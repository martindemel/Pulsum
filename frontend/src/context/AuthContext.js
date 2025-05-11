import React, { createContext, useState, useContext, useCallback } from 'react';
import api from '../utils/api';

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);
  const [ouraStatus, setOuraStatus] = useState({
    isAuthenticated: false,
    needsRefresh: false
  });
  const [dexcomStatus, setDexcomStatus] = useState({
    isAuthenticated: false,
    needsRefresh: false,
    isEnabled: false
  });

  // Check authentication status
  const checkAuthStatus = useCallback(async () => {
    try {
      setLoading(true);
      
      // Check Oura auth status
      const ouraResponse = await api.get('/api/auth/oura/status');
      setOuraStatus(ouraResponse.data);
      
      // Check Dexcom auth status
      const dexcomResponse = await api.get('/api/auth/dexcom/status');
      setDexcomStatus(dexcomResponse.data);
      
      // User is authenticated if at least Oura is connected
      setIsAuthenticated(ouraResponse.data.isAuthenticated);
    } catch (error) {
      console.error('Auth status check failed:', error);
      setIsAuthenticated(false);
    } finally {
      setLoading(false);
    }
  }, []);

  // Get Dexcom login URL
  const getDexcomLoginUrl = async () => {
    try {
      const response = await api.get('/api/auth/dexcom/login');
      return response.data.authUrl;
    } catch (error) {
      console.error('Failed to get Dexcom login URL:', error);
      throw error;
    }
  };

  // Toggle Dexcom integration
  const toggleDexcomIntegration = async (enabled) => {
    try {
      const response = await api.post('/api/auth/dexcom/toggle', { enabled });
      setDexcomStatus(prev => ({
        ...prev,
        isEnabled: response.data.isEnabled
      }));
      return response.data;
    } catch (error) {
      console.error('Failed to toggle Dexcom integration:', error);
      throw error;
    }
  };

  // Set Oura personal token
  const setOuraPersonalToken = async (token) => {
    try {
      const response = await api.post('/api/auth/oura/personal-token', { token });
      // If successful, update auth state
      if (response.data.success) {
        setOuraStatus({
          isAuthenticated: true,
          needsRefresh: false
        });
        setIsAuthenticated(true);
      }
      return response.data;
    } catch (error) {
      console.error('Failed to set Oura personal token:', error);
      throw error;
    }
  };

  const value = {
    isAuthenticated,
    loading,
    ouraStatus,
    dexcomStatus,
    checkAuthStatus,
    getDexcomLoginUrl,
    toggleDexcomIntegration,
    setOuraPersonalToken
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}; 