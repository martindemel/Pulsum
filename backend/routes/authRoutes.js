const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// Oura routes
router.get('/oura/status', authController.checkOuraAuthStatus);
router.post('/oura/personal-token', authController.setOuraPersonalToken);

// Dexcom OAuth routes (optional)
router.get('/dexcom/login', authController.getDexcomLoginUrl);
router.get('/dexcom/callback', authController.handleDexcomCallback);
router.get('/dexcom/status', authController.checkDexcomAuthStatus);
router.post('/dexcom/toggle', authController.toggleDexcomIntegration);

module.exports = router; 