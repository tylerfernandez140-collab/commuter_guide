const mongoose = require('mongoose');

const chatLogSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  question: { type: String, required: true },
  ai_response: { type: String, required: true },
  timestamp: { type: Date, default: Date.now }
});

module.exports = mongoose.model('ChatLog', chatLogSchema);
