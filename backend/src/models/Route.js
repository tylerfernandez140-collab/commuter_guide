const mongoose = require('mongoose');

const routeSchema = new mongoose.Schema({
  route_name: { type: String, required: true },
  vehicle_type: { type: String, enum: ['jeepney', 'minibus', 'ejeepney'], required: true },
  start_point: { type: String, required: true },
  end_point: { type: String, required: true },
  fare: { type: Number, required: true },
  estimated_time: { type: Number, required: true }, // in minutes
  route_status: { type: String, enum: ['active', 'inactive'], default: 'active' },
  landmarks: [{ type: String }],
  coordinates: [{
    lat: { type: Number, required: true },
    lng: { type: Number, required: true }
  }],
  created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Route', routeSchema);
