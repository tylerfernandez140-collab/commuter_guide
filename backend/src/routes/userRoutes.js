const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyToken, isAdmin } = require('../middleware/authMiddleware');

router.get('/me', verifyToken, userController.getProfile);
router.get('/', verifyToken, isAdmin, userController.listUsers);

module.exports = router;
