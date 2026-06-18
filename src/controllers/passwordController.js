const db = require('../config/db');
const bcrypt = require('bcrypt');
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'bhkmeriem123@gmail.com',
    pass: 'ijea wify xgia gioy'
  }
});

const resetCodes = {};

const forgotPassword = (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ message: 'Email est obligatoire' });
  }

  db.query(
    'SELECT * FROM users WHERE email = ?',
    [email],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Erreur serveur', error: err.message });

      if (results.length === 0) {
        return res.status(404).json({ message: 'Email incorrect ou introuvable' });
      }

      const code = Math.floor(1000 + Math.random() * 9000).toString();

      resetCodes[email] = {
        code,
        expires: Date.now() + 10 * 60 * 1000
      };

      const mailOptions = {
        from: 'bhkmeriem123@gmail.com',
        to: email,
        subject: 'LunchUp - Code de réinitialisation',
        html: `
          <h2>Réinitialisation de mot de passe</h2>
          <p>Votre code de réinitialisation est :</p>
          <h1 style="color: #1a3a6b; font-size: 36px;">${code}</h1>
          <p>Ce code expire dans 10 minutes.</p>
        `
      };

      transporter.sendMail(mailOptions, (err) => {
        if (err) return res.status(500).json({ message: 'Erreur envoi email', error: err.message });
        return res.status(200).json({ message: 'Code envoyé sur votre email' });
      });
    }
  );
};

const verifyCode = (req, res) => {
  const { email, code } = req.body;

  if (!email || !code) {
    return res.status(400).json({ message: 'Email et code sont obligatoires' });
  }

  const record = resetCodes[email];

  if (!record) {
    return res.status(400).json({ message: 'Aucun code trouvé pour cet email' });
  }

  if (Date.now() > record.expires) {
    delete resetCodes[email];
    return res.status(400).json({ message: 'Code expiré' });
  }

  if (record.code !== code) {
    return res.status(400).json({ message: 'Code incorrect' });
  }

  return res.status(200).json({ message: 'Code vérifié avec succès' });
};

const resetPassword = async (req, res) => {
  const { email, code, newPassword } = req.body;

  if (!email || !code || !newPassword) {
    return res.status(400).json({ message: 'Tous les champs sont obligatoires' });
  }

  const record = resetCodes[email];

  if (!record || record.code !== code || Date.now() > record.expires) {
    return res.status(400).json({ message: 'Code invalide ou expiré' });
  }

  const hashedPassword = await bcrypt.hash(newPassword, 10);

  db.query(
    'UPDATE users SET password = ? WHERE email = ?',
    [hashedPassword, email],
    (err) => {
      if (err) return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      delete resetCodes[email];
      return res.status(200).json({ message: 'Mot de passe modifié avec succès' });
    }
  );
};

module.exports = { forgotPassword, verifyCode, resetPassword };