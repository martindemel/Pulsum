const fs = require('fs').promises;
const path = require('path');
const OpenAI = require('openai');

class RecommendationAgent {
  constructor(openai = null) {
    this.openai = openai;
    this.microactions = null;
    this.initOpenAI();
  }
  
  // Initialize OpenAI client if not provided
  initOpenAI() {
    if (!this.openai && process.env.OPENAI_API_KEY) {
      try {
        this.openai = new OpenAI({
          apiKey: process.env.OPENAI_API_KEY
        });
        console.log('OpenAI client initialized in RecommendationAgent');
      } catch (error) {
        console.error('Failed to initialize OpenAI in RecommendationAgent:', error);
      }
    }
  }
  
  // Generate recommendations based on patterns and sentiment
  async generateRecommendations(patterns, sentimentAnalysis, userData) {
    try {
      // Load microactions if not already loaded
      if (!this.microactions) {
        await this.loadMicroactions();
      }
      
      // If microactions loaded successfully, try to find matches
      if (this.microactions && this.microactions.length > 0) {
        // Find appropriate microactions based on patterns and sentiment
        const matchedRecommendations = await this.findMatchingMicroactions(patterns, sentimentAnalysis, userData);
        
        // If we found enough recommendations, return them
        if (matchedRecommendations.length >= 3) {
          return matchedRecommendations.slice(0, 5);
        }
        
        // If we have some but not enough, try to supplement with AI-generated ones
        if (matchedRecommendations.length > 0) {
          if (this.openai) {
            const aiRecommendations = await this.generateAIRecommendations(patterns, sentimentAnalysis, userData);
            
            // Add AI recommendations to fill in gaps (avoid duplicates)
            for (const aiRec of aiRecommendations) {
              if (matchedRecommendations.length >= 5) break;
              
              // Check if this recommendation is similar to any existing ones
              const isDuplicate = matchedRecommendations.some(rec => 
                this.areSimilarRecommendations(rec.text, aiRec.text)
              );
              
              if (!isDuplicate) {
                matchedRecommendations.push(aiRec);
              }
            }
            
            return matchedRecommendations.slice(0, 5);
          } else {
            // Add static fallback recommendations if OpenAI is not available
            const fallbackRecs = this.getFallbackRecommendations();
            
            for (const fallbackRec of fallbackRecs) {
              if (matchedRecommendations.length >= 5) break;
              
              const isDuplicate = matchedRecommendations.some(rec => 
                this.areSimilarRecommendations(rec.text, fallbackRec.text)
              );
              
              if (!isDuplicate) {
                matchedRecommendations.push(fallbackRec);
              }
            }
            
            return matchedRecommendations.slice(0, 5);
          }
        }
      }
      
      // If no microactions or no matches, try AI if available
      if (this.openai) {
        return await this.generateAIRecommendations(patterns, sentimentAnalysis, userData);
      }
      
      // Final fallback - static recommendations
      return this.getFallbackRecommendations();
    } catch (error) {
      console.error('Recommendation generation error:', error);
      
      // Fallback to static recommendations if there's an error
      return this.getFallbackRecommendations();
    }
  }
  
  // Get static fallback recommendations
  getFallbackRecommendations() {
    return [
      {
        text: 'Get at least 7-8 hours of sleep each night',
        category: 'Sleep',
        subcategory: 'Sleep Duration',
        source: 'System Fallback',
        microaction: 'Set a consistent bedtime for tonight',
        difficultyLevel: 'Easy',
        timeToComplete: '5 min (setup)',
        description: 'Consistent sleep improves cognitive function and overall health'
      },
      {
        text: 'Take short movement breaks throughout the day',
        category: 'Fitness',
        subcategory: 'Daily Movement',
        source: 'System Fallback',
        microaction: 'Stand up and stretch for 2 minutes',
        difficultyLevel: 'Easy',
        timeToComplete: '2 min',
        description: 'Brief movement breaks reduce sedentary behavior risks'
      },
      {
        text: 'Practice mindful breathing when feeling stressed',
        category: 'Mental Health',
        subcategory: 'Stress Management',
        source: 'System Fallback',
        microaction: 'Take 10 deep breaths, focusing on your breathing',
        difficultyLevel: 'Easy',
        timeToComplete: '1 min',
        description: 'Deep breathing activates the parasympathetic nervous system, reducing stress'
      },
      {
        text: 'Stay hydrated by drinking water throughout the day',
        category: 'Nutrition',
        subcategory: 'Hydration',
        source: 'System Fallback',
        microaction: 'Drink a glass of water right now',
        difficultyLevel: 'Easy',
        timeToComplete: '1 min',
        description: 'Proper hydration supports energy levels, digestion, and cognitive function'
      },
      {
        text: 'Practice gratitude by noting three things you are grateful for today',
        category: 'Mental Health',
        subcategory: 'Positive Psychology',
        source: 'System Fallback',
        microaction: 'Write down three things you are grateful for today',
        difficultyLevel: 'Easy',
        timeToComplete: '5 min',
        description: 'Gratitude practices have been shown to improve mood and overall wellbeing'
      }
    ];
  }
  
