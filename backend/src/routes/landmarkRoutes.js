const express = require('express');
const router = express.Router();
const landmarkController = require('../controllers/landmarkController');
const { verifyToken, isAdmin } = require('../middleware/authMiddleware');

console.log('[LANDMARK ROUTES] File loaded!');

router.post('/', verifyToken, isAdmin, landmarkController.createLandmark);
router.get('/', landmarkController.getAllLandmarks);
router.get('/route/:routeName', landmarkController.getLandmarksByRoute);
router.put('/:id', verifyToken, isAdmin, landmarkController.updateLandmark);
router.delete('/:id', verifyToken, isAdmin, landmarkController.deleteLandmark);

// Test route
router.get('/test', (req, res) => res.json({ message: 'Landmark routes working' }));

module.exports = router;
