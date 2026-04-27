const db = require('../config/db');

// Afficher tous les produits
const getAllProducts = (req, res) => {
  const sql = `
    SELECT products.*, categories.name AS category_name
    FROM products
    INNER JOIN categories ON products.category_id = categories.id
    ORDER BY products.id DESC
  `;

  db.query(sql, (err, results) => {
    if (err) {
      return res.status(500).json({
        message: 'Erreur lors de la récupération des produits',
        error: err.message
      });
    }

    return res.status(200).json(results);
  });
};

// Ajouter un produit
const createProduct = (req, res) => {
  const { category_id, name, description, price, image_url, is_available } = req.body;

  if (!category_id || !name || !price) {
    return res.status(400).json({
      message: 'category_id, name et price sont obligatoires'
    });
  }

  const sql = `
    INSERT INTO products (category_id, name, description, price, image_url, is_available)
    VALUES (?, ?, ?, ?, ?, ?)
  `;

  db.query(
    sql,
    [
      category_id,
      name,
      description || null,
      price,
      image_url || null,
      is_available !== undefined ? is_available : true
    ],
    (err, result) => {
      if (err) {
        return res.status(500).json({
          message: 'Erreur lors de l’ajout du produit',
          error: err.message
        });
      }

      return res.status(201).json({
        message: 'Produit ajouté avec succès',
        productId: result.insertId
      });
    }
  );
};

// Modifier un produit
const updateProduct = (req, res) => {
  const { id } = req.params;
  const { category_id, name, description, price, image_url, is_available } = req.body;

  if (!category_id || !name || !price) {
    return res.status(400).json({
      message: 'category_id, name et price sont obligatoires'
    });
  }

  const sql = `
    UPDATE products
    SET category_id = ?, name = ?, description = ?, price = ?, image_url = ?, is_available = ?
    WHERE id = ?
  `;

  db.query(
    sql,
    [
      category_id,
      name,
      description || null,
      price,
      image_url || null,
      is_available !== undefined ? is_available : true,
      id
    ],
    (err, result) => {
      if (err) {
        return res.status(500).json({
          message: 'Erreur lors de la modification du produit',
          error: err.message
        });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({
          message: 'Produit introuvable'
        });
      }

      return res.status(200).json({
        message: 'Produit modifié avec succès'
      });
    }
  );
};

// Supprimer un produit
const deleteProduct = (req, res) => {
  const { id } = req.params;

  db.query(
    'DELETE FROM products WHERE id = ?',
    [id],
    (err, result) => {
      if (err) {
        return res.status(500).json({
          message: 'Erreur lors de la suppression du produit',
          error: err.message
        });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({
          message: 'Produit introuvable'
        });
      }

      return res.status(200).json({
        message: 'Produit supprimé avec succès'
      });
    }
  );
};

module.exports = {
  getAllProducts,
  createProduct,
  updateProduct,
  deleteProduct
};