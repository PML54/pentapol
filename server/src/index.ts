// Worker Cloudflare — classement du défi quotidien de Pentapol.
//
// Modèle de confiance (décision Paul 2026-09-04) : l'app mesure les trois valeurs localement,
// le joueur ne saisit rien — il ne peut pas tricher via le jeu. Le seul vecteur résiduel est un
// POST direct forgé (curl) hors de l'app ; jugé négligeable pour une app payante à petite
// population. Le serveur NE RECALCULE PAS minIso : il fait confiance aux chiffres envoyés et
// conserve la grille pour un audit hors ligne éventuel (outil Dart). Voir README « Vérification ».
//
// Rien à voir avec le worker duel (WebSocket + Durable Objects) : ici, POST de score + GET de
// tableau, sur D1. Aucun Durable Object.

export interface Env {
  DB: D1Database;
  // Jeton d'amorçage : si défini, POST /challenge l'exige (Authorization: Bearer <token>).
  // Protège la définition d'un défi contre un empoisonnement (§7 : composition à la main /
  // autorité serveur). Laisser vide n'est PAS recommandé (n'importe qui pourrait semer un défi).
  SEED_TOKEN?: string;
}

const JSON_HEADERS = {
  'content-type': 'application/json; charset=utf-8',
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, DELETE, OPTIONS',
  'access-control-allow-headers': 'content-type, authorization',
};

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), { status, headers: JSON_HEADERS });
}

function err(message: string, status: number): Response {
  return json({ error: message }, status);
}

/// Trois entiers de partition, validés (>= 0, bornés).
function partition(url: URL): { version: number; day: string; size: number } | null {
  const version = Number(url.searchParams.get('version'));
  const day = String(url.searchParams.get('day') ?? '');
  const size = Number(url.searchParams.get('size'));
  if (![version, size].every((n) => Number.isInteger(n) && n >= 0 && n < 1_000_000) ||
      !/^\d{4}-\d{2}-\d{2}$/.test(day)) {
    return null;
  }
  return { version, day, size };
}

// L'ordre SQL par maillot. La partition (version, week, size) est petite → tri en requête.
const MAILLOT_ORDER: Record<string, string> = {
  // 🟡 acuité décroissante = MIN((min_iso+1)/(iso_count+1), 1.0) DESC ; temps en départage.
  temps: 'time_ms ASC',
  acuite: 'MIN((min_iso + 1.0) / (iso_count + 1), 1.0) DESC, time_ms ASC',
  coups: 'moves ASC, time_ms ASC',
};

async function getLeaderboard(env: Env, url: URL): Promise<Response> {
  const p = partition(url);
  if (!p) return err('paramètres version/day/size invalides', 400);
  const maillot = url.searchParams.get('maillot') ?? 'temps';
  const order = MAILLOT_ORDER[maillot];
  if (!order) return err('classement inconnu (temps|acuite|coups)', 400);
  const limit = Math.min(Math.max(Number(url.searchParams.get('limit')) || 100, 1), 500);

  const period = url.searchParams.get('period') ?? 'day';
  if (!['day', 'week', 'month'].includes(period)) return err('période inconnue', 400);

  if (period !== 'day') {
    const anchor = new Date(`${p.day}T00:00:00Z`);
    const start = new Date(anchor);
    const end = new Date(anchor);
    const bestDays = period === 'week' ? 5 : 20;
    if (period === 'week') {
      const isoOffset = (anchor.getUTCDay() + 6) % 7;
      start.setUTCDate(anchor.getUTCDate() - isoOffset);
      end.setUTCDate(start.getUTCDate() + 6);
    } else {
      start.setUTCDate(1);
      end.setUTCMonth(start.getUTCMonth() + 1, 0);
    }
    const iso = (date: Date) => date.toISOString().slice(0, 10);
    const rows = await env.DB.prepare(
      `WITH ranked AS (
         SELECT player_id, pseudo, day, size,
                RANK() OVER (PARTITION BY day, size ORDER BY ${order}) AS place,
                COUNT(*) OVER (PARTITION BY day, size) AS participants
           FROM scores
          WHERE version = ? AND day BETWEEN ? AND ?
       ), scored AS (
         SELECT player_id, pseudo, day,
                CASE WHEN participants = 1 THEN 100.0
                     ELSE 100.0 - 80.0 * (place - 1) / (participants - 1) END AS points
           FROM ranked
       ), daily AS (
         SELECT player_id, MAX(pseudo) AS pseudo, day, SUM(points) AS day_points
           FROM scored GROUP BY player_id, day
       ), best AS (
         SELECT *, ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY day_points DESC) AS day_rank
           FROM daily
       )
       SELECT player_id, MAX(pseudo) AS pseudo, ROUND(SUM(day_points), 1) AS points,
              COUNT(*) AS days
         FROM best WHERE day_rank <= ?
        GROUP BY player_id
        ORDER BY points DESC, days DESC
        LIMIT ?`
    ).bind(p.version, iso(start), iso(end), bestDays, limit).all();
    return json({ maillot, period, entries: rows.results ?? [] });
  }

  const rows = await env.DB.prepare(
    `SELECT player_id, pseudo, min_iso, iso_count, moves, faults, time_ms
       FROM scores
      WHERE version = ? AND day = ? AND size = ?
      ORDER BY ${order}
      LIMIT ?`
  )
    .bind(p.version, p.day, p.size, limit)
    .all();

  return json({ maillot, entries: rows.results ?? [] });
}

