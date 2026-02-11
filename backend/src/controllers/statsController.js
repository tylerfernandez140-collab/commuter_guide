const Route = require('../models/Route');
const Landmark = require('../models/Landmark');
const Suggestion = require('../models/Suggestion');
const User = require('../models/User');

// Get Dashboard Stats
exports.getDashboardStats = async (req, res) => {
  try {
    // Get total active routes
    const totalRoutes = await Route.countDocuments({ route_status: 'active' });
    
    // Get total landmarks
    const totalLandmarks = await Landmark.countDocuments();
    
    // Get pending suggestions
    const pendingSuggestions = await Suggestion.countDocuments({ status: 'pending' });
    
    // Get total users (excluding admin)
    const totalUsers = await User.countDocuments({ role: 'commuter' });

    res.json({
      routes: totalRoutes,
      landmarks: totalLandmarks,
      pendingSuggestions: pendingSuggestions,
      users: totalUsers
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
