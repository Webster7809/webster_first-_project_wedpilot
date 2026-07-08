// One-off admin provisioning script — run manually, never exposed via the API.
// Usage: node scripts/createAdmin.js <email> <password> [name]
require('dotenv').config();
const bcrypt = require('bcrypt');
const sequelize = require('../db/sequelize');
const User = require('../db/models/user');

async function main() {
  const [, , email, password, name = 'Admin'] = process.argv;

  if (!email || !password) {
    console.error('Usage: node scripts/createAdmin.js <email> <password> [name]');
    process.exit(1);
  }
  if (password.length < 6) {
    console.error('Password must be at least 6 characters.');
    process.exit(1);
  }

  const normalisedEmail = email.toLowerCase().trim();
  await sequelize.authenticate();

  const existing = await User.findOne({ where: { email: normalisedEmail } });
  if (existing) {
    if (existing.role === 'admin') {
      console.log(`${normalisedEmail} is already an admin.`);
    } else {
      existing.role = 'admin';
      await existing.save();
      console.log(`Promoted existing user ${normalisedEmail} to admin.`);
    }
    process.exit(0);
  }

  const password_hash = await bcrypt.hash(password, 10);
  await User.create({
    email: normalisedEmail,
    password_hash,
    name,
    role: 'admin',
    is_verified: true,
  });
  console.log(`Created admin account: ${normalisedEmail}`);
  process.exit(0);
}

main().catch((err) => {
  console.error('Failed to create admin:', err.message);
  process.exit(1);
});