  // Load microactions from JSON file
  async loadMicroactions() {
    try {
      const dataPath = path.join(__dirname, '../../data/microaction.json');
      const data = await fs.readFile(dataPath, 'utf8');
      const microactionsData = JSON.parse(data);
      
      // Process the microactions into a more usable format
      this.microactions = [];
      
      for (const episode of microactionsData) {
        for (const recommendation of episode.recommendations || []) {
          this.microactions.push({
            episodeNumber: episode.episodeNumber,
            episodeTitle: episode.episodeTitle,
            recommendation: recommendation.recommendation,
            shortDescription: recommendation.shortDescription,
            detailedDescription: recommendation.detailedDescription,
            microActivity: recommendation.microActivity,
            difficultyLevel: recommendation.difficultyLevel,
            timeToComplete: recommendation.timeToComplete,
            category: recommendation.category,
            subcategory: recommendation.subcategory,
            tags: recommendation.tags || []
          });
        }
      }
      
      console.log(`Loaded ${this.microactions.length} microactions`);
    } catch (error) {
      console.error('Failed to load microactions:', error);
      this.microactions = [];
    }
  }
  
  // Find matching microactions based on user data
  async findMatchingMicroactions(patterns, sentimentAnalysis, userData) {
    try {
      // Extract key terms and concepts from patterns and sentiment analysis
      const keyTerms = await this.extractKeyTerms(patterns, sentimentAnalysis);
      
      // Find microactions that match these key terms
      const matchedMicroactions = [];
      
      for (const microaction of this.microactions) {
        let matchScore = 0;
        
        // Check recommendation text
        for (const term of keyTerms) {
          const regex = new RegExp(`\\b${term}\\b`, 'i');
          
          if (regex.test(microaction.recommendation)) matchScore += 3;
          if (regex.test(microaction.shortDescription)) matchScore += 2;
          if (regex.test(microaction.detailedDescription)) matchScore += 1;
          
          // Also check tags
          if (microaction.tags && microaction.tags.some(tag => tag.toLowerCase().includes(term.toLowerCase()))) {
            matchScore += 2;
          }
          
          // Check category and subcategory
          if (microaction.category && microaction.category.toLowerCase().includes(term.toLowerCase())) {
            matchScore += 2;
          }
          if (microaction.subcategory && microaction.subcategory.toLowerCase().includes(term.toLowerCase())) {
            matchScore += 2;
          }
        }
        
        // Check user's feedback history to avoid recommending disliked items
        const isDisliked = this.isDislikedByUser(microaction, userData.recommendationFeedback);
        if (isDisliked) {
          // Significantly reduce score for disliked items
          matchScore = Math.max(0, matchScore - 10);
        }
        
        // Check if this recommendation has been completed recently
        const isRecentlyCompleted = this.isRecentlyCompleted(microaction, userData.recommendationFeedback);
        if (isRecentlyCompleted) {
          // Reduce score for recently completed items
          matchScore = Math.max(0, matchScore - 5);
        }
        
        if (matchScore > 0) {
          matchedMicroactions.push({
            text: microaction.recommendation,
            category: microaction.category,
            subcategory: microaction.subcategory,
            source: `${microaction.episodeTitle} (${microaction.episodeNumber})`,
            microaction: microaction.microActivity,
            difficultyLevel: microaction.difficultyLevel,
            timeToComplete: microaction.timeToComplete,
            description: microaction.shortDescription,
            matchScore
          });
        }
      }
      
      // Sort by match score (highest first)
      matchedMicroactions.sort((a, b) => b.matchScore - a.matchScore);
      
      // Return top 5
      return matchedMicroactions.slice(0, 5);
    } catch (error) {
      console.error('Error finding matching microactions:', error);
      return [];
    }
  }
  
