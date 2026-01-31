const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const { verifyToken } = require('../middleware/authMiddleware');

// Chat can be open or protected. Assuming protected for now to log user history.
// If you want public chat, remove verifyToken.
router.post('/', verifyToken, chatController.chat);

module.exports = router;
