import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import worker from '../src/index.ts';

function environment() {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
  return {
    db,
    env: { DB: { prepare(sql) {
      const statement = db.prepare(sql);
      return { bind(...args) {
        return {
          async run() { return statement.run(...args); },
          async all() { return { results: statement.all(...args) }; },
        };
      } };
    } } },
  };
}

const score = (id, time, counts) => ({
  version: 2, day: '2026-10-05', size: 0,
  playerId: id.repeat(32), pseudo: 'Player', timeMs: time, grid: '123',
  strategyActions: counts ? Object.values(counts).reduce((a, b) => a + b, 0) : null,
  actionCounts: counts ?? null,
  theoreticalMoves: counts ? 3 : null,
  finalSolutionMinimum: true,
});
const actions = { placement: 3, rotation: 1, symmetry: 1, translation: 1, removal: 1 };
const submit = (env, body) => worker.fetch(new Request('https://test/score', {
  method: 'POST', body: JSON.stringify(body),
}), env);
const ranking = async (env, maillot, period = 'day') => {
  const response = await worker.fetch(new Request(
    `https://test/leaderboard?version=2&day=2026-10-05&size=0&maillot=${maillot}&period=${period}`,
  ), env);
  assert.equal(response.status, 200);
  return (await response.json()).entries;
};

test('two rankings, strategy total computed by SQLite and time breaks ties', async () => {
  const { db, env } = environment();
  try {
    assert.equal((await submit(env, score('a', 3000, actions))).status, 201);
    assert.equal((await submit(env, score('b', 2000, actions))).status, 201);
    assert.equal((await submit(env, score('c', 1000, { ...actions, rotation: 5 }))).status, 201);
    assert.equal((await submit(env, score('d', 500))).status, 201);
    const strategy = await ranking(env, 'strategie');
    assert.deepEqual(strategy.map((r) => r.player_id[0]), ['b', 'a', 'c']);
    assert.deepEqual(strategy.map((r) => r.strategy_actions), [7, 7, 11]);
    assert.deepEqual(strategy.map((r) => r.theoretical_moves), [3, 3, 3]);
    assert.deepEqual((await ranking(env, 'temps')).map((r) => r.player_id[0]), ['d', 'c', 'b', 'a']);
    for (const period of ['week', 'month']) {
      assert.equal((await ranking(env, 'strategie', period)).length, 3);
      assert.equal((await ranking(env, 'strategie', period))[0].theoretical_moves, 3);
      assert.equal((await ranking(env, 'temps', period)).length, 4);
    }
    assert.equal((await submit(env, score('a', 100, actions))).status, 409);
  } finally { db.close(); }
});

test('reject inconsistent counts; database errors are not acknowledged as duplicates', async () => {
  const { db, env } = environment();
  try {
    assert.equal((await submit(env, { ...score('a', 1000, actions), strategyActions: 99 })).status, 400);
    assert.equal((await submit(env, { ...score('a', 1000, actions), theoreticalMoves: 99 })).status, 400);
    assert.equal((await submit(env, score('b', 1000, { ...actions, removal: -1 }))).status, 400);
    db.exec('DROP TABLE scores');
    assert.equal((await submit(env, score('a', 1000, actions))).status, 500);
  } finally { db.close(); }
});

test('14/7 beats 14/6, ratios break total-move ordering in all periods', async () => {
  const { db, env } = environment();
  try {
    const fourteen = { ...actions, rotation: 8 };
    assert.equal((await submit(env, { ...score('a', 5000, fourteen), theoreticalMoves: 7 })).status, 201);
    assert.equal((await submit(env, { ...score('b', 1000, fourteen), theoreticalMoves: 6 })).status, 201);
    assert.equal((await submit(env, { ...score('c', 6000, actions), theoreticalMoves: 3 })).status, 201);
    assert.equal((await submit(env, { ...score('d', 100, fourteen), finalSolutionMinimum: false })).status, 201);
    for (const period of ['day', 'week', 'month']) {
      assert.deepEqual((await ranking(env, 'strategie', period)).map(r => r.player_id[0]), ['a', 'b', 'c']);
    }
    assert.equal((await ranking(env, 'temps')).length, 4);
    assert.equal(db.prepare("SELECT theoretical_moves FROM scores WHERE player_id = ?").get('d'.repeat(32)).theoretical_moves, null);
    db.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
    assert.equal(db.prepare('SELECT COUNT(*) AS n FROM scores').get().n, 0);
  } finally { db.close(); }
});

