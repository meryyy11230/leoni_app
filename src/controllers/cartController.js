const db = require('../config/db');

// Ajouter un produit au panier
const addToCart = (req, res) => {
  const userId = req.user.id;
  const { product_id, quantity } = req.body;

  if (!product_id || !quantity) {
    return res.status(400).json({
      message: 'product_id et quantity sont obligatoires'
    });
  }

  if (quantity <= 0) {
    return res.status(400).json({
      message: 'La quantité doit être supérieure à 0'
    });
  }

  db.query(
    'SELECT * FROM products WHERE id = ? AND is_available = 1',
    [product_id],
    (err, productResults) => {
      if (err) {
        return res.status(500).json({
          message: 'Erreur serveur',
          error: err.message
        });
      }

      if (productResults.length === 0) {
        return res.status(404).json({
          message: 'Produit introuvable ou indisponible'
        });
      }

      const product = productResults[0];

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

          const createOrUseCart = (cartId) => {
            db.query(
              'SELECT * FROM cart_items WHERE cart_id = ? AND product_id = ?',
              [cartId, product_id],
              (err, itemResults) => {
                if (err) {
                  return res.status(500).json({
                    message: 'Erreur serveur',
                    error: err.message
                  });
                }

                if (itemResults.length > 0) {
                  const newQuantity = itemResults[0].quantity + quantity;

                  db.query(
                    'UPDATE cart_items SET quantity = ? WHERE id = ?',
                    [newQuantity, itemResults[0].id],
                    (err) => {
                      if (err) {
                        return res.status(500).json({
                          message: 'Erreur mise à jour panier',
                          error: err.message
                        });
                      }

                      return res.status(200).json({
                        message: 'Quantité mise à jour dans le panier'
                      });
                    }
                  );
                } else {
                  db.query(
                    'INSERT INTO cart_items (cart_id, product_id, quantity, unit_price) VALUES (?, ?, ?, ?)',
                    [cartId, product_id, quantity, product.price],
                    (err) => {
                      if (err) {
                        return res.status(500).json({
                          message: 'Erreur ajout panier',
                          error: err.message
                        });
                      }

                      return res.status(201).json({
                        message: 'Produit ajouté au panier'
                      });
                    }
                  );
                }
              }
            );
          };

          if (cartResults.length > 0) {
            createOrUseCart(cartResults[0].id);
          } else {
            db.query(
              'INSERT INTO carts (user_id, status) VALUES (?, "active")',
              [userId],
              (err, result) => {
                if (err) {
                  return res.status(500).json({
                    message: 'Erreur création panier',
                    error: err.message
                  });
                }

                createOrUseCart(result.insertId);
              }
            );
          }
        }
      );
    }
  );
};

// Afficher le panier actif
const getMyCart = (req, res) => {
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
        return res.status(200).json({
          message: 'Panier vide',
          items: []
        });
      }

      const cartId = cartResults[0].id;

      const sql = `
        SELECT ci.id, ci.quantity, ci.unit_price,
               p.id AS product_id, p.name, p.description, p.image_url,
               (ci.quantity * ci.unit_price) AS subtotal
        FROM cart_items ci
        INNER JOIN products p ON ci.product_id = p.id
        WHERE ci.cart_id = ?
      `;

      db.query(sql, [cartId], (err, items) => {
        if (err) {
          return res.status(500).json({
            message: 'Erreur récupération panier',
            error: err.message
          });
        }

        const total = items.reduce((sum, item) => sum + parseFloat(item.subtotal), 0);

        return res.status(200).json({
          cart_id: cartId,
          items,
          total
        });
      });
    }
  );
};

// Modifier la quantité d'un item du panier
const updateCartItem = (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;
  const { quantity } = req.body;

  if (!quantity || quantity <= 0) {
    return res.status(400).json({
      message: 'La quantité doit être supérieure à 0'
    });
  }

  const sql = `
    SELECT ci.*, c.user_id, c.status
    FROM cart_items ci
    INNER JOIN carts c ON ci.cart_id = c.id
    WHERE ci.id = ? AND c.user_id = ? AND c.status = "active"
  `;

  db.query(sql, [id, userId], (err, results) => {
    if (err) {
      return res.status(500).json({
        message: 'Erreur serveur',
        error: err.message
      });
    }

    if (results.length === 0) {
      return res.status(404).json({
        message: 'Item panier introuvable'
      });
    }

    db.query(
      'UPDATE cart_items SET quantity = ? WHERE id = ?',
      [quantity, id],
      (err) => {
        if (err) {
          return res.status(500).json({
            message: 'Erreur mise à jour quantité',
            error: err.message
          });
        }

        return res.status(200).json({
          message: 'Quantité modifiée avec succès'
        });
      }
    );
  });
};

// Supprimer un item du panier
const removeCartItem = (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;

  const sql = `
    SELECT ci.*, c.user_id, c.status
    FROM cart_items ci
    INNER JOIN carts c ON ci.cart_id = c.id
    WHERE ci.id = ? AND c.user_id = ? AND c.status = "active"
  `;

  db.query(sql, [id, userId], (err, results) => {
    if (err) {
      return res.status(500).json({
        message: 'Erreur serveur',
        error: err.message
      });
    }

    if (results.length === 0) {
      return res.status(404).json({
        message: 'Item panier introuvable'
      });
    }

    db.query(
      'DELETE FROM cart_items WHERE id = ?',
      [id],
      (err) => {
        if (err) {
          return res.status(500).json({
            message: 'Erreur suppression item',
            error: err.message
          });
        }

        return res.status(200).json({
          message: 'Produit supprimé du panier avec succès'
        });
      }
    );
  });
};

module.exports = {
  addToCart,
  getMyCart,
  updateCartItem,
  removeCartItem
};