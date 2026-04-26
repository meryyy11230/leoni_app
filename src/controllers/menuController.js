const db = require('../config/db');

// Publier menu du jour (ADMIN)
const publishMenu = (req, res) => {
  const { menu_date, product_ids } = req.body;

  if (!menu_date || !product_ids || product_ids.length === 0) {
    return res.status(400).json({
      message: 'menu_date et product_ids sont obligatoires'
    });
  }

  // Vérifier si menu existe déjà
  db.query(
    'SELECT * FROM daily_menus WHERE menu_date = ?',
    [menu_date],
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });

      if (results.length > 0) {
        return res.status(400).json({
          message: 'Menu déjà publié pour cette date'
        });
      }

      // Créer menu
      db.query(
        'INSERT INTO daily_menus (menu_date) VALUES (?)',
        [menu_date],
        (err, result) => {
          if (err) return res.status(500).json({ error: err.message });

          const menuId = result.insertId;

          // Ajouter les produits au menu
          const values = product_ids.map(pid => [menuId, pid]);

          db.query(
            'INSERT INTO daily_menu_items (daily_menu_id, product_id) VALUES ?',
            [values],
            (err) => {
              if (err) return res.status(500).json({ error: err.message });

              return res.status(201).json({
                message: 'Menu publié avec succès',
                menuId
              });
            }
          );
        }
      );
    }
  );
};

// Récupérer menu du jour
const getTodayMenu = (req, res) => {
  const today = new Date().toISOString().split('T')[0];

  const sql = `
    SELECT p.*, c.name AS category_name
    FROM daily_menus dm
    INNER JOIN daily_menu_items dmi ON dm.id = dmi.daily_menu_id
    INNER JOIN products p ON dmi.product_id = p.id
    INNER JOIN categories c ON p.category_id = c.id
    WHERE dm.menu_date = ?
  `;

  db.query(sql, [today], (err, results) => {
    if (err) {
      return res.status(500).json({
        message: 'Erreur récupération menu',
        error: err.message
      });
    }

    return res.status(200).json(results);
  });
};

module.exports = { publishMenu, getTodayMenu };