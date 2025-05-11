const OpenAI = require('openai');
const { getDb } = require('../utils/db');
const { PatternDetectionAgent } = require('./patternDetectionAgent');
const { SentimentJournalAgent } = require('./sentimentJournalAgent');
const { RecommendationAgent } = require('./recommendationAgent');
const { PersonalizationAgent } = require('./personalizationAgent');
const { SafetyAgent } = require('./safetyAgent');

class ManagerAgent {
  constructor() {
    try {
      console.log('Initializing OpenAI client in ManagerAgent');
      console.log('API Key available:', !!process.env.OPENAI_API_KEY);
      console.log('API Key prefix:', process.env.OPENAI_API_KEY ? process.env.OPENAI_API_KEY.substring(0, 10) + '...' : 'N/A');
      
      this.openai = new OpenAI({
        apiKey: process.env.OPENAI_API_KEY
      });
      
      console.log('OpenAI client initialized in ManagerAgent');
    } catch (error) {
      console.error('Failed to initialize OpenAI in ManagerAgent:', error);
      this.openai = null;
    }
    
    // Initialize sub-agents
    this.patternDetection = new PatternDetectionAgent(this.openai);
    this.sentimentJournal = new SentimentJournalAgent(this.openai);
    this.recommendation = new RecommendationAgent(this.openai);
    this.personalization = new PersonalizationAgent(this.openai);
    this.safety = new SafetyAgent(this.openai);
    
    // Default responses when AI is unavailable
    this.defaultPatterns = [
      "Your recent sleep patterns indicate moderate consistency",
      "Physical activity levels appear to be within normal ranges",
      "Your wellness data suggests regular daily routines"
    ];
    
    this.defaultSentiment = "Your journal entries suggest a neutral to positive outlook. Continue monitoring your emotions and engaging in self-reflection.";
  }
  
  // Check if OpenAI API is available
  get isAIAvailable() {
    return !!this.openai;
  }
  
  // Process a user chat message and generate a response
  async processChat(userId, userMessage) {
    try {
      // First, check for safety concerns
      let safetyCheck;
      try {
        safetyCheck = await this.safety.checkMessage(userMessage);
      } catch (safetyError) {
        console.error('Safety check failed:', safetyError);
        // Default to safe if safety check fails
        safetyCheck = { isSafe: true, response: null };
      }
      
      if (!safetyCheck.isSafe) {
        // If message is unsafe, return the safety response
        await this.storeChatMessage(userId, 'user', userMessage);
        await this.storeChatMessage(userId, 'assistant', safetyCheck.response);
        return { response: safetyCheck.response, isSafe: false };
      }
      
      // Get user health data
      const userData = await this.getUserData(userId);
      
      // Variables to store analysis results
      let patterns = this.defaultPatterns;
      let sentimentAnalysis = this.defaultSentiment;
      let personalizedRecommendations = [];
      
      // If we have AI available, use it for analysis
      if (this.isAIAvailable) {
        try {
          // Run pattern detection on health data
          patterns = await this.patternDetection.detectPatterns(userData);
        } catch (patternError) {
          console.error('Pattern detection failed:', patternError);
          // Continue with default patterns
        }
        
        try {
          // Analyze journal entries and sentiment
          sentimentAnalysis = await this.sentimentJournal.analyzeSentiment(userData.journalEntries);
        } catch (sentimentError) {
          console.error('Sentiment analysis failed:', sentimentError);
          // Continue with default sentiment
        }
        
        try {
          // Get personalized recommendations based on patterns and sentiment
          const recommendations = await this.recommendation.generateRecommendations(patterns, sentimentAnalysis, userData);
          
          // Personalize the recommendations further
          personalizedRecommendations = await this.personalization.personalizeRecommendations(
            recommendations, 
            userData.recommendationFeedback
          );
        } catch (recError) {
          console.error('Recommendation generation failed:', recError);
          // Will use static recommendations from recommendation agent
          personalizedRecommendations = await this.recommendation.getFallbackRecommendations();
        }
      } else {
        // Use static recommendations if AI is unavailable
        personalizedRecommendations = await this.recommendation.getFallbackRecommendations();
      }
      
      let assistantResponse;
      
      // Try to generate response with AI, fall back to template if unavailable
      if (this.isAIAvailable) {
        try {
          const response = await this.openai.chat.completions.create({
            model: 'gpt-4-turbo-preview',
            messages: [
              {
                role: 'system',
                content: `You are the Pulsum wellness assistant. You have access to the user's health data from Oura${userData.useDexcom ? ' and Dexcom' : ''}.
                
                Based on the user's health data, we've detected the following patterns:
                ${patterns.join('\n')}
                
                Based on the user's journal entries, we've identified the following sentiment:
                ${sentimentAnalysis}
                
                We recommend the following actions:
                ${personalizedRecommendations.map(r => r.text).join('\n')}
                
                Respond to the user in a helpful, empathetic way. You can acknowledge their health patterns and offer advice,
                but do not explicitly mention the internal agent analysis. Just provide natural, conversational responses that incorporate
                the insights. When recommending actions, make them sound like your own suggestions, not something from a database.
                
                Keep responses concise and friendly. If the user asks about specific health metrics, you can provide that information
                based on the data you have. If they ask something you don't have data for, acknowledge that and suggest how they might
                track that information.`
              },
              {
                role: 'user',
                content: userMessage
              }
            ],
            temperature: 0.7,
            max_tokens: 500
          });

          assistantResponse = response.choices[0].message.content;
        } catch (aiError) {
          console.error('Failed to generate AI response:', aiError);
          // Fall back to template response
          assistantResponse = this.generateTemplateResponse(userMessage, patterns, personalizedRecommendations);
        }
      } else {
        // Use template response if AI is unavailable
        assistantResponse = this.generateTemplateResponse(userMessage, patterns, personalizedRecommendations);
      }
      
      // Store the chat messages
      await this.storeChatMessage(userId, 'user', userMessage);
      await this.storeChatMessage(userId, 'assistant', assistantResponse);
      
      return { response: assistantResponse, isSafe: true };
    } catch (error) {
      console.error('Manager agent processing error:', error);
      const fallbackResponse = "I'm sorry, but I'm having trouble processing your request right now. Please try again in a moment.";
      
      try {
        // Try to store the messages anyway
        await this.storeChatMessage(userId, 'user', userMessage);
        await this.storeChatMessage(userId, 'assistant', fallbackResponse);
      } catch (storageError) {
        console.error('Failed to store chat messages:', storageError);
      }
      
      return { 
        response: fallbackResponse, 
        isSafe: true,
        error: error.message
      };
    }
  }
  
