const express = require('express');
const router = express.Router();
const searchController = require('../controllers/searchController');
const { verifyToken, isCommuter } = require('../middleware/authMiddleware');

router.post('/', verifyToken, isCommuter, searchController.searchDestination);

module.exports = router;
