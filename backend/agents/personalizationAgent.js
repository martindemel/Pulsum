class PersonalizationAgent {
  constructor(openai) {
    this.openai = openai;
  }
  
  // Personalize recommendations based on user feedback history
  async personalizeRecommendations(recommendations, userFeedback) {
    try {
      // If there's no feedback or recommendations, just return the original recommendations
      if (!userFeedback || userFeedback.length === 0 || !recommendations || recommendations.length === 0) {
        return recommendations;
      }
      
      // Extract user preferences from feedback
      const preferences = this.extractPreferences(userFeedback);
      
      // Skip personalization if there's not enough preference data
      if (Object.keys(preferences.liked).length === 0 && Object.keys(preferences.disliked).length === 0) {
        return recommendations;
      }
      
      // Use OpenAI to personalize the recommendations
      const response = await this.openai.chat.completions.create({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: `You are a recommendation personalization system. You have a set of health and wellness recommendations
            and need to personalize them based on the user's preferences and feedback history.
            
            The user tends to like recommendations related to: ${Object.keys(preferences.liked).join(', ')}
            The user tends to dislike recommendations related to: ${Object.keys(preferences.disliked).join(', ')}
            
            Your task is to:
            1. Adjust wording to better match the user's preferences
            2. Reorder the recommendations to prioritize types they tend to like
            3. Do not change the core advice or content of the recommendations
            4. Maintain the original JSON structure for each recommendation
            
            Return the personalized recommendations as a JSON array.`
          },
          {
            role: 'user',
            content: JSON.stringify(recommendations)
          }
        ],
        temperature: 0.4,
        max_tokens: 1500,
        response_format: { type: "json_object" }
      });
      
      // Parse the personalized recommendations
      const content = response.choices[0].message.content;
      let personalizedRecs;
      
      try {
        const parsed = JSON.parse(content);
        personalizedRecs = parsed.recommendations || parsed;
      } catch (error) {
        console.error('Error parsing personalized recommendations:', error);
        return recommendations; // Return original if parsing fails
      }
      
      // Ensure we maintain the same structure as the original recommendations
      return personalizedRecs.map((rec, index) => {
        // If we're missing fields, fallback to the original recommendation
        const originalRec = recommendations[index] || {};
        
        return {
          text: rec.text || originalRec.text,
          category: rec.category || originalRec.category,
          subcategory: rec.subcategory || originalRec.subcategory,
          source: rec.source || originalRec.source,
          microaction: rec.microaction || originalRec.microaction,
          difficultyLevel: rec.difficultyLevel || originalRec.difficultyLevel,
          timeToComplete: rec.timeToComplete || originalRec.timeToComplete,
          description: rec.description || originalRec.description
        };
      });
    } catch (error) {
      console.error('Personalization error:', error);
      return recommendations; // Return original recommendations if personalization fails
    }
  }
  
  // Extract user preferences from feedback history
  extractPreferences(userFeedback) {
    const liked = {};
    const disliked = {};
    
    for (const feedback of userFeedback) {
      if (feedback.is_liked === 1) {
        // User liked this recommendation
        this.updatePreferenceCount(liked, feedback.category);
        this.updatePreferenceCount(liked, feedback.subcategory);
      } else if (feedback.is_liked === 0) {
        // User disliked this recommendation
        this.updatePreferenceCount(disliked, feedback.category);
        this.updatePreferenceCount(disliked, feedback.subcategory);
      }
    }
    
    // Sort by count (highest first) and convert to object with normalized scores
    return {
      liked: this.normalizePreferences(liked),
      disliked: this.normalizePreferences(disliked)
    };
  }
  
  // Update preference count
  updatePreferenceCount(preferences, category) {
    if (!category) return;
    
    if (!preferences[category]) {
      preferences[category] = 1;
    } else {
      preferences[category]++;
    }
  }
  
  // Normalize preferences to values between 0 and 1
  normalizePreferences(preferences) {
    const entries = Object.entries(preferences);
    
    if (entries.length === 0) return {};
    
    // Find the maximum count
    const maxCount = Math.max(...entries.map(([_, count]) => count));
    
    // Normalize each count
    const normalized = {};
    for (const [category, count] of entries) {
      normalized[category] = count / maxCount;
    }
    
    return normalized;
  }
}

module.exports = { PersonalizationAgent }; 