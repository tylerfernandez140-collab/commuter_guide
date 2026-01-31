const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/resend-verification', authController.resendVerification);
router.get('/verify', authController.verifyEmail);

module.exports = router;