  // Generate a template response when AI is unavailable
  generateTemplateResponse(userMessage, patterns, recommendations) {
    const greeting = "Thanks for reaching out to Pulsum!";
    const messageLower = userMessage.toLowerCase();
    
    // Check for common queries
    if (messageLower.includes('sleep') || messageLower.includes('tired')) {
      return `${greeting} I notice you're asking about sleep. Based on your data, ${patterns[0]}. You might want to try: ${recommendations[0]?.text || 'setting a consistent sleep schedule'}.`;
    } else if (messageLower.includes('exercise') || messageLower.includes('active') || messageLower.includes('workout')) {
      return `${greeting} Regarding physical activity, ${patterns[1]}. Consider ${recommendations[1]?.text || 'adding short movement breaks throughout your day'}.`;
    } else if (messageLower.includes('stress') || messageLower.includes('anxious') || messageLower.includes('anxiety')) {
      return `${greeting} I understand managing stress is important. Try ${recommendations[2]?.text || 'practicing deep breathing for a few minutes when feeling overwhelmed'}.`;
    } else if (messageLower.includes('food') || messageLower.includes('nutrition') || messageLower.includes('diet')) {
      return `${greeting} For nutrition, I'd recommend ${recommendations[3]?.text || 'staying hydrated and focusing on whole foods'}.`;
    } else {
      return `${greeting} I'm here to help with your wellness journey. Based on your data, I'd recommend: ${recommendations[0]?.text || 'focusing on consistency in your daily routines'}. Let me know if you'd like more specific insights about sleep, activity, stress, or nutrition.`;
    }
  }
  
  // Generate daily recommendations for the user
  async generateDailyRecommendations(userId) {
    try {
      // Get user health data
      const userData = await this.getUserData(userId);
      
      // Run pattern detection on health data
      const patterns = await this.patternDetection.detectPatterns(userData);
      
      // Analyze journal entries and sentiment
      const sentimentAnalysis = await this.sentimentJournal.analyzeSentiment(userData.journalEntries);
      
      // Get personalized recommendations based on patterns and sentiment
      const recommendations = await this.recommendation.generateRecommendations(patterns, sentimentAnalysis, userData);
      
      // Personalize the recommendations further
      const personalizedRecommendations = await this.personalization.personalizeRecommendations(
        recommendations, 
        userData.recommendationFeedback
      );
      
      // Save recommendations to database
      await this.saveRecommendations(userId, personalizedRecommendations);
      
      return personalizedRecommendations;
    } catch (error) {
      console.error('Failed to generate daily recommendations:', error);
      throw error;
    }
  }
  
