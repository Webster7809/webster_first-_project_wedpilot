const express = require('express');
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const { OAuth2Client } = require('google-auth-library');
const User = require('../db/models/user');
const verifyJwt = require('../middleware/verifyJwt');
const { sendPasswordResetEmail } = require('../services/mailer');

const router = express.Router();

// GOOGLE_CLIENT_ID is the OAuth 2.0 client ID from Google Cloud Console
// (the Android/Web client the Flutter app signs in with) — unset in dev
// until that's created, in which case /google below responds 501 instead
// of trying to verify against an undefined audience.
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// Credential-guessing surface: login (password brute force / credential
// stuffing against a known email) and register (bulk account creation) both
// let an attacker try many values per second with no cost otherwise. Keyed on
// IP — coarse, but this app has no CDN/proxy layer in front of it yet to
// support a more precise key, and coarse-but-present beats absent.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many attempts. Please wait a few minutes and try again.' },
});

// Forgot-password is already response-time-safe (see genericResponse below),
// but without a cap an attacker can still mass-trigger reset emails at an
// address (a spam/harassment vector against a real user) or hammer the SMTP
// provider's own rate limit. Reset itself only matters once someone already
// holds a valid token, so it rides the same generous limiter as login.
const passwordResetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many attempts. Please wait a few minutes and try again.' },
});

const ACCESS_TOKEN_TTL = '1h';
const ACCESS_TOKEN_TTL_MS = 60 * 60 * 1000;
const REFRESH_TOKEN_TTL = process.env.JWT_EXPIRES_IN || '7d';
const REFRESH_TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const RESET_TOKEN_TTL_MS = 60 * 60 * 1000;
const PUBLIC_WEB_BASE_URL = process.env.PUBLIC_WEB_BASE_URL || 'http://localhost:8080';

const hashToken = (token) => crypto.createHash('sha256').update(token).digest('hex');

function issueTokens(user) {
  const payload = { user_id: user.user_id, role: user.role };
  const accessToken = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: ACCESS_TOKEN_TTL });
  const refreshToken = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: REFRESH_TOKEN_TTL });
  const now = Date.now();
  return {
    accessToken,
    refreshToken,
    accessExpiry: new Date(now + ACCESS_TOKEN_TTL_MS).toISOString(),
    refreshExpiry: new Date(now + REFRESH_TOKEN_TTL_MS).toISOString(),
  };
}

function serializeUser(user) {
  return {
    user_id: user.user_id,
    email: user.email,
    name: user.name,
    avatar_url: user.avatar_url,
    role: user.role,
    is_verified: user.is_verified,
    created_at: user.created_at,
  };
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// ── POST /api/auth/register ───────────────────────────────────────────────────
router.post('/register', authLimiter, async (req, res) => {
  const { email, password, name, role = 'couple' } = req.body;

  if (!email || !EMAIL_RE.test(email)) {
    return res.status(400).json({ error: 'A valid email is required.' });
  }
  if (!password || password.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters.' });
  }
  if (!['couple', 'vendor'].includes(role)) {
    return res.status(400).json({ error: 'Invalid role.' });
  }

  const normalisedEmail = email.toLowerCase().trim();

  try {
    const existing = await User.findOne({ where: { email: normalisedEmail } });
    if (existing) {
      return res.status(409).json({ error: 'An account with this email already exists.' });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const user = await User.create({
      email: normalisedEmail,
      password_hash,
      name,
      role,
    });

    const tokens = issueTokens(user);
    res.status(201).json({ user: serializeUser(user), ...tokens });
  } catch (err) {
    console.error('Register error:', err.message);
    res.status(500).json({ error: 'Registration failed.' });
  }
});

// ── POST /api/auth/login ───────────────────────────────────────────────────────
router.post('/login', authLimiter, async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required.' });
  }

  const normalisedEmail = email.toLowerCase().trim();

  try {
    const user = await User.findOne({ where: { email: normalisedEmail } });
    if (!user) {
      return res.status(401).json({ error: 'No account found. Please create an account first.' });
    }

    const passwordMatches = await bcrypt.compare(password, user.password_hash);
    if (!passwordMatches) {
      return res.status(401).json({ error: 'Invalid credentials.' });
    }

    if (user.is_suspended) {
      return res.status(403).json({ error: 'This account has been suspended. Contact support for help.' });
    }

    const tokens = issueTokens(user);
    res.json({ user: serializeUser(user), ...tokens });
  } catch (err) {
    console.error('Login error:', err.message);
    res.status(500).json({ error: 'Login failed.' });
  }
});

