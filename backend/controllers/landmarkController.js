const Landmark = require('../models/Landmark');

// Create Landmark (Admin)
exports.createLandmark = async (req, res) => {
  try {
    const newLandmark = new Landmark(req.body);
    const savedLandmark = await newLandmark.save();
    res.status(201).json(savedLandmark);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get All Landmarks
exports.getAllLandmarks = async (req, res) => {
  try {
    const landmarks = await Landmark.find();
    res.json(landmarks);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get Landmarks by Route
exports.getLandmarksByRoute = async (req, res) => {
  try {
    const { routeName } = req.params;
    const landmarks = await Landmark.find({ near_route: routeName });
    res.json(landmarks);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
