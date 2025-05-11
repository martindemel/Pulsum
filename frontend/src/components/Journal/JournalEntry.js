import React, { useState, useEffect } from 'react';
import { useData } from '../../context/DataContext';
import { FaSmile, FaFrown, FaMeh, FaBed, FaSave } from 'react-icons/fa';
import styles from './JournalEntry.module.css';

const JournalEntry = ({ initialEntry, loading, isCompact = false }) => {
  const { createJournalEntry } = useData();
  
  // Today's date in YYYY-MM-DD format
  const today = new Date().toISOString().split('T')[0];
  
  // State for the journal entry
  const [entry, setEntry] = useState({
    date: today,
    moodRating: 3,
    sleepRating: 3,
    entryText: ''
  });
  
  // State for saving status
  const [saving, setSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [saveError, setSaveError] = useState(false);
  
  // Initialize with the initial entry if provided
  useEffect(() => {
    if (initialEntry) {
      setEntry({
        date: initialEntry.date || today,
        moodRating: initialEntry.mood_rating || 3,
        sleepRating: initialEntry.sleep_rating || 3,
        entryText: initialEntry.entry_text || ''
      });
    }
  }, [initialEntry, today]);
  
  // Handle input changes
  const handleChange = (e) => {
    const { name, value } = e.target;
    setEntry(prev => ({ ...prev, [name]: value }));
  };
  
  // Handle rating changes
  const handleRatingChange = (type, value) => {
    setEntry(prev => ({ ...prev, [type]: value }));
  };
  
  // Handle form submission
  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
      setSaving(true);
      setSaveSuccess(false);
      setSaveError(false);
      
      await createJournalEntry(
        entry.date,
        entry.moodRating,
        entry.sleepRating,
        entry.entryText
      );
      
      setSaveSuccess(true);
      
      // Force reload the window to ensure dashboard updates
      if (isCompact) {
        window.location.reload();
      }
      
      // Reset success message after 3 seconds
      setTimeout(() => {
        setSaveSuccess(false);
      }, 3000);
    } catch (error) {
      console.error('Failed to save journal entry:', error);
      setSaveError(true);
      
      // Reset error message after 3 seconds
      setTimeout(() => {
        setSaveError(false);
      }, 3000);
    } finally {
      setSaving(false);
    }
  };
  
  // Get label for mood rating
  const getMoodLabel = (rating) => {
    switch (rating) {
      case 1: return 'Very Poor';
      case 2: return 'Poor';
      case 3: return 'Neutral';
      case 4: return 'Good';
      case 5: return 'Excellent';
      default: return 'Neutral';
    }
  };
  
  // Get label for sleep rating
  const getSleepLabel = (rating) => {
    switch (rating) {
      case 1: return 'Very Poor';
      case 2: return 'Poor';
      case 3: return 'Fair';
      case 4: return 'Good';
      case 5: return 'Excellent';
      default: return 'Fair';
    }
  };
  
  // Render mood rating buttons
  const renderMoodRating = () => {
    return (
      <div className={styles.ratingGroup}>
        <span className={styles.ratingLabel}>How do you feel today?</span>
        <div className={styles.ratingButtons}>
          {[1, 2, 3, 4, 5].map(rating => (
            <button
              key={`mood-${rating}`}
              type="button"
              className={`${styles.ratingButton} ${entry.moodRating === rating ? styles.active : ''}`}
              onClick={() => handleRatingChange('moodRating', rating)}
              aria-label={`Mood: ${getMoodLabel(rating)}`}
              title={getMoodLabel(rating)}
            >
              {rating === 1 && <FaFrown />}
              {rating === 2 && <FaMeh style={{ transform: 'rotate(180deg)' }} />}
              {rating === 3 && <FaMeh />}
              {rating === 4 && <FaSmile />}
              {rating === 5 && <FaSmile style={{ transform: 'scale(1.2)' }} />}
            </button>
          ))}
        </div>
        <span className={styles.selectedRating}>{getMoodLabel(entry.moodRating)}</span>
      </div>
    );
  };
  
  // Render sleep rating buttons
  const renderSleepRating = () => {
    return (
      <div className={styles.ratingGroup}>
        <span className={styles.ratingLabel}>How well did you sleep?</span>
        <div className={styles.ratingButtons}>
          {[1, 2, 3, 4, 5].map(rating => (
            <button
              key={`sleep-${rating}`}
              type="button"
              className={`${styles.ratingButton} ${entry.sleepRating === rating ? styles.active : ''}`}
              onClick={() => handleRatingChange('sleepRating', rating)}
              aria-label={`Sleep: ${getSleepLabel(rating)}`}
              title={getSleepLabel(rating)}
            >
              {rating === 1 && <FaBed style={{ transform: 'rotate(180deg)' }} />}
              {rating === 2 && <FaBed />}
              {rating === 3 && <FaBed style={{ transform: 'rotate(30deg)' }} />}
              {rating === 4 && <FaBed style={{ transform: 'rotate(60deg)' }} />}
              {rating === 5 && <FaBed style={{ transform: 'rotate(90deg)' }} />}
            </button>
          ))}
        </div>
        <span className={styles.selectedRating}>{getSleepLabel(entry.sleepRating)}</span>
      </div>
    );
  };
  
  return (
    <div className={`${styles.journalEntry} ${isCompact ? styles.compact : ''}`}>
      {loading ? (
        <div className={styles.loading}>
          <div className={styles.loadingSpinner}></div>
          <p>Loading journal entry...</p>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className={styles.form}>
          {!isCompact && (
            <div className={styles.dateField}>
              <label htmlFor="date">Date</label>
              <input
                type="date"
                id="date"
                name="date"
                value={entry.date}
                onChange={handleChange}
                max={today}
              />
            </div>
          )}
          
          {renderMoodRating()}
          {renderSleepRating()}
          
          <div className={styles.textField}>
            <label htmlFor="entryText">Journal Entry</label>
            <textarea
              id="entryText"
              name="entryText"
              value={entry.entryText}
              onChange={handleChange}
              placeholder="How was your day? Any notable events or feelings to document?"
              rows={isCompact ? 3 : 5}
            ></textarea>
          </div>
          
          <button 
            type="submit" 
            className={styles.saveButton}
            disabled={saving}
          >
            {saving ? (
              <>
                <div className={styles.savingSpinner}></div>
                Saving...
              </>
            ) : (
              <>
                <FaSave />
                Save Entry
              </>
            )}
          </button>
          
          {saveSuccess && (
            <div className={styles.successMessage}>
              Journal entry saved successfully!
            </div>
          )}
          
          {saveError && (
            <div className={styles.errorMessage}>
              Failed to save journal entry. Please try again.
            </div>
          )}
        </form>
      )}
    </div>
  );
};

export default JournalEntry; 