const express = require('express');
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const { OAuth2Client } = require('google-auth-library');
const User = require('../db/models/user');
const verifyJwt = require('../middleware/verifyJwt');
const { sendPasswordResetEmail, sendVerificationEmail } = require('../services/mailer');

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

// Verification mail is the same spam/harassment and SMTP-quota vector as the
// reset mail — resend is reachable with any valid session, and /verify-email
// is an unauthenticated token guess. Its own bucket rather than sharing the
// password one, so burning through resends can't lock a user out of a reset.
const verifyEmailLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 8,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many attempts. Please wait a few minutes and try again.' },
});

// Matches what register_screen.dart and reset_password_screen.dart already
// enforce in the client ("Min 8 characters"). The server had been accepting 6,
// which meant the only real policy was one a non-Flutter caller could ignore
// entirely — the client validation is a convenience, this is the rule.
const MIN_PASSWORD_LENGTH = 8;

// bcrypt's cost factor doubles work per increment. 12 is the current
// commodity-hardware default (~250ms per hash) and is applied to new hashes
// only — the cost is encoded in each stored hash, so accounts created at 10
// keep verifying correctly and are upgraded whenever they next reset.
const BCRYPT_ROUNDS = 12;

const ACCESS_TOKEN_TTL = '1h';
const ACCESS_TOKEN_TTL_MS = 60 * 60 * 1000;
const REFRESH_TOKEN_TTL = process.env.JWT_EXPIRES_IN || '7d';
const REFRESH_TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const RESET_TOKEN_TTL_MS = 60 * 60 * 1000;
// Longer than the reset TTL: a reset is something you asked for seconds ago,
// but a signup confirmation often waits until someone next opens their mail.
const VERIFY_TOKEN_TTL_MS = 24 * 60 * 60 * 1000;
const PUBLIC_WEB_BASE_URL = process.env.PUBLIC_WEB_BASE_URL || 'http://localhost:8080';

const hashToken = (token) => crypto.createHash('sha256').update(token).digest('hex');

/// Mints a fresh verification token for [user], stores only its hash, and
/// returns the link to mail out. Issuing again invalidates the previous link,
/// so a resend can't leave two live tokens on one account.
async function issueVerificationLink(user) {
  const rawToken = crypto.randomBytes(32).toString('hex');
  user.verify_token_hash = hashToken(rawToken);
  user.verify_token_expires = new Date(Date.now() + VERIFY_TOKEN_TTL_MS);
  await user.save();
  return `${PUBLIC_WEB_BASE_URL}/#/verify-email?token=${rawToken}`;
}

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
    phone: user.phone,
    role: user.role,
    is_verified: user.is_verified,
    created_at: user.created_at,
    email_notifications: user.email_notifications,
  };
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// ── POST /api/auth/register ───────────────────────────────────────────────────
router.post('/register', authLimiter, async (req, res) => {
  const { email, password, name, phone, role = 'couple' } = req.body;

  if (!email || !EMAIL_RE.test(email)) {
    return res.status(400).json({ error: 'A valid email is required.' });
  }
  if (!password || password.length < MIN_PASSWORD_LENGTH) {
    return res.status(400).json({ error: `Password must be at least ${MIN_PASSWORD_LENGTH} characters.` });
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

    const password_hash = await bcrypt.hash(password, BCRYPT_ROUNDS);
    const user = await User.create({
      email: normalisedEmail,
      password_hash,
      name,
      phone: typeof phone === 'string' && phone.trim() ? phone.trim() : null,
      role,
    });

    // Best effort, and deliberately after the account exists: a signup must
    // not fail because SMTP is down or slow. If this throws, the account is
    // still usable and the verify screen's resend button covers the gap.
    try {
      await sendVerificationEmail(user.email, await issueVerificationLink(user));
    } catch (err) {
      console.error('Verification email failed for', user.email, err.message);
    }

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
      const password_hash = await bcrypt.hash(crypto.randomBytes(32).toString('hex'), BCRYPT_ROUNDS);
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

// ── POST /api/auth/resend-verification ────────────────────────────────────────
// Authenticated: you can only ask for a new link to your own address, so there
// is no address-enumeration surface here and the response can be specific.
router.post('/resend-verification', verifyEmailLimiter, verifyJwt, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.user_id);
    if (!user) {
      return res.status(404).json({ error: 'Account not found.' });
    }
    if (user.is_verified) {
      return res.status(409).json({ error: 'This email address is already verified.' });
    }

    await sendVerificationEmail(user.email, await issueVerificationLink(user));
    res.json({ message: 'Verification email sent.' });
  } catch (err) {
    console.error('Resend verification error:', err.message);
    res.status(500).json({ error: 'Could not send the verification email.' });
  }
});

