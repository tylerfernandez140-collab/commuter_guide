const mongoose = require('mongoose');

const suggestionSchema = new mongoose.Schema({
  landmark_name: { type: String, required: true },
  latitude: { type: Number, required: true },
  longitude: { type: Number, required: true },
  submitted_by: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
  submitted_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Suggestion', suggestionSchema);
