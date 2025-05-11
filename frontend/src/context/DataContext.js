import React, { createContext, useState, useContext, useCallback, useEffect } from 'react';
import { useAuth } from './AuthContext';
import api from '../utils/api';

const DataContext = createContext();

export const useData = () => useContext(DataContext);

export const DataProvider = ({ children }) => {
  const { isAuthenticated, dexcomStatus } = useAuth();
  
  // Oura data
  const [ouraData, setOuraData] = useState({
    sleep: [],
    readiness: [],
    activity: [],
    daily: []
  });
  
  // Dexcom data
  const [dexcomData, setDexcomData] = useState({
    dailyStats: [],
    allReadings: []
  });
  
  // Journal entries
  const [journalEntries, setJournalEntries] = useState([]);
  
  // Recommendations
  const [recommendations, setRecommendations] = useState([]);
  
  // Wellness scores
  const [wellnessScores, setWellnessScores] = useState([]);
  
  // Chat history
  const [chatHistory, setChatHistory] = useState([]);
  
  // Dashboard summary
  const [dashboardSummary, setDashboardSummary] = useState(null);
  
  // Loading states
  const [loadingOura, setLoadingOura] = useState(false);
  const [loadingDexcom, setLoadingDexcom] = useState(false);
  const [loadingJournal, setLoadingJournal] = useState(false);
  const [loadingRecommendations, setLoadingRecommendations] = useState(false);
  const [loadingWellnessScores, setLoadingWellnessScores] = useState(false);
  const [loadingChat, setLoadingChat] = useState(false);
  const [loadingSummary, setLoadingSummary] = useState(false);
  
  // Date range for data fetching (last 30 days by default)
  const getDefaultDateRange = () => {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 30);
    
    return {
      startDate: startDate.toISOString().split('T')[0],
      endDate: endDate.toISOString().split('T')[0]
    };
  };
  
  // Fetch Oura data
  const fetchOuraData = useCallback(async (dateRange = getDefaultDateRange()) => {
    if (!isAuthenticated) return;
    
    try {
      setLoadingOura(true);
      const data = await api.cachedGet('/api/oura/data', {
        params: { range: JSON.stringify(dateRange) },
        maxAge: 5 * 60 * 1000, // Cache for 5 minutes
      });
      setOuraData(data);
    } catch (error) {
      console.error('Failed to fetch Oura data:', error);
    } finally {
      setLoadingOura(false);
    }
  }, [isAuthenticated]);
  
  // Fetch Dexcom data
  const fetchDexcomData = useCallback(async (dateRange = getDefaultDateRange()) => {
    if (!isAuthenticated || !dexcomStatus.isEnabled) return;
    
    try {
      setLoadingDexcom(true);
      const data = await api.cachedGet('/api/dexcom/data', {
        params: { range: JSON.stringify(dateRange) },
        maxAge: 5 * 60 * 1000, // Cache for 5 minutes
      });
      setDexcomData(data);
    } catch (error) {
      console.error('Failed to fetch Dexcom data:', error);
    } finally {
      setLoadingDexcom(false);
    }
  }, [isAuthenticated, dexcomStatus.isEnabled]);
  
  // Fetch journal entries
  const fetchJournalEntries = useCallback(async (dateRange = getDefaultDateRange()) => {
    if (!isAuthenticated) return;
    
    try {
      setLoadingJournal(true);
      const data = await api.cachedGet('/api/journal/entries', {
        params: { range: JSON.stringify(dateRange) },
        maxAge: 5 * 60 * 1000, // Cache for 5 minutes
      });
      setJournalEntries(data);
    } catch (error) {
      console.error('Failed to fetch journal entries:', error);
    } finally {
      setLoadingJournal(false);
    }
  }, [isAuthenticated]);
  
  // Create journal entry
  const createJournalEntry = async (date, moodRating, sleepRating, entryText) => {
    try {
      const response = await api.post('/api/journal/entry', {
        date,
        moodRating,
        sleepRating,
        entryText
      });
      
      // Refresh journal entries and wellness scores
      await fetchJournalEntries();
      await fetchWellnessScores();
      await fetchDashboardSummary();
      
      return response.data;
    } catch (error) {
      console.error('Failed to create journal entry:', error);
      throw error;
    }
  };
  
  // Fetch recommendations
  const fetchRecommendations = useCallback(async (dateRange = getDefaultDateRange()) => {
    if (!isAuthenticated) return;
    
    try {
      setLoadingRecommendations(true);
      const data = await api.cachedGet('/api/recommendations/list', {
        params: { range: JSON.stringify(dateRange) },
        maxAge: 15 * 60 * 1000, // Cache for 15 minutes
      });
      setRecommendations(data);
    } catch (error) {
      console.error('Failed to fetch recommendations:', error);
    } finally {
      setLoadingRecommendations(false);
    }
  }, [isAuthenticated]);
  
  // Fetch today's recommendations
  const fetchTodayRecommendations = useCallback(async () => {
    if (!isAuthenticated) return;
    
    try {
      setLoadingRecommendations(true);
      const data = await api.cachedGet('/api/recommendations/today', {
        maxAge: 15 * 60 * 1000, // Cache for 15 minutes
      });
      setRecommendations(data);
    } catch (error) {
      console.error('Failed to fetch today\'s recommendations:', error);
    } finally {
      setLoadingRecommendations(false);
    }
  }, [isAuthenticated]);
  
  // Generate new recommendations
  const generateRecommendations = async () => {
    try {
      const response = await api.post('/api/recommendations/generate');
      await fetchTodayRecommendations();
      return response.data;
    } catch (error) {
      console.error('Failed to generate recommendations:', error);
      throw error;
    }
  };
  
  // Update recommendation feedback
  const updateRecommendationFeedback = async (recommendationId, isLiked, isCompleted) => {
    try {
      const response = await api.post(`/api/recommendations/feedback/${recommendationId}`, {
        isLiked,
        isCompleted
      });
      
      // Clear the recommendations cache
      api.clearCache('/api/recommendations');
      
      // Refresh recommendations
      await fetchTodayRecommendations();
      
      return response.data;
    } catch (error) {
      console.error('Failed to update recommendation feedback:', error);
      throw error;
    }
  };
  
  // Fetch wellness scores
  const fetchWellnessScores = useCallback(async (dateRange = getDefaultDateRange()) => {
    if (!isAuthenticated) return;
    
    try {
      setLoadingWellnessScores(true);
      const data = await api.cachedGet('/api/user/wellness-scores', {
        params: { range: JSON.stringify(dateRange) },
        maxAge: 30 * 60 * 1000, // Cache for 30 minutes
      });
      setWellnessScores(data);
    } catch (error) {
      console.error('Failed to fetch wellness scores:', error);
    } finally {
      setLoadingWellnessScores(false);
    }
  }, [isAuthenticated]);
  
  // Fetch chat history
  const fetchChatHistory = useCallback(async () => {
    if (!isAuthenticated) return;
    
    try {
      console.log('DataContext: Fetching chat history');
      setLoadingChat(true);
      const data = await api.cachedGet('/api/chat/history', {
        maxAge: 60 * 1000, // Cache for 1 minute
      });
      console.log('DataContext: Chat history received:', data);
      setChatHistory(data);
    } catch (error) {
      console.error('Failed to fetch chat history:', error);
    } finally {
      setLoadingChat(false);
    }
  }, [isAuthenticated]);
  
  // Send chat message
  const sendChatMessage = async (message) => {
    try {
      console.log('DataContext: Sending chat message:', message);
      const response = await api.post('/api/chat/message', { message });
      console.log('DataContext: Response received:', response);
      
      // Refresh chat history
      await fetchChatHistory();
      
      return response.data;
    } catch (error) {
      console.error('Failed to send chat message:', error);
      throw error;
    }
  };
  
  // Clear chat history
  const clearChatHistory = async () => {
    try {
      const response = await api.delete('/api/chat/history');
      setChatHistory([]);
      return response.data;
    } catch (error) {
      console.error('Failed to clear chat history:', error);
      throw error;
    }
  };
  
  // Fetch dashboard summary
  const fetchDashboardSummary = useCallback(async () => {
    if (!isAuthenticated) return;
    
    try {
      setLoadingSummary(true);
      const data = await api.cachedGet('/api/user/dashboard-summary', {
        maxAge: 15 * 60 * 1000, // Cache for 15 minutes
      });
      setDashboardSummary(data);
    } catch (error) {
      console.error('Failed to fetch dashboard summary:', error);
    } finally {
      setLoadingSummary(false);
    }
  }, [isAuthenticated]);
  
  // Sync data on demand
  const syncData = async () => {
    try {
      // Sync Oura data
      await api.post('/api/oura/sync');
      
      // Sync Dexcom data if enabled
      if (dexcomStatus.isEnabled) {
        await api.post('/api/dexcom/sync');
      }
      
      // Clear relevant caches
      api.clearCache('/api/oura');
      api.clearCache('/api/user');
      if (dexcomStatus.isEnabled) {
        api.clearCache('/api/dexcom');
      }
      
      // Refresh all data
      await fetchOuraData();
      if (dexcomStatus.isEnabled) {
        await fetchDexcomData();
      }
      await fetchWellnessScores();
      await fetchDashboardSummary();
      
      return { success: true };
    } catch (error) {
      console.error('Failed to sync data:', error);
      throw error;
    }
  };
  
  // Fetch all data when authenticated
  useEffect(() => {
    if (isAuthenticated) {
      fetchOuraData();
      fetchJournalEntries();
      fetchTodayRecommendations();
      fetchWellnessScores();
      fetchChatHistory();
      fetchDashboardSummary();
      
      if (dexcomStatus.isEnabled) {
        fetchDexcomData();
      }
    }
  }, [isAuthenticated, dexcomStatus.isEnabled, fetchOuraData, fetchDexcomData, 
      fetchJournalEntries, fetchTodayRecommendations, fetchWellnessScores, 
      fetchChatHistory, fetchDashboardSummary]);
  
  const value = {
    // Data
    ouraData,
    dexcomData,
    journalEntries,
    recommendations,
    wellnessScores,
    chatHistory,
    dashboardSummary,
    
    // Loading states
    loadingOura,
    loadingDexcom,
    loadingJournal,
    loadingRecommendations,
    loadingWellnessScores,
    loadingChat,
    loadingSummary,
    
    // Functions
    fetchOuraData,
    fetchDexcomData,
    fetchJournalEntries,
    createJournalEntry,
    fetchRecommendations,
    fetchTodayRecommendations,
    generateRecommendations,
    updateRecommendationFeedback,
    fetchWellnessScores,
    fetchChatHistory,
    sendChatMessage,
    clearChatHistory,
    fetchDashboardSummary,
    syncData,
    getDefaultDateRange
  };
  
  return <DataContext.Provider value={value}>{children}</DataContext.Provider>;
}; 