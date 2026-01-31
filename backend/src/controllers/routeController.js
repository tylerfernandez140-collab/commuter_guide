const Route = require('../models/Route');

// Create Route (Admin)
exports.createRoute = async (req, res) => {
  try {
    const newRoute = new Route(req.body);
    const savedRoute = await newRoute.save();
    res.status(201).json(savedRoute);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get All Routes
exports.getAllRoutes = async (req, res) => {
  try {
    const routes = await Route.find();
    res.json(routes);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get Single Route
exports.getRouteById = async (req, res) => {
  try {
    const route = await Route.findById(req.params.id);
    if (!route) return res.status(404).json({ message: 'Route not found' });
    res.json(route);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Update Route (Admin)
exports.updateRoute = async (req, res) => {
  try {
    const updatedRoute = await Route.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!updatedRoute) return res.status(404).json({ message: 'Route not found' });
    res.json(updatedRoute);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Delete Route (Admin)
exports.deleteRoute = async (req, res) => {
  try {
    const deletedRoute = await Route.findByIdAndDelete(req.params.id);
    if (!deletedRoute) return res.status(404).json({ message: 'Route not found' });
    res.json({ message: 'Route deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
