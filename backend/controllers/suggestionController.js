const Suggestion = require('../models/Suggestion');

// Submit Suggestion (Commuter)
exports.submitSuggestion = async (req, res) => {
  try {
    const { landmark_name, latitude, longitude } = req.body;
    
    const suggestion = new Suggestion({
      landmark_name,
      latitude,
      longitude,
      submitted_by: req.user.id
    });

    await suggestion.save();
    res.status(201).json({ message: 'Suggestion submitted successfully', suggestion });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// View Suggestions (Admin)
exports.getSuggestions = async (req, res) => {
  try {
    const suggestions = await Suggestion.find().populate('submitted_by', 'full_name email');
    res.json(suggestions);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Approve Suggestion
exports.approveSuggestion = async (req, res) => {
  try {
    const suggestion = await Suggestion.findByIdAndUpdate(
      req.params.id, 
      { status: 'approved' }, 
      { new: true }
    );
    if (!suggestion) return res.status(404).json({ message: 'Suggestion not found' });
    
    // TODO: Optionally add to Landmarks collection automatically
    
    res.json(suggestion);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Reject Suggestion
exports.rejectSuggestion = async (req, res) => {
  try {
    const suggestion = await Suggestion.findByIdAndUpdate(
      req.params.id, 
      { status: 'rejected' }, 
      { new: true }
    );
    if (!suggestion) return res.status(404).json({ message: 'Suggestion not found' });
    res.json(suggestion);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