// ── POST /api/auth/verify-email ───────────────────────────────────────────────
// Unauthenticated on purpose: the link is token-identified, and it gets opened
// in whatever browser the user's mail client hands it to — not necessarily one
// holding a session.
router.post('/verify-email', verifyEmailLimiter, async (req, res) => {
  const { token } = req.body;
  if (!token) {
    return res.status(400).json({ error: 'Missing verification token.' });
  }

  try {
    const user = await User.findOne({ where: { verify_token_hash: hashToken(token) } });
    if (!user || !user.verify_token_expires || user.verify_token_expires < new Date()) {
      return res.status(400).json({ error: 'This verification link is invalid or has expired.' });
    }

    user.is_verified = true;
    user.verify_token_hash = null;
    user.verify_token_expires = null;
    await user.save();

    res.json({ message: 'Email verified.', user: serializeUser(user) });
  } catch (err) {
    console.error('Verify email error:', err.message);
    res.status(500).json({ error: 'Could not verify this email address.' });
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
  if (!newPassword || newPassword.length < MIN_PASSWORD_LENGTH) {
    return res.status(400).json({ error: `Password must be at least ${MIN_PASSWORD_LENGTH} characters.` });
  }

  try {
    const user = await User.findOne({ where: { reset_token_hash: hashToken(token) } });
    if (!user || !user.reset_token_expires || user.reset_token_expires < new Date()) {
      return res.status(400).json({ error: 'This reset link is invalid or has expired.' });
    }

    user.password_hash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
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

// ── POST /api/auth/change-password ────────────────────────────────────────────
// Distinct from /reset-password: this is for a signed-in user who still knows
// their current password and wants to set a new one, without leaving the app
// or waiting on an email round-trip. Requires the current password rather
// than trusting the access token alone — a stolen-but-not-yet-expired token
// should not be enough on its own to lock the real owner out.
router.post('/change-password', authLimiter, verifyJwt, async (req, res) => {
  const { currentPassword, newPassword } = req.body;

  if (!currentPassword) {
    return res.status(400).json({ error: 'Your current password is required.' });
  }
  if (!newPassword || newPassword.length < MIN_PASSWORD_LENGTH) {
    return res.status(400).json({ error: `New password must be at least ${MIN_PASSWORD_LENGTH} characters.` });
  }

  try {
    const user = await User.findByPk(req.user.user_id);
    if (!user) {
      return res.status(404).json({ error: 'Account not found.' });
    }

    const currentMatches = await bcrypt.compare(currentPassword, user.password_hash);
    if (!currentMatches) {
      return res.status(401).json({ error: 'Your current password is incorrect.' });
    }

    user.password_hash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    await user.save();

    res.json({ message: 'Password updated.' });
  } catch (err) {
    console.error('Change password error:', err.message);
    res.status(500).json({ error: 'Could not update your password.' });
  }
});

// ── PATCH /api/auth/notification-preferences ──────────────────────────────────
router.patch('/notification-preferences', verifyJwt, async (req, res) => {
  const { emailNotifications } = req.body;
  if (typeof emailNotifications !== 'boolean') {
    return res.status(400).json({ error: 'emailNotifications must be a boolean.' });
  }

  try {
    const user = await User.findByPk(req.user.user_id);
    if (!user) {
      return res.status(404).json({ error: 'Account not found.' });
    }

    user.email_notifications = emailNotifications;
    await user.save();

    res.json({ user: serializeUser(user) });
  } catch (err) {
    console.error('Update notification preferences error:', err.message);
    res.status(500).json({ error: 'Could not update notification preferences.' });
  }
});

// ── POST /api/auth/delete-account ─────────────────────────────────────────────
// Scrubs PII and blocks login rather than a real row delete — migration 004
// makes `inquiries` and `vendor_feedback` RESTRICT (not CASCADE) on this
// user's id specifically so one party's deletion can't erase the other
// party's booking history, so a real DELETE FROM users would throw a foreign
// key violation for any account with a booking or feedback on record.
// Reuses is_suspended so the existing login/refresh/verifyJwt checks block
// access immediately with no new gate to add; deleted_at distinguishes this
// from an admin-issued suspension.
router.post('/delete-account', authLimiter, verifyJwt, async (req, res) => {
  const { currentPassword } = req.body;

  if (!currentPassword) {
    return res.status(400).json({ error: 'Your current password is required.' });
  }

  try {
    const user = await User.findByPk(req.user.user_id);
    if (!user) {
      return res.status(404).json({ error: 'Account not found.' });
    }

    const currentMatches = await bcrypt.compare(currentPassword, user.password_hash);
    if (!currentMatches) {
      return res.status(401).json({ error: 'Your current password is incorrect.' });
    }

    user.email = `deleted-${user.user_id}@wedpilot.invalid`;
    user.name = 'Deleted user';
    user.phone = null;
    user.avatar_url = null;
    user.password_hash = await bcrypt.hash(crypto.randomBytes(32).toString('hex'), BCRYPT_ROUNDS);
    user.is_suspended = true;
    user.deleted_at = new Date();
    await user.save();

    res.json({ message: 'Account deleted.' });
  } catch (err) {
    console.error('Delete account error:', err.message);
    res.status(500).json({ error: 'Could not delete your account.' });
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