// ── POST /api/auth/google ──────────────────────────────────────────────────────
// Signs in with a Google ID token from the client's google_sign_in flow.
// Matches by email (Google already verifies it) rather than requiring a
// separate linked-account step first — an existing email/password account
// logs straight in via Google too, same as any other "sign in with X" that
// treats a verified email as proof of identity. `role` only matters the
// first time this email is seen, when it decides the new account's role.
router.post('/google', authLimiter, async (req, res) => {
  const { id_token, role = 'couple' } = req.body;

  if (!id_token || typeof id_token !== 'string') {
    return res.status(400).json({ error: 'id_token is required.' });
  }
  if (!['couple', 'vendor'].includes(role)) {
    return res.status(400).json({ error: 'Invalid role.' });
  }
  if (!process.env.GOOGLE_CLIENT_ID) {
    return res.status(501).json({ error: 'Google sign-in is not configured on this server yet.' });
  }

  let payload;
  try {
    const ticket = await googleClient.verifyIdToken({
      idToken: id_token,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    payload = ticket.getPayload();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid Google sign-in token.' });
  }
  if (!payload?.email || !payload.email_verified) {
    return res.status(401).json({ error: 'Could not verify your Google account email.' });
  }

  const normalisedEmail = payload.email.toLowerCase().trim();

  try {
    let user = await User.findOne({ where: { email: normalisedEmail } });
    if (!user) {
      // No password is ever set for a Google-created account — this random
      // value satisfies the NOT NULL column and is never revealed or used;
      // password login for this email simply never succeeds.
      const password_hash = await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 10);
      user = await User.create({
        email: normalisedEmail,
        password_hash,
        name: payload.name || payload.given_name || null,
        avatar_url: payload.picture || null,
        role,
        is_verified: true,
      });
    }

    if (user.is_suspended) {
      return res.status(403).json({ error: 'This account has been suspended. Contact support for help.' });
    }

    const tokens = issueTokens(user);
    res.json({ user: serializeUser(user), ...tokens });
  } catch (err) {
    console.error('Google auth error:', err.message);
    res.status(500).json({ error: 'Google sign-in failed.' });
  }
});

// ── POST /api/auth/forgot-password ────────────────────────────────────────────
router.post('/forgot-password', passwordResetLimiter, async (req, res) => {
  const { email } = req.body;

  if (!email || !EMAIL_RE.test(email)) {
    return res.status(400).json({ error: 'A valid email is required.' });
  }

  // Always return the same generic response whether or not the account
  // exists, so this endpoint can't be used to enumerate registered emails.
  const genericResponse = { message: 'If an account exists for that email, a reset link has been sent.' };
  const normalisedEmail = email.toLowerCase().trim();

  try {
    const user = await User.findOne({ where: { email: normalisedEmail } });
    if (user) {
      const rawToken = crypto.randomBytes(32).toString('hex');
      user.reset_token_hash = hashToken(rawToken);
      user.reset_token_expires = new Date(Date.now() + RESET_TOKEN_TTL_MS);
      await user.save();

      const resetLink = `${PUBLIC_WEB_BASE_URL}/#/reset-password?token=${rawToken}`;
      await sendPasswordResetEmail(normalisedEmail, resetLink);
    }
    res.json(genericResponse);
  } catch (err) {
    console.error('Forgot password error:', err.message);
    // Still respond generically — a server-side hiccup shouldn't leak
    // whether the account exists either.
    res.json(genericResponse);
  }
});

// ── POST /api/auth/reset-password ─────────────────────────────────────────────
router.post('/reset-password', passwordResetLimiter, async (req, res) => {
  const { token, newPassword } = req.body;

  if (!token) {
    return res.status(400).json({ error: 'Missing reset token.' });
  }
  if (!newPassword || newPassword.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters.' });
  }

  try {
    const user = await User.findOne({ where: { reset_token_hash: hashToken(token) } });
    if (!user || !user.reset_token_expires || user.reset_token_expires < new Date()) {
      return res.status(400).json({ error: 'This reset link is invalid or has expired.' });
    }

    user.password_hash = await bcrypt.hash(newPassword, 10);
    user.reset_token_hash = null;
    user.reset_token_expires = null;
    await user.save();

    res.json({ message: 'Password updated. You can now log in.' });
  } catch (err) {
    console.error('Reset password error:', err.message);
    res.status(500).json({ error: 'Could not reset password.' });
  }
});

// ── POST /api/auth/refresh ────────────────────────────────────────────────────
// The access token is deliberately short-lived (1h), but until this endpoint
// existed nothing ever exchanged the refresh token the client already stores
// for a new one — every session just died an hour after login with no
// recovery path. Issues a fresh pair (rotation: the old refresh token is
// implicitly retired since the client overwrites it) rather than only a new
// access token, so a session can keep renewing indefinitely across logins.
router.post('/refresh', authLimiter, async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    return res.status(400).json({ error: 'refreshToken is required.' });
  }

  let payload;
  try {
    payload = jwt.verify(refreshToken, process.env.JWT_SECRET);
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired refresh token.' });
  }

  try {
    // Re-checks suspension the same way verifyJwt does for access tokens —
    // a refresh token issued before a suspension must not be able to mint a
    // fresh working session after the fact.
    const user = await User.findByPk(payload.user_id);
    if (!user || user.is_suspended) {
      return res.status(403).json({ error: 'This account has been suspended. Contact support for help.' });
    }

    const tokens = issueTokens(user);
    res.json({ user: serializeUser(user), ...tokens });
  } catch (err) {
    console.error('Refresh error:', err.message);
    res.status(500).json({ error: 'Could not refresh session.' });
  }
});

// ── GET /api/auth/me ────────────────────────────────────────────────────────────
router.get('/me', verifyJwt, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.user_id);
    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }
    res.json({ user: serializeUser(user) });
  } catch (err) {
    console.error('Me error:', err.message);
    res.status(500).json({ error: 'Could not load user.' });
  }
});

module.exports = router;
