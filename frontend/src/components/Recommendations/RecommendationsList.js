import React, { useState } from 'react';
import { FaCheck, FaThumbsUp, FaThumbsDown, FaClock, FaTag } from 'react-icons/fa';
import { useData } from '../../context/DataContext';
import styles from './RecommendationsList.module.css';
import { motion, AnimatePresence } from 'framer-motion';

const RecommendationsList = ({ recommendations, loading, refreshRecommendations, limit }) => {
  const { updateRecommendationFeedback } = useData();
  const [feedbackState, setFeedbackState] = useState({});
  const [toast, setToast] = useState({ visible: false, message: '', type: '' });

  // Limit the number of recommendations to display
  const limitedRecommendations = limit && recommendations ? 
    recommendations.slice(0, limit) : recommendations;

  // Show toast notification
  const showToast = (message, type = 'success') => {
    setToast({ visible: true, message, type });
    setTimeout(() => {
      setToast({ visible: false, message: '', type: '' });
    }, 3000);
  };

  // Handle user feedback (like/dislike) with optimistic UI updates
  const handleFeedback = async (id, isLiked) => {
    try {
      // Track the current processing state to prevent double-clicks
      if (feedbackState[id]?.processing) return;
      
      // Optimistic UI update
      setFeedbackState(prev => ({
        ...prev,
        [id]: { processing: true, isLiked }
      }));
      
      // Send the feedback to the server
      await updateRecommendationFeedback(id, isLiked);
      
      // Success notification
      showToast(isLiked ? 'Recommendation liked!' : 'Feedback recorded, we\'ll show fewer like this');
      
      // Clear the processing state
      setFeedbackState(prev => ({
        ...prev,
        [id]: { processing: false, isLiked }
      }));
    } catch (error) {
      console.error('Failed to update feedback:', error);
      
      // Error notification
      showToast('Failed to save feedback. Please try again.', 'error');
      
      // Reset the processing state
      setFeedbackState(prev => ({
        ...prev,
        [id]: { processing: false }
      }));
    }
  };

  // Handle marking a recommendation as completed with optimistic UI updates
  const handleComplete = async (id, isCompleted) => {
    try {
      // Track the current processing state to prevent double-clicks
      if (feedbackState[id]?.processing) return;
      
      // Optimistic UI update
      setFeedbackState(prev => ({
        ...prev,
        [id]: { processing: true, isCompleted: !isCompleted }
      }));
      
      // Send the update to the server
      await updateRecommendationFeedback(id, undefined, !isCompleted);
      
      // Success notification
      showToast(!isCompleted ? 'Marked as completed. Great job!' : 'Marked as not completed');
      
      // Clear the processing state
      setFeedbackState(prev => ({
        ...prev,
        [id]: { processing: false, isCompleted: !isCompleted }
      }));
    } catch (error) {
      console.error('Failed to update completion status:', error);
      
      // Error notification
      showToast('Failed to update status. Please try again.', 'error');
      
      // Reset the processing state
      setFeedbackState(prev => ({
        ...prev,
        [id]: { processing: false }
      }));
    }
  };

  return (
    <div className={styles.recommendationsList}>
      <AnimatePresence>
        {toast.visible && (
          <motion.div 
            className={`${styles.toast} ${styles[toast.type]}`}
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
          >
            {toast.message}
          </motion.div>
        )}
      </AnimatePresence>

      {loading ? (
        <div className={styles.loading}>
          <div className={styles.loadingSpinner}></div>
          <p>Loading recommendations...</p>
        </div>
      ) : !limitedRecommendations || limitedRecommendations.length === 0 ? (
        <div className={styles.empty}>
          <p>No recommendations available.</p>
          <button 
            className={styles.refreshButton}
            onClick={refreshRecommendations}
          >
            Generate Recommendations
          </button>
        </div>
      ) : (
        <>
          <div className={styles.list}>
            <AnimatePresence>
              {limitedRecommendations.map((recommendation, index) => {
                const isProcessing = feedbackState[recommendation.id]?.processing;
                const displayIsCompleted = feedbackState[recommendation.id]?.isCompleted !== undefined 
                  ? feedbackState[recommendation.id]?.isCompleted 
                  : recommendation.is_completed;
                
                return (
                  <motion.div 
                    key={recommendation.id} 
                    className={`${styles.item} ${displayIsCompleted ? styles.completed : ''}`}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -20 }}
                    transition={{ duration: 0.3, delay: index * 0.1 }}
                    whileHover={{ y: -5, boxShadow: '0 10px 20px rgba(0,0,0,0.1)' }}
                  >
                    <div className={styles.content}>
                      <h3 className={styles.title}>
                        {recommendation.recommendation_text || recommendation.text}
                      </h3>
                      
                      <div className={styles.metadata}>
                        {recommendation.category && (
                          <div className={styles.category}>
                            <FaTag className={styles.metaIcon} />
                            {recommendation.category} {recommendation.subcategory ? `• ${recommendation.subcategory}` : ''}
                          </div>
                        )}
                        
                        {recommendation.time_to_complete && (
                          <div className={styles.timeToComplete}>
                            <FaClock className={styles.metaIcon} />
                            {recommendation.time_to_complete}
                          </div>
                        )}
                      </div>
                      
                      {recommendation.microaction && (
                        <div className={styles.microaction}>
                          <strong>Try this:</strong> {recommendation.microaction}
                        </div>
                      )}
                    </div>
                    
                    <div className={styles.actions}>
                      <button 
                        className={`${styles.actionButton} ${displayIsCompleted ? styles.active : ''} ${isProcessing ? styles.processing : ''}`}
                        onClick={() => handleComplete(recommendation.id, recommendation.is_completed)}
                        title={displayIsCompleted ? "Mark as incomplete" : "Mark as completed"}
                        disabled={isProcessing}
                      >
                        <FaCheck />
                        <span className={styles.btnText}>Complete</span>
                      </button>
                      
                      <div className={styles.feedbackButtons}>
                        <button 
                          className={`${styles.actionButton} ${recommendation.is_liked === true ? styles.liked : ''} ${isProcessing ? styles.processing : ''}`}
                          onClick={() => handleFeedback(recommendation.id, true)}
                          title="Like this recommendation"
                          disabled={isProcessing}
                        >
                          <FaThumbsUp />
                        </button>
                        
                        <button 
                          className={`${styles.actionButton} ${recommendation.is_liked === false ? styles.disliked : ''} ${isProcessing ? styles.processing : ''}`}
                          onClick={() => handleFeedback(recommendation.id, false)}
                          title="Dislike this recommendation"
                          disabled={isProcessing}
                        >
                          <FaThumbsDown />
                        </button>
                      </div>
                    </div>
                  </motion.div>
                );
              })}
            </AnimatePresence>
          </div>
          
          {limit && recommendations && recommendations.length > limit && (
            <motion.div 
              className={styles.viewMore}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <a href="/dashboard/recommendations">View all recommendations</a>
            </motion.div>
          )}
        </>
      )}
    </div>
  );
};

export default RecommendationsList; 