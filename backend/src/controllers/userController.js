const User = require('../models/User');

exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.listUsers = async (req, res) => {
  try {
    const users = await User.find({ role: 'commuter' })
      .select('_id full_name email role');

    const filtered = users.filter(u => String(u._id) !== String(req.user.id));
    res.status(200).json(filtered);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