async function postScore(env: Env, request: Request): Promise<Response> {
  let body: any;
  try {
    body = await request.json();
  } catch {
    return err('corps JSON invalide', 400);
  }

  // Champs requis + bornes légères (modèle confiance : pas de vérification de pavage).
  const fields = ['version', 'size', 'minIso', 'isoCount', 'moves', 'faults', 'timeMs'];
  for (const f of fields) {
    if (!Number.isInteger(body[f]) || body[f] < 0) return err(`champ entier ${f} manquant/invalide`, 400);
  }
  const day = String(body.day ?? '');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) return err('champ day invalide', 400);
  const playerId = String(body.playerId ?? '');
  if (!/^[0-9a-f]{32}$/.test(playerId)) return err('playerId doit être 32 hex', 400);
  const pseudo = String(body.pseudo ?? '').trim().replace(/\s+/g, ' ');
  const pseudoLength = Array.from(pseudo).length;
  if (pseudoLength < 3 || pseudoLength > 20 ||
      !/^[A-Za-zÀ-ÖØ-öø-ÿŒœÆæ0-9 '\-’]+$/.test(pseudo) ||
      !/[A-Za-zÀ-ÖØ-öø-ÿŒœÆæ]/.test(pseudo)) {
    return err('pseudo invalide (3 à 20 caractères)', 400);
  }
  const grid = String(body.grid ?? '');
  if (grid.length === 0 || grid.length > 4096) return err('grid manquante/trop grande', 400);

  // Essai UNIQUE par (version, week, size, player_id) — §7.1 « premier essai » : la clé primaire
  // refuse un second. INSERT simple → conflit = 409.
  try {
    await env.DB.prepare(
      `INSERT INTO scores
         (version, day, size, player_id, pseudo, min_iso, iso_count, moves, faults, time_ms, grid, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
      .bind(
        body.version, day, body.size, playerId, pseudo,
        body.minIso, body.isoCount, body.moves, body.faults, body.timeMs, grid, Date.now()
      )
      .run();
  } catch (e) {
    // Violation de clé primaire = déjà soumis (premier essai déjà enregistré).
    return err('score déjà soumis pour ce défi (premier essai seulement)', 409);
  }
  return json({ ok: true }, 201);
}

// Suppression RGPD (CDC §7.4) : efface TOUTES les lignes d'un joueur (toutes semaines/tailles/
// versions). Le player_id est un secret aléatoire de 128 bits connu du seul propriétaire → un
// DELETE non authentifié n'expose que ses propres données (même modèle de confiance que POST /score).
async function deleteScores(env: Env, url: URL): Promise<Response> {
  const playerId = String(url.searchParams.get('playerId') ?? '');
  if (!/^[0-9a-f]{32}$/.test(playerId)) return err('playerId doit être 32 hex', 400);
  const res = await env.DB.prepare(`DELETE FROM scores WHERE player_id = ?`).bind(playerId).run();
  return json({ ok: true, deleted: res.meta?.changes ?? 0 }, 200);
}

async function getChallenge(env: Env, url: URL): Promise<Response> {
  const p = partition(url);
  if (!p) return err('paramètres version/day/size invalides', 400);
  const row = await env.DB.prepare(
    `SELECT mask, rack, solution_count FROM challenges WHERE version = ? AND day = ? AND size = ?`
  )
    .bind(p.version, p.day, p.size)
    .first();
  if (!row) return err('défi non défini pour cette semaine', 404);
  return json({ mask: row.mask, rack: JSON.parse(String(row.rack)), solutionCount: row.solution_count });
}

async function postChallenge(env: Env, request: Request): Promise<Response> {
  // Amorçage gardé par un jeton (composition à la main / autorité serveur, §7). Empêche
  // l'empoisonnement d'un défi par un POST forgé.
  if (env.SEED_TOKEN) {
    const auth = request.headers.get('authorization') ?? '';
    if (auth !== `Bearer ${env.SEED_TOKEN}`) return err('non autorisé', 401);
  }
  let body: any;
  try {
    body = await request.json();
  } catch {
    return err('corps JSON invalide', 400);
  }
  for (const f of ['version', 'size', 'mask', 'solutionCount']) {
    if (!Number.isInteger(body[f]) || body[f] < 0) return err(`champ entier ${f} manquant/invalide`, 400);
  }
  const day = String(body.day ?? '');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) return err('champ day invalide', 400);
  const rack = JSON.stringify(body.rack ?? {});
  // INSERT OR IGNORE : idempotent, premier semeur gagne (course inoffensive, §7 Acté 1bis).
  await env.DB.prepare(
    `INSERT OR IGNORE INTO challenges (version, day, size, mask, rack, solution_count) VALUES (?, ?, ?, ?, ?, ?)`
  )
    .bind(body.version, day, body.size, body.mask, rack, body.solutionCount)
    .run();
  return json({ ok: true }, 201);
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === 'OPTIONS') return new Response(null, { headers: JSON_HEADERS });
    const url = new URL(request.url);
    try {
      if (request.method === 'GET' && url.pathname === '/leaderboard') return await getLeaderboard(env, url);
      if (request.method === 'POST' && url.pathname === '/score') return await postScore(env, request);
      if (request.method === 'DELETE' && url.pathname === '/score') return await deleteScores(env, url);
      if (request.method === 'GET' && url.pathname === '/challenge') return await getChallenge(env, url);
      if (request.method === 'POST' && url.pathname === '/challenge') return await postChallenge(env, request);
      return err('route inconnue', 404);
    } catch (e) {
      return err('erreur serveur', 500);
    }
  },
};
