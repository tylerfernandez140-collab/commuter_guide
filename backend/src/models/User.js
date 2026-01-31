const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  full_name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['admin', 'commuter'], default: 'commuter' },
  isVerified: { type: Boolean, default: false },
  verificationToken: { type: String },
  created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', userSchema);
