const express = require('express');
const router = express.Router();
const suggestionController = require('../controllers/suggestionController');
const { verifyToken, isCommuter, isAdmin } = require('../middleware/authMiddleware');

router.post('/', verifyToken, isCommuter, suggestionController.submitSuggestion);
router.get('/', verifyToken, isAdmin, suggestionController.getSuggestions);
router.put('/:id/approve', verifyToken, isAdmin, suggestionController.approveSuggestion);
router.put('/:id/reject', verifyToken, isAdmin, suggestionController.rejectSuggestion);

module.exports = router;
