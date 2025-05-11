import React, { useState } from 'react';
import { FaBolt, FaBrain, FaHeart, FaSync, FaMoon, FaStopwatch, FaRunning, FaTachometerAlt } from 'react-icons/fa';
import styles from './WellnessScoreCard.module.css';
import api from '../../utils/api';

const WellnessScoreCard = ({ wellnessScores, dashboardSummary, loading, refreshData }) => {
  const [recalculating, setRecalculating] = useState(false);
  
  // Get the most recent wellness score
  const latestScore = dashboardSummary?.wellnessScores || {};
  
  // Calculate date for the displayed data
  const today = new Date();
  const formattedDate = today.toLocaleDateString('en-US', { 
    weekday: 'long', 
    month: 'long', 
    day: 'numeric' 
  });
  
  // Format the scores for display
  const formatScore = (score) => {
    if (score === null || score === undefined) return '-';
    return Math.round(score);
  };
  
  // Determine score levels
  const getScoreLevel = (score) => {
    if (score === null || score === undefined) return '';
    if (score >= 80) return styles.excellent;
    if (score >= 60) return styles.good;
    if (score >= 40) return styles.fair;
    return styles.poor;
  };
  
  // Get label based on score
  const getScoreLabel = (score) => {
    if (score === null || score === undefined) return 'No data';
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  };
  
  // Check if wellness scores are missing
  const hasNoScores = (
    latestScore.objective_score === null && 
    latestScore.subjective_score === null && 
    latestScore.combined_score === null
  );
  
  // Get values from dashboardSummary for additional metrics
  const journalEntry = dashboardSummary?.journalEntry || {};
  const ouraStats = dashboardSummary?.ouraStats || {};
  
  // Recalculate wellness scores
  const handleRecalculate = async () => {
    try {
      setRecalculating(true);
      await api.post('/api/user/recalculate-wellness-scores');
      
      // Refresh dashboard data after recalculation
      if (refreshData) {
        await refreshData();
      }
    } catch (error) {
      console.error('Failed to recalculate wellness scores:', error);
      alert('Failed to recalculate wellness scores. Please try again later.');
    } finally {
      setRecalculating(false);
    }
  };
  
  return (
    <div className={styles.card}>
      {loading || recalculating ? (
        <div className={styles.loading}>
          <div className={styles.loadingSpinner}></div>
          <p>{recalculating ? 'Recalculating wellness scores...' : 'Loading wellness scores...'}</p>
        </div>
      ) : (
        <>
          <div className={styles.cardHeader}>
            <h2 className={styles.scoreTitle}>Wellness Score</h2>
            <div className={styles.date}>{formattedDate}</div>
          </div>
          
          <div className={styles.cardContent}>
            <div className={styles.overallScore}>
              {hasNoScores && (
                <button 
                  className={styles.recalculateButton} 
                  onClick={handleRecalculate}
                  title="Recalculate wellness scores"
                >
                  <FaSync /> Recalculate
                </button>
              )}
              <div className={styles.scoreCircle}>
                <div className={`${styles.scoreValue} ${getScoreLevel(latestScore.combined_score)}`}>
                  {formatScore(latestScore.combined_score)}
                </div>
                <div className={styles.scoreLabel}>
                  {getScoreLabel(latestScore.combined_score)}
                </div>
              </div>
            </div>
            
            <div className={styles.scoreDetails}>
              <div className={styles.detailItem}>
                <div className={styles.detailIcon}>
                  <FaHeart />
                </div>
                <div className={styles.detailContent}>
                  <h3>Physical</h3>
                  <div className={`${styles.detailScore} ${getScoreLevel(latestScore.objective_score)}`}>
                    {formatScore(latestScore.objective_score)}
                  </div>
                </div>
              </div>
              
              <div className={styles.detailItem}>
                <div className={styles.detailIcon}>
                  <FaBrain />
                </div>
                <div className={styles.detailContent}>
                  <h3>Mental</h3>
                  <div className={`${styles.detailScore} ${getScoreLevel(latestScore.subjective_score)}`}>
                    {formatScore(latestScore.subjective_score)}
                  </div>
                </div>
              </div>
              
              <div className={styles.detailItem}>
                <div className={styles.detailIcon}>
                  <FaMoon />
                </div>
                <div className={styles.detailContent}>
                  <h3>Sleep</h3>
                  <div className={styles.detailScore}>
                    {formatScore(latestScore.objective_score)}
                  </div>
                </div>
              </div>
              
              <div className={styles.detailItem}>
                <div className={styles.detailIcon}>
                  <FaRunning />
                </div>
                <div className={styles.detailContent}>
                  <h3>Activity</h3>
                  <div className={styles.detailScore}>
                    {ouraStats?.activity_days || '--'}
                  </div>
                </div>
              </div>
              
              <div className={styles.detailItem}>
                <div className={styles.detailIcon}>
                  <FaStopwatch />
                </div>
                <div className={styles.detailContent}>
                  <h3>Readiness</h3>
                  <div className={styles.detailScore}>
                    {ouraStats?.readiness_days || '--'}
                  </div>
                </div>
              </div>
              
              <div className={styles.detailItem}>
                <div className={styles.detailIcon}>
                  <FaTachometerAlt />
                </div>
                <div className={styles.detailContent}>
                  <h3>Mood</h3>
                  <div className={styles.detailScore}>
                    {journalEntry?.mood_rating || '--'}/5
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          {/* Status message */}
          {!ouraStats?.last_sync_date ? (
            <div className={styles.statusMessage}>Connect your Oura Ring to see your health data.</div>
          ) : (
            <div className={styles.statusMessage}>Have a great day!</div>
          )}
        </>
      )}
    </div>
  );
};

export default WellnessScoreCard; 