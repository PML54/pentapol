// Worker Cloudflare — classement du défi de la semaine de Pentapol (CDC §7).
//
// Modèle de confiance (décision Paul 2026-09-04) : l'app mesure les quatre valeurs localement,
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
  'access-control-allow-methods': 'GET, POST, OPTIONS',
  'access-control-allow-headers': 'content-type, authorization',
};

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), { status, headers: JSON_HEADERS });
}

function err(message: string, status: number): Response {
  return json({ error: message }, status);
}

/// Trois entiers de partition, validés (>= 0, bornés).
function partition(url: URL): { version: number; week: number; size: number } | null {
  const version = Number(url.searchParams.get('version'));
  const week = Number(url.searchParams.get('week'));
  const size = Number(url.searchParams.get('size'));
  if (![version, week, size].every((n) => Number.isInteger(n) && n >= 0 && n < 1_000_000)) {
    return null;
  }
  return { version, week, size };
}

// L'ordre SQL par maillot. La partition (version, week, size) est petite → tri en requête.
const MAILLOT_ORDER: Record<string, string> = {
  // 🟡 acuité décroissante = (min_iso+1)/(iso_count+1) DESC ; temps en départage.
  jaune: '(min_iso + 1.0) / (iso_count + 1) DESC, time_ms ASC',
  pois: 'moves ASC, time_ms ASC', // ⚫ coups
  vert: 'time_ms ASC', // 🟢 temps
  blanc: 'help ASC, time_ms ASC', // ⚪ Help
};

async function getLeaderboard(env: Env, url: URL): Promise<Response> {
  const p = partition(url);
  if (!p) return err('paramètres version/week/size invalides', 400);
  const maillot = url.searchParams.get('maillot') ?? 'jaune';
  const order = MAILLOT_ORDER[maillot];
  if (!order) return err('maillot inconnu (jaune|pois|vert|blanc)', 400);
  const limit = Math.min(Math.max(Number(url.searchParams.get('limit')) || 100, 1), 500);

  const rows = await env.DB.prepare(
    `SELECT player_id, pseudo, min_iso, iso_count, moves, time_ms, help
       FROM scores
      WHERE version = ? AND week = ? AND size = ?
      ORDER BY ${order}
      LIMIT ?`
  )
    .bind(p.version, p.week, p.size, limit)
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
  const fields = ['version', 'week', 'size', 'minIso', 'isoCount', 'moves', 'timeMs', 'help'];
  for (const f of fields) {
    if (!Number.isInteger(body[f]) || body[f] < 0) return err(`champ entier ${f} manquant/invalide`, 400);
  }
  const playerId = String(body.playerId ?? '');
  if (!/^[0-9a-f]{32}$/.test(playerId)) return err('playerId doit être 32 hex', 400);
  const pseudo = String(body.pseudo ?? '').slice(0, 40);
  const grid = String(body.grid ?? '');
  if (grid.length === 0 || grid.length > 4096) return err('grid manquante/trop grande', 400);

  // Essai UNIQUE par (version, week, size, player_id) — §7.1 « premier essai » : la clé primaire
  // refuse un second. INSERT simple → conflit = 409.
  try {
    await env.DB.prepare(
      `INSERT INTO scores
         (version, week, size, player_id, pseudo, min_iso, iso_count, moves, time_ms, help, grid, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
      .bind(
        body.version, body.week, body.size, playerId, pseudo,
        body.minIso, body.isoCount, body.moves, body.timeMs, body.help, grid, Date.now()
      )
      .run();
  } catch (e) {
    // Violation de clé primaire = déjà soumis (premier essai déjà enregistré).
    return err('score déjà soumis pour ce défi (premier essai seulement)', 409);
  }
  return json({ ok: true }, 201);
}

async function getChallenge(env: Env, url: URL): Promise<Response> {
  const p = partition(url);
  if (!p) return err('paramètres version/week/size invalides', 400);
  const row = await env.DB.prepare(
    `SELECT mask, rack FROM challenges WHERE version = ? AND week = ? AND size = ?`
  )
    .bind(p.version, p.week, p.size)
    .first();
  if (!row) return err('défi non défini pour cette semaine', 404);
  return json({ mask: row.mask, rack: JSON.parse(String(row.rack)) });
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
  for (const f of ['version', 'week', 'size', 'mask']) {
    if (!Number.isInteger(body[f]) || body[f] < 0) return err(`champ entier ${f} manquant/invalide`, 400);
  }
  const rack = JSON.stringify(body.rack ?? {});
  // INSERT OR IGNORE : idempotent, premier semeur gagne (course inoffensive, §7 Acté 1bis).
  await env.DB.prepare(
    `INSERT OR IGNORE INTO challenges (version, week, size, mask, rack) VALUES (?, ?, ?, ?, ?)`
  )
    .bind(body.version, body.week, body.size, body.mask, rack)
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
      if (request.method === 'GET' && url.pathname === '/challenge') return await getChallenge(env, url);
      if (request.method === 'POST' && url.pathname === '/challenge') return await postChallenge(env, request);
      return err('route inconnue', 404);
    } catch (e) {
      return err('erreur serveur', 500);
    }
  },
};
