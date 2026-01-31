const express = require('express');
const router = express.Router();
const routeController = require('../controllers/routeController');
const { verifyToken, isAdmin } = require('../middleware/authMiddleware');

router.post('/', verifyToken, isAdmin, routeController.createRoute);
router.get('/', routeController.getAllRoutes);
router.get('/:id', routeController.getRouteById);
router.put('/:id', verifyToken, isAdmin, routeController.updateRoute);
router.delete('/:id', verifyToken, isAdmin, routeController.deleteRoute);

module.exports = router;
