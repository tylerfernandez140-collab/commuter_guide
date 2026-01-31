const mongoose = require('mongoose');

const searchLogSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  destination: { type: String, required: true },
  suggested_route: { type: String, required: true },
  searched_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('SearchLog', searchLogSchema);
