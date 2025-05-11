import React, { useEffect } from 'react';
import { useData } from '../../context/DataContext';
import { useAuth } from '../../context/AuthContext';
import WellnessScoreCard from '../../components/Dashboard/WellnessScoreCard';
import DataOverview from '../../components/Dashboard/DataOverview';
import JournalEntry from '../../components/Journal/JournalEntry';
import RecommendationsList from '../../components/Recommendations/RecommendationsList';
import ChatWidget from '../../components/Chat/ChatWidget';
import styles from './DashboardHome.module.css';

const DashboardHome = () => {
  const { dexcomStatus } = useAuth();
  const { 
    dashboardSummary, 
    loadingSummary,
    fetchDashboardSummary,
    ouraData,
    dexcomData,
    wellnessScores,
    recommendations,
    journalEntries,
    loadingOura,
    loadingDexcom,
    loadingWellnessScores,
    loadingRecommendations,
    loadingJournal,
    fetchTodayRecommendations,
    fetchJournalEntries,
    fetchWellnessScores
  } = useData();

  // Fetch dashboard summary on load
  useEffect(() => {
    fetchDashboardSummary();
  }, [fetchDashboardSummary]);

  // Get latest journal entry
  const latestJournalEntry = journalEntries?.[0] || null;
  
  // Function to refresh all data
  const refreshAllData = async () => {
    await Promise.all([
      fetchDashboardSummary(),
      fetchJournalEntries(),
      fetchWellnessScores(),
      fetchTodayRecommendations()
    ]);
  };

  return (
    <div className={styles.dashboard}>
      {/* Main title */}
      <h1 className={styles.heading}>Dashboard</h1>
      
      {/* Wellness Score Card */}
      <div className={styles.wellnessRow}>
        <WellnessScoreCard 
          wellnessScores={wellnessScores}
          dashboardSummary={dashboardSummary}
          loading={loadingWellnessScores || loadingSummary}
          refreshData={fetchDashboardSummary}
        />
      </div>
      
      {/* Three Column Layout */}
      <div className={styles.columnsContainer}>
        {/* Column 1: Data Overview / Charts */}
        <div className={styles.column}>
          <h2 className={styles.columnHeading}>Health Data</h2>
          <DataOverview 
            ouraData={ouraData}
            dexcomData={dexcomData}
            loadingOura={loadingOura}
            loadingDexcom={loadingDexcom}
            hasDexcom={dexcomStatus.isEnabled}
          />
        </div>
        
        {/* Column 2: Journaling & Chat */}
        <div className={styles.column}>
          <div className={styles.journalSection}>
            <h2 className={styles.columnHeading}>Daily Check-in</h2>
            <JournalEntry 
              initialEntry={latestJournalEntry}
              loading={loadingJournal}
              isCompact
            />
            <h2 className={styles.columnHeading}>AI Chat</h2>
            <ChatWidget isCompact />
          </div>
        </div>
        
        {/* Column 3: Recommendations */}
        <div className={styles.column}>
          <div className={styles.recommendationsSection}>
            <h2 className={styles.columnHeading}>Recommendations</h2>
            <RecommendationsList 
              recommendations={recommendations}
              loading={loadingRecommendations}
              refreshRecommendations={fetchTodayRecommendations}
              limit={5}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardHome; 