test('optional qualifier survives daily and period rankings; old clients remain valid', async () => {
  const { db, env } = environment();
  try {
    assert.equal((await submit(env, { ...score('a', 1000, actions), qualifier: '  Québec  ' })).status, 201);
    assert.equal((await submit(env, score('b', 2000, actions))).status, 201);
    for (const period of ['day', 'week', 'month']) {
      const entries = await ranking(env, 'temps', period);
      assert.equal(entries[0].qualifier, 'Québec');
      assert.equal(entries[1].qualifier, null);
    }
    for (const qualifier of ['x'.repeat(21), 'street@', '🏠']) {
      assert.equal((await submit(env, { ...score('c', 1000), qualifier })).status, 400);
    }
    // La migration additive conserve les anciens scores.
    db.exec('ALTER TABLE scores DROP COLUMN qualifier');
    db.exec(readFileSync(new URL('../migrations/20261111_player_qualifier.sql', import.meta.url), 'utf8'));
    assert.equal(db.prepare('SELECT COUNT(*) AS n FROM scores').get().n, 2);
    assert.equal((await ranking(env, 'temps'))[0].qualifier, null);
  } finally { db.close(); }
});


test('period labels use one coherent latest identity when a player changes profile', async () => {
  const { db, env } = environment();
  try {
    assert.equal((await submit(env, { ...score('a', 1000, actions), pseudo: 'Zoe', qualifier: 'Zurich' })).status, 201);
    assert.equal((await submit(env, { ...score('a', 2000, actions), size: 1, pseudo: 'Alice', qualifier: 'Annecy' })).status, 201);
    db.prepare('UPDATE scores SET created_at = ? WHERE size = ?').run(1, 0);
    db.prepare('UPDATE scores SET created_at = ? WHERE size = ?').run(2, 1);
    for (const period of ['week', 'month']) {
      const entries = await ranking(env, 'temps', period);
      assert.equal(entries[0].pseudo, 'Alice');
      assert.equal(entries[0].qualifier, 'Annecy');
    }
  } finally { db.close(); }
});

test('belts remain unknown for old scores and advance across days and all rankings', async () => {
  const { db, env } = environment();
  try {
    assert.equal((await submit(env, score('a', 1000, actions))).status, 201);
    assert.equal((await submit(env, { ...score('b', 2000, actions), belt: 1 })).status, 201);
    assert.equal((await submit(env, { ...score('b', 3000, actions), day: '2026-10-06', belt: 4 })).status, 201);
    for (const period of ['day', 'week', 'month']) {
      for (const maillot of ['temps', 'strategie']) {
        const entries = await ranking(env, maillot, period);
        assert.equal(entries.find(e => e.player_id === 'a'.repeat(32)).belt, null);
        assert.equal(entries.find(e => e.player_id === 'b'.repeat(32)).belt, 4);
      }
    }
    assert.equal((await submit(env, { ...score('b', 1, actions), belt: 6 })).status, 409);
    const stored = db.prepare('SELECT time_ms, belt FROM scores WHERE player_id = ? AND day = ?').get('b'.repeat(32), '2026-10-05');
    assert.equal(stored.time_ms, 2000);
    assert.equal(stored.belt, 6);
    assert.equal((await submit(env, { ...score('b', 1, actions), belt: 2 })).status, 409);
    assert.equal((await ranking(env, 'temps')).find(e => e.player_id === 'b'.repeat(32)).belt, 6);
    for (const belt of [-1, 7, 1.5, '3']) {
      assert.equal((await submit(env, { ...score('c', 1000, actions), belt })).status, 400);
    }
  } finally { db.close(); }
});

test('belt migration preserves existing scores without assigning an invented grade', () => {
  const db = new DatabaseSync(':memory:');
  try {
    const schema = readFileSync(new URL('../schema.sql', import.meta.url), 'utf8')
      .replace('  belt       INTEGER CHECK (belt BETWEEN 0 AND 6),\n', '')
      .replace('CREATE INDEX scores_player_belt ON scores (player_id, belt);', '');
    db.exec(schema);
    db.prepare('INSERT INTO scores (version, day, size, player_id, pseudo, time_ms, grid, created_at) VALUES (3, ?, 0, ?, ?, 30000, ?, 0)')
      .run('2026-11-17', 'a'.repeat(32), 'Paul', '123');
    db.exec(readFileSync(new URL('../migrations/20261117_player_belt.sql', import.meta.url), 'utf8'));
    const row = db.prepare('SELECT time_ms, belt FROM scores').get();
    assert.equal(row.time_ms, 30000);
    assert.equal(row.belt, null);
    assert.equal(db.prepare('SELECT COUNT(*) AS n FROM scores').get().n, 1);
  } finally { db.close(); }
});
