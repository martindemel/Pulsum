import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import styles from './AuthPage.module.css';

const AuthPage = () => {
  const { isAuthenticated, ouraStatus, dexcomStatus, getDexcomLoginUrl, setOuraPersonalToken } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [personalToken, setPersonalToken] = useState('');
  const location = useLocation();
  const navigate = useNavigate();

  // Check for authentication success/error from OAuth callback
  useEffect(() => {
    const searchParams = new URLSearchParams(location.search);
    const authParam = searchParams.get('auth');
    
    if (authParam === 'dexcom-success') {
      setError(null);
    } else if (authParam === 'dexcom-error') {
      setError('Dexcom authentication failed. Please try again.');
    }
  }, [location]);

  // Redirect to dashboard if already authenticated
  useEffect(() => {
    if (isAuthenticated) {
      navigate('/dashboard');
    }
  }, [isAuthenticated, navigate]);

  // Handle Dexcom authentication
  const handleDexcomAuth = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const authUrl = await getDexcomLoginUrl();
      window.location.href = authUrl;
    } catch (error) {
      console.error('Failed to start Dexcom authentication:', error);
      setError('Failed to connect to Dexcom. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  // Handle personal token submission
  const handleSubmitPersonalToken = async (e) => {
    e.preventDefault();
    if (!personalToken.trim()) return;
    
    try {
      setLoading(true);
      setError(null);
      
      await setOuraPersonalToken(personalToken);
      navigate('/dashboard');
    } catch (error) {
      console.error('Failed to set personal token:', error);
      setError('Failed to set Oura personal token. Please check the token and try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles.authPage}>
      <div className={styles.leftPanel}>
        <div className={styles.logo}>Pulsum</div>
        <h1 className={styles.title}>Welcome to Pulsum</h1>
        <p className={styles.subtitle}>Your personal wellness dashboard</p>
        
        <ul className={styles.features}>
          <li>📊 Real-time Health Data - Connect your Oura Ring and Dexcom to visualize your health trends</li>
          <li>🤖 AI-Powered Insights - Get personalized recommendations based on your unique health patterns</li>
          <li>📝 Daily Journal - Track your mood, sleep quality, and daily reflections</li>
        </ul>
      </div>
      
      <div className={styles.rightPanel}>
        <div className={styles.formContainer}>
          <h2>Connect Your Devices</h2>
          <p>To get started, enter your Oura Personal Access Token below. Dexcom integration is optional.</p>
          
          {error && <div className={styles.error}>{error}</div>}
          
          <form className={styles.authForm} onSubmit={handleSubmitPersonalToken}>
            <input
              type="text"
              value={personalToken}
              onChange={(e) => setPersonalToken(e.target.value)}
              placeholder="Enter your Oura Personal Access Token"
              required
            />
            <p className={styles.tokenHelp}>
              You can get your Personal Access Token from the <a href="https://cloud.ouraring.com/personal-access-tokens" target="_blank" rel="noopener noreferrer">Oura Developer Portal</a>.
            </p>
            <button type="submit" disabled={loading || !personalToken.trim()}>
              {loading ? 'Connecting...' : 'Connect with Personal Token'}
            </button>
          </form>
          
          <div className={styles.divider}>Optional</div>
          
          <button 
            className={`${styles.oauthButton} ${styles.dexcomButton}`}
            onClick={handleDexcomAuth}
            disabled={loading || dexcomStatus.isAuthenticated}
          >
            {dexcomStatus.isAuthenticated ? '✓ Connected to Dexcom' : 'Connect Dexcom (Optional)'}
          </button>
          
          <div className={styles.footer}>
            Your data stays local on your device. We never store your health data on our servers.
          </div>
        </div>
      </div>
    </div>
  );
};

export default AuthPage; 