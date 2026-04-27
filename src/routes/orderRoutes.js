const express = require('express');
const router = express.Router();

const {
  checkout,
  getMyOrders,
  getAllOrders,
  updateOrderStatus,
  getOrderById
} = require('../controllers/orderController');

const authMiddleware = require('../middleware/authMiddleware');
const adminMiddleware = require('../middleware/adminMiddleware');

// utilisateur
router.post('/checkout', authMiddleware, checkout);
router.get('/my-orders', authMiddleware, getMyOrders);

// admin
router.get('/all', authMiddleware, adminMiddleware, getAllOrders);
router.put('/:id/status', authMiddleware, adminMiddleware, updateOrderStatus);

// détail commande
router.get('/:id', authMiddleware, getOrderById);

module.exports = router;