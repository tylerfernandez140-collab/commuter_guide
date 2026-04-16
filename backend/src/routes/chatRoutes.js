const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const { verifyToken } = require('../middleware/authMiddleware');

// Chat endpoint - requires authentication
router.post('/', verifyToken, chatController.chat);

module.exports = router;
