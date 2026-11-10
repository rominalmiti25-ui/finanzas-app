require('dotenv').config();
const secret = process.env.JWT_SECRET;
if (!secret || secret.length < 16) {
  console.error('JWT_SECRET no definido o demasiado corto (mínimo 16 caracteres). Revisa tu .env');
  process.exit(1);
}
module.exports = {
  PORT: Number(process.env.PORT || 3000),
  JWT_SECRET: secret,
  JWT_EXPIRES: process.env.JWT_EXPIRES || '12h',
};
