const mongoose = require('mongoose');

const landmarkSchema = new mongoose.Schema({
  name: { type: String, required: true },
  type: {
    type: String,
    enum: ['Hospital', 'Government Office', 'Market', 'School', 'Airport', 'Mall', 'Cemetery', 'Restaurant', 'Establishment'],
    required: true
  },
  near_route: { type: String, required: true },
  latitude: { type: Number, required: true },
  longitude: { type: Number, required: true },
  created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Landmark', landmarkSchema);
