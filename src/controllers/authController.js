const db = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const register = async (req, res) => {
  try {
    const { matricule, password } = req.body;

    if (!matricule || !password) {
      return res.status(400).json({
        message: 'Matricule et mot de passe sont obligatoires'
      });
    }

    db.query(
      'SELECT * FROM employee_references WHERE matricule = ? AND is_active = 1',
      [matricule],
      async (err, results) => {
        if (err) {
          return res.status(500).json({
            message: 'Erreur serveur',
            error: err.message
          });
        }

        if (results.length === 0) {
          return res.status(404).json({
            message: 'Matricule introuvable ou inactif'
          });
        }

        const employee = results[0];

        db.query(
          'SELECT * FROM users WHERE matricule = ?',
          [matricule],
          async (err, userResults) => {
            if (err) {
              return res.status(500).json({
                message: 'Erreur serveur',
                error: err.message
              });
            }

            if (userResults.length > 0) {
              return res.status(400).json({
                message: 'Ce matricule est déjà inscrit'
              });
            }

            const hashedPassword = await bcrypt.hash(password, 10);
            const fullName = `${employee.nom} ${employee.prenom}`;

            db.query(
              'INSERT INTO users (employee_reference_id, matricule, name, password, role) VALUES (?, ?, ?, ?, ?)',
              [employee.id, matricule, fullName, hashedPassword, 'employee'],
              (err, result) => {
                if (err) {
                  return res.status(500).json({
                    message: 'Erreur lors de la création du compte',
                    error: err.message
                  });
                }

                return res.status(201).json({
                  message: 'Compte créé avec succès',
                  user: {
                    id: result.insertId,
                    matricule: matricule,
                    name: fullName,
                    role: 'employee'
                  }
                });
              }
            );
          }
        );
      }
    );
  } catch (error) {
    return res.status(500).json({
      message: 'Erreur serveur',
      error: error.message
    });
  }
};

const login = (req, res) => {
  try {
    const { matricule, password } = req.body;

    if (!matricule || !password) {
      return res.status(400).json({
        message: 'Matricule et mot de passe requis'
      });
    }

    db.query(
      'SELECT * FROM users WHERE matricule = ?',
      [matricule],
      async (err, results) => {
        if (err) {
          return res.status(500).json({
            message: 'Erreur serveur',
            error: err.message
          });
        }

        if (results.length === 0) {
          return res.status(404).json({
            message: 'Utilisateur non trouvé'
          });
        }

        const user = results[0];
        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
          return res.status(401).json({
            message: 'Mot de passe incorrect'
          });
        }

        const token = jwt.sign(
          {
            id: user.id,
            matricule: user.matricule,
            role: user.role
          },
          process.env.JWT_SECRET || 'secret',
          { expiresIn: '1d' }
        );

        return res.status(200).json({
          message: 'Connexion réussie',
          token,
          user: {
            id: user.id,
            matricule: user.matricule,
            name: user.name,
            role: user.role
          }
        });
      }
    );
  } catch (error) {
    return res.status(500).json({
      message: 'Erreur serveur',
      error: error.message
    });
  }
};

module.exports = { register, login };