// Startup configuration gate.
//
// Every value checked here has the same failure signature in production: the
// server boots perfectly, serves traffic, and only the *user-visible* half of
// a feature is broken — a verification mail pointing at localhost, a reset
// link nobody can open, an auth layer that 401s every request. Those surface
// as support tickets days later rather than as a failed deploy, so each one
// is turned into a refusal to start instead. server.js already took this
// stance for CORS_ORIGINS; this is the same rule applied to the rest of the
// config surface.
//
// Development is deliberately left alone — localhost defaults and a
// console-logging mailer are exactly what makes local work pleasant, and the
// database there is disposable.

// Placeholders shipped in .env.example. Copying that file and forgetting to
// edit a line is the single most likely way to reach production with a
// "configured" secret that every reader of this repo already knows.
const EXAMPLE_PLACEHOLDERS = [
  'change_this_to_a_long_random_secret_string',
  'your_mysql_password_here',
  'your_openrouter_api_key_here',
  'your_smtp_app_password',
];

// A JWT signing key is only as strong as its entropy: jsonwebtoken will
// happily sign with "secret", and HS256 forgery against a short key is a
// dictionary attack, not a cryptographic one. 32 characters is the floor for
// a key that is genuinely random (`openssl rand -base64 32`).
const MIN_JWT_SECRET_LENGTH = 32;

function isPlaceholder(value) {
  return EXAMPLE_PLACEHOLDERS.includes(value.trim());
}

/**
 * Validates production configuration and returns the list of problems found.
 * Kept pure (no process.exit, no console) so it is directly testable.
 *
 * @param {NodeJS.ProcessEnv} env
 * @returns {string[]} human-readable problems; empty means good to start.
 */
function findConfigProblems(env) {
  const problems = [];

  const required = (name, hint) => {
    const value = env[name];
    if (!value || !value.trim()) {
      problems.push(`${name} is not set. ${hint}`);
      return null;
    }
    if (isPlaceholder(value)) {
      problems.push(`${name} still holds the placeholder value from .env.example. ${hint}`);
      return null;
    }
    return value.trim();
  };

  // ── Auth ──────────────────────────────────────────────────────────────────
  const jwtSecret = required(
    'JWT_SECRET',
    'Generate one with `openssl rand -base64 32`. Without it every login and '
    + 'every authenticated request fails.',
  );
  if (jwtSecret && jwtSecret.length < MIN_JWT_SECRET_LENGTH) {
    problems.push(
      `JWT_SECRET is only ${jwtSecret.length} characters. Use at least `
      + `${MIN_JWT_SECRET_LENGTH} (\`openssl rand -base64 32\`) — a short signing key is brute-forceable.`,
    );
  }

  // ── Database ──────────────────────────────────────────────────────────────
  for (const name of ['DB_HOST', 'DB_USER', 'DB_NAME']) {
    required(name, 'The server cannot reach its database without it.');
  }
  // DB_PASSWORD is intentionally allowed to be empty (some managed instances
  // authenticate by socket/IAM) but never the shipped placeholder.
  if (env.DB_PASSWORD && isPlaceholder(env.DB_PASSWORD)) {
    problems.push('DB_PASSWORD still holds the placeholder value from .env.example.');
  }

  // ── CORS ──────────────────────────────────────────────────────────────────
  // Checked here rather than at the app.use(cors(...)) site so that an
  // operator bringing up a fresh deploy sees every configuration problem in
  // one pass instead of fixing one, restarting, and discovering the next.
  const corsOrigins = (env.CORS_ORIGINS || '').split(',').map((o) => o.trim()).filter(Boolean);
  if (corsOrigins.length === 0) {
    problems.push(
      'CORS_ORIGINS is not set. List the web origins allowed to call this API '
      + '(e.g. CORS_ORIGINS=https://wedpilot.app) — the only alternative is an '
      + 'unrestricted CORS policy. Native app builds send no Origin header and are unaffected.',
    );
  }

  // ── Outbound links ────────────────────────────────────────────────────────
  // Baked into verification and password-reset emails. Left unset, every one
  // of those mails points the recipient at their own machine.
  const publicUrl = required(
    'PUBLIC_WEB_BASE_URL',
    'It is embedded in verification and password-reset emails (e.g. https://wedpilot.app).',
  );
  if (publicUrl) {
    if (/localhost|127\.0\.0\.1|0\.0\.0\.0/.test(publicUrl)) {
      problems.push(
        `PUBLIC_WEB_BASE_URL points at "${publicUrl}". Verification and password-reset `
        + 'emails would send users to their own machine. Set it to the public origin '
        + 'the web build is served from.',
      );
    } else if (!publicUrl.startsWith('https://')) {
      problems.push(
        `PUBLIC_WEB_BASE_URL must use https in production (got "${publicUrl}") — reset `
        + 'and verification tokens travel in that URL.',
      );
    }
  }

  // ── Mail ──────────────────────────────────────────────────────────────────
  // services/mailer.js falls back to logging links to the console when these
  // are missing. That is the right behaviour in development and a silent
  // account-recovery outage in production: the API keeps answering "if an
  // account exists, a reset link has been sent" while no mail is ever sent.
  const smtpMissing = ['SMTP_HOST', 'SMTP_USER', 'SMTP_PASS'].filter(
    (name) => !env[name] || !env[name].trim() || isPlaceholder(env[name]),
  );
  if (smtpMissing.length > 0) {
    problems.push(
      `SMTP is not configured (missing/placeholder: ${smtpMissing.join(', ')}). Password `
      + 'reset and email verification would silently send nothing while still reporting success.',
    );
  }

  return problems;
}

/**
 * In production, refuses to start unless the configuration is complete.
 * Outside production this is a no-op beyond a short advisory notice.
 */
function assertProductionConfig(env = process.env, { exit = true } = {}) {
  if (env.NODE_ENV !== 'production') return [];

  const problems = findConfigProblems(env);
  if (problems.length === 0) return [];

  console.error(
    `\nRefusing to start: ${problems.length} configuration problem`
    + `${problems.length === 1 ? '' : 's'} that would surface as broken features rather than a failed deploy.\n`,
  );
  problems.forEach((problem, i) => console.error(`  ${i + 1}. ${problem}\n`));
  console.error('Fix the values above in the environment, then restart.\n');

  if (exit) process.exit(1);
  return problems;
}

module.exports = {
  assertProductionConfig,
  findConfigProblems,
  MIN_JWT_SECRET_LENGTH,
};
