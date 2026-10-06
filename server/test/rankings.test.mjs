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
