const ChatLog = require('../models/ChatLog');
const aiService = require('../services/aiService');

exports.chat = async (req, res) => {
  try {
    const { message, lat, lng, landmarks } = req.body;
    
    // Use AI service to get response
    const reply = await aiService.askAI(message, lat, lng, landmarks);

    // Log interaction if user is logged in (optional, but good for history)
    if (req.user) {
      await ChatLog.create({
        user_id: req.user.id,
        question: message,
        ai_response: reply
      });
    }

    res.json({ reply });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
