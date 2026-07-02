const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../db/models/user');
const verifyJwt = require('../middleware/verifyJwt');

const router = express.Router();

const ACCESS_TOKEN_TTL = '1h';
const ACCESS_TOKEN_TTL_MS = 60 * 60 * 1000;
const REFRESH_TOKEN_TTL = process.env.JWT_EXPIRES_IN || '7d';
const REFRESH_TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000;

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
router.post('/register', async (req, res) => {
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
router.post('/login', async (req, res) => {
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

    const tokens = issueTokens(user);
    res.json({ user: serializeUser(user), ...tokens });
  } catch (err) {
    console.error('Login error:', err.message);
    res.status(500).json({ error: 'Login failed.' });
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
