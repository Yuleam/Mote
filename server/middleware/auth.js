/**
 * JWT 인증 미들웨어
 */
const jwt = require('jsonwebtoken');

function getSecret() {
  return process.env.JWT_SECRET;
}

function authMiddleware(req, res, next) {
  const secret = getSecret();
  if (!secret) {
    return res.status(500).json({ error: 'Server configuration error' });
  }
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Login required' });
  }
  const token = header.slice(7);
  try {
    req.user = jwt.verify(token, secret);
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Session expired. Please sign in again' });
  }
}

module.exports = { authMiddleware, getSecret };
