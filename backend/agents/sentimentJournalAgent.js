class SentimentJournalAgent {
  constructor(openai) {
    this.openai = openai;
  }
  
  // Analyze sentiment from user journal entries
  async analyzeSentiment(journalEntries) {
    try {
      // If there are no journal entries, return a default message
      if (!journalEntries || journalEntries.length === 0) {
        return "No journal entries available for sentiment analysis. Please add journal entries to receive personalized insights.";
      }
      
      // Sort entries by date (most recent first)
      const sortedEntries = [...journalEntries].sort((a, b) => new Date(b.date) - new Date(a.date));
      
      // Take the 10 most recent entries
      const recentEntries = sortedEntries.slice(0, 10);
      
      // Format entries for analysis
      const formattedEntries = recentEntries.map(entry => {
        return {
          date: entry.date,
          mood_rating: entry.mood_rating,
          sleep_rating: entry.sleep_rating,
          entry_text: entry.entry_text
        };
      });
      
      // Use OpenAI to analyze the sentiment
      const response = await this.openai.chat.completions.create({
        model: 'gpt-4-turbo-preview',
        messages: [
          {
            role: 'system',
            content: `You are a sentiment analysis and journaling expert. Analyze the following journal entries from a user and provide insights about their emotional state, stress levels, recurring themes, and potential underlying issues.

The journal entries include subjective ratings (1-5 scale) for mood and sleep, as well as free text entries.

Your analysis should:
1. Identify the general emotional tone (positive, negative, mixed, neutral)
2. Note any recurring themes or patterns
3. Detect any potential signs of stress, anxiety, or other mental health concerns
4. Highlight strengths or positive coping mechanisms
5. Provide a concise summary of what the entries reveal about the user's current state

Return a concise paragraph (3-5 sentences) summarizing your analysis. Focus on being accurate and insightful rather than unnecessarily positive.`
          },
          {
            role: 'user',
            content: JSON.stringify(formattedEntries)
          }
        ],
        temperature: 0.4,
        max_tokens: 300
      });
      
      // Return the analysis
      return response.choices[0].message.content;
    } catch (error) {
      console.error('Sentiment analysis error:', error);
      return "Unable to analyze journal entries at this time. Please try again later.";
    }
  }
  
  // Create a new journal entry
  async createJournalEntry(userId, date, moodRating, sleepRating, entryText) {
    try {
      const { getDb } = require('../utils/db');
      const db = await getDb();
      
      // Insert or update the journal entry
      await db.run(
        `INSERT INTO journal_entries (user_id, date, mood_rating, sleep_rating, entry_text, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
         ON CONFLICT(user_id, date) 
         DO UPDATE SET mood_rating = excluded.mood_rating,
                       sleep_rating = excluded.sleep_rating,
                       entry_text = excluded.entry_text,
                       updated_at = CURRENT_TIMESTAMP`,
        [userId, date, moodRating, sleepRating, entryText]
      );
      
      // After saving the journal entry, recalculate wellness scores
      const { calculateWellnessScores } = require('../services/wellnessScoreService');
      await calculateWellnessScores(userId);
      
      return { success: true };
    } catch (error) {
      console.error('Failed to create journal entry:', error);
      throw error;
    }
  }
  
  // Get journal entries for a date range
  async getJournalEntries(userId, startDate, endDate) {
    try {
      const { getDb } = require('../utils/db');
      const db = await getDb();
      
      const entries = await db.all(
        `SELECT date, mood_rating, sleep_rating, entry_text, created_at, updated_at
         FROM journal_entries
         WHERE user_id = ? AND date BETWEEN ? AND ?
         ORDER BY date DESC`,
        [userId, startDate, endDate]
      );
      
      return entries;
    } catch (error) {
      console.error('Failed to get journal entries:', error);
      throw error;
    }
  }
  
  // Get the most recent journal entry
  async getMostRecentEntry(userId) {
    try {
      const { getDb } = require('../utils/db');
      const db = await getDb();
      
      const entry = await db.get(
        `SELECT date, mood_rating, sleep_rating, entry_text, created_at, updated_at
         FROM journal_entries
         WHERE user_id = ?
         ORDER BY date DESC
         LIMIT 1`,
        [userId]
      );
      
      return entry || null;
    } catch (error) {
      console.error('Failed to get most recent journal entry:', error);
      throw error;
    }
  }
}

module.exports = { SentimentJournalAgent }; 