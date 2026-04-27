const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        message: 'Accès refusé, token manquant'
      });
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        message: 'Token invalide'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');

    req.user = decoded;

    next();
  } catch (error) {
    return res.status(401).json({
      message: 'Token invalide ou expiré',
      error: error.message
    });
  }
};

module.exports = authMiddleware;