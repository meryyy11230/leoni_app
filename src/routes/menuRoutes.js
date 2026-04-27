const express = require('express');
const router = express.Router();
const { publishMenu, getTodayMenu } = require('../controllers/menuController');
const authMiddleware = require('../middleware/authMiddleware');
const adminMiddleware = require('../middleware/adminMiddleware');

// Admin publie menu
router.post('/publish', authMiddleware, adminMiddleware, publishMenu);

// Utilisateur voit menu du jour
router.get('/today', getTodayMenu);

module.exports = router;