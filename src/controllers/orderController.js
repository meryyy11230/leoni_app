const db = require('../config/db');

// Valider le panier en commande
const checkout = (req, res) => {
  const userId = req.user.id;

  db.query(
    'SELECT * FROM carts WHERE user_id = ? AND status = "active"',
    [userId],
    (err, cartResults) => {
      if (err) {
        return res.status(500).json({
          message: 'Erreur serveur',
          error: err.message
        });
      }

      if (cartResults.length === 0) {
        return res.status(404).json({
          message: 'Aucun panier actif trouvé'
        });
      }

      const cart = cartResults[0];

      const sqlCartItems = `
        SELECT ci.*, p.name AS product_name
        FROM cart_items ci
        INNER JOIN products p ON ci.product_id = p.id
        WHERE ci.cart_id = ?
      `;

      db.query(sqlCartItems, [cart.id], (err, cartItems) => {
        if (err) {
          return res.status(500).json({
            message: 'Erreur récupération panier',
            error: err.message
          });
        }

        if (cartItems.length === 0) {
          return res.status(400).json({
            message: 'Le panier est vide'
          });
        }

        const totalPrice = cartItems.reduce((sum, item) => {
          return sum + parseFloat(item.unit_price) * item.quantity;
        }, 0);

        db.query(
          'INSERT INTO orders (user_id, total_price, status) VALUES (?, ?, "pending")',
          [userId, totalPrice],
          (err, orderResult) => {
            if (err) {
              return res.status(500).json({
                message: 'Erreur création commande',
                error: err.message
              });
            }

            const orderId = orderResult.insertId;

            const orderItemsValues = cartItems.map(item => [
              orderId,
              item.product_id,
              item.product_name,
              item.quantity,
              item.unit_price,
              item.quantity * parseFloat(item.unit_price)
            ]);

            db.query(
              `INSERT INTO order_items
              (order_id, product_id, product_name, quantity, unit_price, subtotal)
              VALUES ?`,
              [orderItemsValues],
              (err) => {
                if (err) {
                  return res.status(500).json({
                    message: 'Erreur création lignes commande',
                    error: err.message
                  });
                }

                db.query(
                  'UPDATE carts SET status = "validated" WHERE id = ?',
                  [cart.id],
                  (err) => {
                    if (err) {
                      return res.status(500).json({
                        message: 'Erreur mise à jour panier',
                        error: err.message
                      });
                    }

                    return res.status(201).json({
                      message: 'Commande créée avec succès',
                      order_id: orderId,
                      total_price: totalPrice
                    });
                  }
                );
              }
            );
          }
        );
      });
    }
  );
};

// Voir mes commandes
const getMyOrders = (req, res) => {
  const userId = req.user.id;

  const sql = `
    SELECT * FROM orders
    WHERE user_id = ?
    ORDER BY ordered_at DESC
  `;

  db.query(sql, [userId], (err, orders) => {
    if (err) {
      return res.status(500).json({
        message: 'Erreur récupération commandes',
        error: err.message
      });
    }

    return res.status(200).json(orders);
  });
};

// Voir toutes les commandes (ADMIN)
const getAllOrders = (req, res) => {
  const sql = `
    SELECT o.*, u.name, u.matricule
    FROM orders o
    INNER JOIN users u ON o.user_id = u.id
    ORDER BY o.ordered_at DESC
  `;

  db.query(sql, (err, results) => {
    if (err) {
      return res.status(500).json({
        message: 'Erreur récupération commandes',
        error: err.message
      });
    }

    return res.status(200).json(results);
  });
};

// Changer statut commande (ADMIN)
const updateOrderStatus = (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  const allowedStatus = [
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'delivered',
    'cancelled'
  ];

  if (!allowedStatus.includes(status)) {
    return res.status(400).json({
      message: 'Statut invalide'
    });
  }

  db.query(
    'UPDATE orders SET status = ? WHERE id = ?',
    [status, id],
    (err, result) => {
      if (err) {
        return res.status(500).json({
          message: 'Erreur mise à jour statut',
          error: err.message
        });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({
          message: 'Commande introuvable'
        });
      }

      return res.status(200).json({
        message: 'Statut mis à jour avec succès'
      });
    }
  );
};

// Détail d'une commande
const getOrderById = (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  db.query(
    'SELECT * FROM orders WHERE id = ?',
    [id],
    (err, orderResults) => {
      if (err) {
        return res.status(500).json({
          message: 'Erreur récupération commande',
          error: err.message
        });
      }

      if (orderResults.length === 0) {
        return res.status(404).json({
          message: 'Commande introuvable'
        });
      }

      const order = orderResults[0];

      if (order.user_id !== userId && req.user.role !== 'admin') {
        return res.status(403).json({
          message: 'Accès refusé'
        });
      }

      const sql = `
        SELECT product_name, quantity, unit_price, subtotal
        FROM order_items
        WHERE order_id = ?
      `;

      db.query(sql, [id], (err, items) => {
        if (err) {
          return res.status(500).json({
            message: 'Erreur récupération items',
            error: err.message
          });
        }

        return res.status(200).json({
          order,
          items
        });
      });
    }
  );
};

module.exports = {
  checkout,
  getMyOrders,
  getAllOrders,
  updateOrderStatus,
  getOrderById
};