  // Extract key terms from patterns and sentiment
  async extractKeyTerms(patterns, sentimentAnalysis) {
    try {
      // Check if OpenAI is available
      if (!this.openai) {
        // Return default terms if OpenAI is not available
        return ['sleep', 'stress', 'exercise', 'nutrition', 'mindfulness', 'health', 'wellness'];
      }
      
      // Use OpenAI to extract key terms
      const response = await this.openai.chat.completions.create({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: `Extract key health and wellness terms from the following health patterns and sentiment analysis.
            Focus on specific health concerns, activities, emotions, or wellness topics that could be used to match with recommendations.
            Return a list of 5-10 keywords or short phrases, each on a new line.`
          },
          {
            role: 'user',
            content: `Health Patterns:\n${patterns.join('\n')}\n\nSentiment Analysis:\n${sentimentAnalysis}`
          }
        ],
        temperature: 0.3,
        max_tokens: 150
      });
      
      // Process the response
      const termText = response.choices[0].message.content;
      let terms = termText.split('\n').map(t => t.trim().replace(/^\d+\.\s*/, '').toLowerCase());
      
      // Remove empty terms and duplicates
      terms = [...new Set(terms.filter(t => t))];
      
      // Add some default terms to ensure we always get some results
      const defaultTerms = ['sleep', 'stress', 'exercise', 'nutrition', 'mindfulness'];
      for (const term of defaultTerms) {
        if (!terms.includes(term)) {
          terms.push(term);
        }
      }
      
