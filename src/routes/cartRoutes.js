const express = require('express');
const router = express.Router();

const {
  addToCart,
  getMyCart,
  updateCartItem,
  removeCartItem
} = require('../controllers/cartController');

const authMiddleware = require('../middleware/authMiddleware');

router.post('/add', authMiddleware, addToCart);
router.get('/', authMiddleware, getMyCart);
router.put('/item/:id', authMiddleware, updateCartItem);
router.delete('/item/:id', authMiddleware, removeCartItem);

module.exports = router;