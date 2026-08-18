const { test } = require('node:test');
const assert = require('node:assert/strict');

const { findConfigProblems, assertProductionConfig } = require('../config/requireEnv');

/// A configuration that should pass cleanly. Individual tests break one key
/// at a time from this baseline, so a new required variable added to
/// requireEnv.js fails every test here until it is represented — which is the
/// intent: the gate and its fixture stay in step.
const VALID = {
  JWT_SECRET: 'K7pQ2vX9mR4tL8wN3zY6bH1jF5sD0aG2',
  DB_HOST: 'db.internal',
  DB_USER: 'wedpilot',
  DB_PASSWORD: 'a-real-password',
  DB_NAME: 'wedpilot',
  CORS_ORIGINS: 'https://wedpilot.app,https://www.wedpilot.app',
  PUBLIC_WEB_BASE_URL: 'https://wedpilot.app',
  SMTP_HOST: 'smtp.provider.com',
  SMTP_USER: 'no-reply@wedpilot.app',
  SMTP_PASS: 'a-real-app-password',
};

const withEnv = (overrides) => ({ ...VALID, ...overrides });

/// Asserts exactly one problem was found and that it names the variable at
/// fault — the message is the whole product here, since an operator reading
/// it at 3am is the only consumer.
function assertSingleProblemNaming(problems, variableName) {
  assert.equal(problems.length, 1, `expected one problem, got: ${JSON.stringify(problems)}`);
  assert.match(problems[0], new RegExp(variableName));
}

test('a fully configured environment raises nothing', () => {
  assert.deepEqual(findConfigProblems(VALID), []);
});

test('an empty environment reports every required variable at once', () => {
  const problems = findConfigProblems({});
  // One pass, not one-error-at-a-time: an operator fixing a fresh deploy
  // should see the whole list rather than restarting six times.
  for (const name of ['JWT_SECRET', 'DB_HOST', 'DB_USER', 'DB_NAME', 'PUBLIC_WEB_BASE_URL', 'SMTP']) {
    assert.ok(
      problems.some((p) => p.includes(name)),
      `expected a problem naming ${name}, got: ${JSON.stringify(problems)}`,
    );
  }
});

test('the .env.example JWT placeholder is rejected, not merely its absence', () => {
  const problems = findConfigProblems(withEnv({ JWT_SECRET: 'change_this_to_a_long_random_secret_string' }));
  assertSingleProblemNaming(problems, 'JWT_SECRET');
  assert.match(problems[0], /placeholder/i);
});

test('a short JWT secret is rejected', () => {
  const problems = findConfigProblems(withEnv({ JWT_SECRET: 'short-secret' }));
  assertSingleProblemNaming(problems, 'JWT_SECRET');
  assert.match(problems[0], /12 characters/);
});

test('a JWT secret exactly at the 32-character floor passes', () => {
  assert.deepEqual(findConfigProblems(withEnv({ JWT_SECRET: 'x'.repeat(32) })), []);
});

test('an empty or comma-only CORS_ORIGINS is rejected', () => {
  // The alternative to a real list is an API any origin can call.
  for (const value of ['', '   ', ',', ' , , ']) {
    const problems = findConfigProblems(withEnv({ CORS_ORIGINS: value }));
    assertSingleProblemNaming(problems, 'CORS_ORIGINS');
  }
});

test('a localhost PUBLIC_WEB_BASE_URL is rejected', () => {
  // The failure this exists to stop: every verification and reset email
  // pointing the recipient at their own machine.
  for (const url of ['http://localhost:8080', 'http://127.0.0.1:8080', 'https://0.0.0.0:8080']) {
    const problems = findConfigProblems(withEnv({ PUBLIC_WEB_BASE_URL: url }));
    assertSingleProblemNaming(problems, 'PUBLIC_WEB_BASE_URL');
  }
});

test('a plain-http PUBLIC_WEB_BASE_URL is rejected — reset tokens ride in that URL', () => {
  const problems = findConfigProblems(withEnv({ PUBLIC_WEB_BASE_URL: 'http://wedpilot.app' }));
  assertSingleProblemNaming(problems, 'PUBLIC_WEB_BASE_URL');
  assert.match(problems[0], /https/);
});

test('missing SMTP is rejected and names the specific missing keys', () => {
  const problems = findConfigProblems(withEnv({ SMTP_PASS: '' }));
  assertSingleProblemNaming(problems, 'SMTP_PASS');
  // mailer.js silently logs to console instead of sending when unconfigured —
  // in production that is an invisible account-recovery outage.
  assert.match(problems[0], /silently/i);
});

test('the SMTP placeholder password counts as unconfigured', () => {
  const problems = findConfigProblems(withEnv({ SMTP_PASS: 'your_smtp_app_password' }));
  assertSingleProblemNaming(problems, 'SMTP_PASS');
});

test('an empty DB_PASSWORD is allowed but the placeholder is not', () => {
  // Some managed instances authenticate by socket/IAM rather than password.
  assert.deepEqual(findConfigProblems(withEnv({ DB_PASSWORD: '' })), []);
  const problems = findConfigProblems(withEnv({ DB_PASSWORD: 'your_mysql_password_here' }));
  assertSingleProblemNaming(problems, 'DB_PASSWORD');
});

test('whitespace-only values count as unset', () => {
  const problems = findConfigProblems(withEnv({ DB_NAME: '   ' }));
  assertSingleProblemNaming(problems, 'DB_NAME');
});

test('the gate only applies to production', () => {
  // Localhost defaults and a console-logging mailer are exactly what makes
  // local development work; the gate must never fire there.
  for (const nodeEnv of ['development', 'test', undefined]) {
    assert.deepEqual(assertProductionConfig({ NODE_ENV: nodeEnv }, { exit: false }), []);
  }
});

test('production with a broken config reports problems rather than starting', () => {
  const problems = assertProductionConfig({ NODE_ENV: 'production' }, { exit: false });
  assert.ok(problems.length > 0);
});

test('production with a good config returns no problems', () => {
  assert.deepEqual(
    assertProductionConfig({ ...VALID, NODE_ENV: 'production' }, { exit: false }),
    [],
  );
});
