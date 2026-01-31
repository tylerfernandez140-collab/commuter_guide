const express = require('express');
const router = express.Router();
const landmarkController = require('../controllers/landmarkController');
const { verifyToken, isAdmin } = require('../middleware/authMiddleware');

router.post('/', verifyToken, isAdmin, landmarkController.createLandmark);
router.get('/', landmarkController.getAllLandmarks);
router.get('/route/:routeName', landmarkController.getLandmarksByRoute);

module.exports = router;
