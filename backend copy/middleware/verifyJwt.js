const jwt = require('jsonwebtoken');
const User = require('../db/models/user');

async function verifyJwt(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header.' });
  }
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }

  // A short-lived access token can outlive an admin suspending the account
  // mid-session, so re-check current status on every request rather than
  // trusting whatever the token claimed at login time.
  try {
    const user = await User.findByPk(req.user.user_id, { attributes: ['is_suspended'] });
    if (!user || user.is_suspended) {
      return res.status(403).json({ error: 'This account has been suspended. Contact support for help.' });
    }
    next();
  } catch (err) {
    return res.status(500).json({ error: 'Could not verify account status.' });
  }
}

module.exports = verifyJwt;
