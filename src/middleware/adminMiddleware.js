const adminMiddleware = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({
      message: 'Accès refusé, administrateur uniquement'
    });
  }

  next();
};

module.exports = adminMiddleware;