  // Get relevant user data for processing
  async getUserData(userId) {
    try {
      const db = await getDb();
      
      // Get user preferences - handle case where use_dexcom doesn't exist
      let useDexcom = false;
      try {
        // Check if the column exists
        const tableInfo = await db.all('PRAGMA table_info(users)');
        const columnExists = tableInfo.some(column => column.name === 'use_dexcom');
        
        if (columnExists) {
          const user = await db.get('SELECT use_dexcom FROM users WHERE id = ?', [userId]);
          useDexcom = !!user?.use_dexcom;
        }
      } catch (error) {
        console.error('Error checking for use_dexcom column:', error);
        // Default to false if there's an error
      }
      
      // Get Oura data for the last 30 days
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      const startDate = thirtyDaysAgo.toISOString().split('T')[0];
      const today = new Date().toISOString().split('T')[0];
      
      // Get Oura data
      const ouraData = await db.all(
        `SELECT date, data_type, data FROM oura_data 
         WHERE user_id = ? AND date BETWEEN ? AND ?`,
        [userId, startDate, today]
      );
      
      // Process Oura data by type
      const processedOuraData = {
        sleep: [],
        readiness: [],
        activity: [],
        daily: []
      };
      
      ouraData.forEach(item => {
        const data = JSON.parse(item.data);
        if (processedOuraData[item.data_type]) {
          processedOuraData[item.data_type].push({
            date: item.date,
            ...data
          });
        }
      });
      
      // Get Dexcom data if enabled
      let dexcomData = [];
      if (useDexcom) {
        dexcomData = await db.all(
          `SELECT date, reading_time, glucose_value, trend FROM dexcom_data 
           WHERE user_id = ? AND date BETWEEN ? AND ?`,
          [userId, startDate, today]
        );
      }
      
      // Get journal entries
      const journalEntries = await db.all(
        `SELECT date, mood_rating, sleep_rating, entry_text FROM journal_entries 
         WHERE user_id = ? AND date BETWEEN ? AND ?`,
        [userId, startDate, today]
      );
      
      // Get wellness scores
      const wellnessScores = await db.all(
        `SELECT date, objective_score, subjective_score, combined_score FROM wellness_scores 
         WHERE user_id = ? AND date BETWEEN ? AND ?`,
        [userId, startDate, today]
      );
      
      // Get past recommendations and user feedback
      const recommendationFeedback = await db.all(
        `SELECT id, date, recommendation_text, category, subcategory, is_completed, is_liked 
         FROM recommendations 
         WHERE user_id = ? AND date BETWEEN ? AND ?`,
        [userId, startDate, today]
      );
      
      return {
        oura: processedOuraData,
        dexcom: dexcomData,
        journalEntries,
        wellnessScores,
        recommendationFeedback,
        useDexcom
      };
    } catch (error) {
      console.error('Failed to get user data:', error);
      throw error;
    }
  }
  
  // Save generated recommendations to the database
  async saveRecommendations(userId, recommendations) {
    const db = await getDb();
    const today = new Date().toISOString().split('T')[0];
    
    try {
      for (const rec of recommendations) {
        // Extract recommendation details
        const {
          text, 
          category = null,
          subcategory = null,
          source = null,
          microaction = null,
          difficultyLevel = null,
          timeToComplete = null
        } = rec;
        
        await db.run(
          `INSERT INTO recommendations 
           (user_id, date, recommendation_text, category, subcategory, source, microaction, difficulty_level, time_to_complete, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)`,
          [userId, today, text, category, subcategory, source, microaction, difficultyLevel, timeToComplete]
        );
      }
    } catch (error) {
      console.error('Failed to save recommendations:', error);
      throw error;
    }
  }
  
  // Store chat messages in the database
  async storeChatMessage(userId, role, content) {
    const db = await getDb();
    
    try {
      await db.run(
        `INSERT INTO chat_history (user_id, role, content, timestamp)
         VALUES (?, ?, ?, CURRENT_TIMESTAMP)`,
        [userId, role, content]
      );
    } catch (error) {
      console.error('Failed to store chat message:', error);
      // Don't throw error to prevent interrupting the chat flow
    }
  }
}

module.exports = new ManagerAgent(); 