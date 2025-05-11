import React from 'react';
import styles from './SummaryCard.module.css';
import { FaMoon, FaStopwatch, FaRunning, FaTachometerAlt } from 'react-icons/fa';

const SummaryCard = ({ dashboardSummary, loading }) => {
  // Calculate date for the displayed data
  const today = new Date();
  const formattedDate = today.toLocaleDateString('en-US', { 
    weekday: 'long', 
    month: 'long', 
    day: 'numeric' 
  });
  
  // Get values from dashboardSummary
  const journalEntry = dashboardSummary?.journalEntry || {};
  const wellnessScores = dashboardSummary?.wellnessScores || {};
  const ouraStats = dashboardSummary?.ouraStats || {};

  return (
    <div className={styles.summaryCard}>
      <div className={styles.header}>
        <h2 className={styles.title}>Daily Summary</h2>
        <div className={styles.date}>{formattedDate}</div>
      </div>

      {loading ? (
        <div className={styles.loading}>
          <div className={styles.loadingSpinner}></div>
          <p>Loading your data...</p>
        </div>
      ) : (
        <div className={styles.content}>
          {/* Wellness Score */}
          <div className={styles.score}>
            <div className={styles.scoreCircle}>
              <span className={styles.scoreValue}>{wellnessScores?.combined_score ? Math.round(wellnessScores.combined_score) : '--'}</span>
              <span className={styles.scoreLabel}>Wellness<br />Score</span>
            </div>
          </div>

          {/* Daily Metrics */}
          <div className={styles.metrics}>
            <div className={styles.metricItem}>
              <div className={styles.metricIcon}>
                <FaMoon />
              </div>
              <div className={styles.metricContent}>
                <div className={styles.metricLabel}>Sleep</div>
                <div className={styles.metricValue}>
                  {wellnessScores?.objective_score ? Math.round(wellnessScores.objective_score) : '--'}
                </div>
              </div>
            </div>

            <div className={styles.metricItem}>
              <div className={styles.metricIcon}>
                <FaStopwatch />
              </div>
              <div className={styles.metricContent}>
                <div className={styles.metricLabel}>Readiness</div>
                <div className={styles.metricValue}>
                  {ouraStats?.readiness_days ? ouraStats.readiness_days : '--'}
                </div>
              </div>
            </div>

            <div className={styles.metricItem}>
              <div className={styles.metricIcon}>
                <FaRunning />
              </div>
              <div className={styles.metricContent}>
                <div className={styles.metricLabel}>Activity</div>
                <div className={styles.metricValue}>
                  {ouraStats?.activity_days ? ouraStats.activity_days : '--'}
                </div>
              </div>
            </div>

            <div className={styles.metricItem}>
              <div className={styles.metricIcon}>
                <FaTachometerAlt />
              </div>
              <div className={styles.metricContent}>
                <div className={styles.metricLabel}>Mood</div>
                <div className={styles.metricValue}>
                  {journalEntry?.mood_rating || '--'}/5
                </div>
              </div>
            </div>
          </div>

          {/* Status */}
          <div className={styles.status}>
            {!ouraStats?.last_sync_date ? (
              <p>Connect your Oura Ring to see your health data.</p>
            ) : (
              <p>Have a great day!</p>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default SummaryCard; 