      return terms;
    } catch (error) {
      console.error('Error extracting key terms:', error);
      // Return default terms if extraction fails
      return ['sleep', 'stress', 'exercise', 'nutrition', 'mindfulness', 'health', 'wellness'];
    }
  }
  
  // Generate AI-based recommendations when microactions aren't available or suitable
  async generateAIRecommendations(patterns, sentimentAnalysis, userData) {
    try {
      // Use OpenAI to generate recommendations
      const response = await this.openai.chat.completions.create({
        model: 'gpt-4-turbo-preview',
        messages: [
          {
            role: 'system',
            content: `You are a wellness recommendation system. Based on the user's health patterns and sentiment analysis,
            generate 5 personalized recommendations for improving their health and wellness.
            
            Each recommendation should be in the following JSON format:
            {
              "text": "The main recommendation (concise imperative statement)",
              "category": "Main category (Sleep, Fitness, Nutrition, Mental Health, etc.)",
              "subcategory": "More specific subcategory",
              "microaction": "A very specific, small action the user can take immediately",
              "difficultyLevel": "Easy, Moderate, or Hard",
              "timeToComplete": "Approximate time to complete (e.g., '5 min', '15 min', '1 hour')",
              "description": "A 1-2 sentence explanation of why this recommendation is beneficial"
            }
            
            The recommendations should be evidence-based, practical, and tailored to the user's specific situation.
            Focus on small, achievable actions that can make a meaningful difference.
            Return a JSON array containing exactly 5 recommendation objects.`
          },
          {
            role: 'user',
            content: `Health Patterns:\n${patterns.join('\n')}\n\nSentiment Analysis:\n${sentimentAnalysis}`
          }
        ],
        temperature: 0.7,
        max_tokens: 1000,
        response_format: { type: "json_object" }
      });
      
      // Parse the response
      const content = response.choices[0].message.content;
      const recommendations = JSON.parse(content).recommendations || [];
      
      // Ensure we have valid recommendations
      return recommendations.map(rec => ({
        text: rec.text,
        category: rec.category,
        subcategory: rec.subcategory,
        source: 'AI Generated',
        microaction: rec.microaction,
        difficultyLevel: rec.difficultyLevel,
        timeToComplete: rec.timeToComplete,
        description: rec.description
      }));
    } catch (error) {
      console.error('Error generating AI recommendations:', error);
      
      // Return basic fallback recommendations if AI generation fails
      return [
        {
          text: 'Get at least 7-8 hours of sleep each night',
          category: 'Sleep',
          subcategory: 'Sleep Duration',
          source: 'System Fallback',
          microaction: 'Set a consistent bedtime for tonight',
          difficultyLevel: 'Easy',
          timeToComplete: '5 min (setup)',
          description: 'Consistent sleep improves cognitive function and overall health'
        },
        {
          text: 'Take short movement breaks throughout the day',
          category: 'Fitness',
          subcategory: 'Daily Movement',
          source: 'System Fallback',
          microaction: 'Stand up and stretch for 2 minutes',
          difficultyLevel: 'Easy',
          timeToComplete: '2 min',
          description: 'Brief movement breaks reduce sedentary behavior risks'
        },
        {
          text: 'Practice mindful breathing when feeling stressed',
          category: 'Mental Health',
          subcategory: 'Stress Management',
          source: 'System Fallback',
          microaction: 'Take 10 deep breaths, focusing on your breathing',
          difficultyLevel: 'Easy',
          timeToComplete: '1 min',
          description: 'Deep breathing activates the parasympathetic nervous system, reducing stress'
        }
      ];
    }
  }
  
  // Check if a recommendation is similar to another (to avoid duplicates)
  areSimilarRecommendations(rec1, rec2) {
    if (!rec1 || !rec2) return false;
    
    // Convert to lowercase and remove punctuation
    const normalize = text => text.toLowerCase().replace(/[^\w\s]/g, '');
    const norm1 = normalize(rec1);
    const norm2 = normalize(rec2);
    
    // Check for exact match
    if (norm1 === norm2) return true;
    
    // Check if one contains the other
    if (norm1.includes(norm2) || norm2.includes(norm1)) return true;
    
    // Check for high word overlap
    const words1 = new Set(norm1.split(/\s+/).filter(w => w.length > 3));
    const words2 = new Set(norm2.split(/\s+/).filter(w => w.length > 3));
    
    // Count overlapping significant words
    let overlap = 0;
    for (const word of words1) {
      if (words2.has(word)) overlap++;
    }
    
    // If more than 50% of words overlap, consider them similar
    const similarity = overlap / Math.min(words1.size, words2.size);
    return similarity > 0.5;
  }
  
  // Check if a recommendation has been disliked by the user
  isDislikedByUser(microaction, feedback) {
    if (!feedback || feedback.length === 0) return false;
    
    return feedback.some(item => 
      item.is_liked === 0 && // Explicitly disliked
      this.areSimilarRecommendations(microaction.recommendation, item.recommendation_text)
    );
  }
  
  // Check if a recommendation has been completed recently
  isRecentlyCompleted(microaction, feedback) {
    if (!feedback || feedback.length === 0) return false;
    
    // Get recommendations completed in the last 7 days
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    
    return feedback.some(item => {
      const itemDate = new Date(item.date);
      return item.is_completed === 1 && // Completed
             itemDate >= oneWeekAgo && // Within the last week
             this.areSimilarRecommendations(microaction.recommendation, item.recommendation_text);
    });
  }
  
  // Get all recommendatios for a user with feedback
  async getUserRecommendations(userId, startDate, endDate) {
    try {
      const { getDb } = require('../utils/db');
      const db = await getDb();
      
      const recommendations = await db.all(
        `SELECT id, date, recommendation_text, category, subcategory, source, 
                microaction, difficulty_level, time_to_complete, is_completed, is_liked, created_at
         FROM recommendations
         WHERE user_id = ? AND date BETWEEN ? AND ?
         ORDER BY date DESC, created_at DESC`,
        [userId, startDate, endDate]
      );
      
      return recommendations;
    } catch (error) {
      console.error('Failed to get user recommendations:', error);
      throw error;
    }
  }
  
  // Update recommendation feedback (liked/completed)
  async updateRecommendationFeedback(userId, recommendationId, isLiked, isCompleted) {
    try {
      const { getDb } = require('../utils/db');
      const db = await getDb();
      
      // Build the update SQL based on what's provided
      let sql = 'UPDATE recommendations SET ';
      const params = [];
      
      if (isLiked !== undefined) {
        sql += 'is_liked = ?';
        params.push(isLiked ? 1 : 0);
      }
      
      if (isCompleted !== undefined) {
        if (params.length > 0) sql += ', ';
        sql += 'is_completed = ?';
        params.push(isCompleted ? 1 : 0);
      }
      
      sql += ' WHERE id = ? AND user_id = ?';
      params.push(recommendationId, userId);
      
      await db.run(sql, params);
      
      return { success: true };
    } catch (error) {
      console.error('Failed to update recommendation feedback:', error);
      throw error;
    }
  }
}

module.exports = { RecommendationAgent }; 