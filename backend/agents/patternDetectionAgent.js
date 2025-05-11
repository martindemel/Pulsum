class PatternDetectionAgent {
  constructor(openai) {
    this.openai = openai;
  }
  
  // Detect patterns in user health data
  async detectPatterns(userData) {
    try {
      const { oura, dexcom, wellnessScores } = userData;
      
      // Prepare the data for analysis
      const analysisData = {
        sleep: this.prepareSleepData(oura.sleep),
        readiness: this.prepareReadinessData(oura.readiness),
        activity: this.prepareActivityData(oura.activity),
        dexcom: this.prepareGlucoseData(dexcom),
        wellnessScores
      };
      
      // If there's not enough data, return a default message
      if (!this.hasEnoughData(analysisData)) {
        return ['Not enough data to detect meaningful patterns yet. Please continue using the app and sync more data.'];
      }
      
      // Use OpenAI to analyze the patterns
      const response = await this.openai.chat.completions.create({
        model: 'gpt-4-turbo-preview',
        messages: [
          {
            role: 'system',
            content: `You are a health data pattern detection system. Analyze the following user health data and identify key patterns and trends.
            Focus on sleep quality, readiness, activity levels, and heart rate variability${userData.useDexcom ? ', and glucose patterns' : ''}.
            Looking for correlations between different metrics, anomalies, improvements or declines over time, and potential areas of concern.
            Return exactly 5 key patterns or insights, each as a separate line.
            Keep each insight concise (1-2 sentences) and actionable.
            Base your analysis on concrete data points, not general advice.`
          },
          {
            role: 'user',
            content: JSON.stringify(analysisData)
          }
        ],
        temperature: 0.3,
        max_tokens: 700
      });
      
      // Process the response
      const patternText = response.choices[0].message.content;
      const patterns = patternText.split('\n').filter(p => p.trim() !== '');
      
      return patterns;
    } catch (error) {
      console.error('Pattern detection error:', error);
      return ['Unable to analyze health patterns at this time. Please try again later.'];
    }
  }
  
  // Check if we have enough data for meaningful analysis
  hasEnoughData(analysisData) {
    // If we have at least 3 days of sleep data, consider it enough to start
    return analysisData.sleep && analysisData.sleep.length >= 3;
  }
  
  // Prepare sleep data for analysis
  prepareSleepData(sleepData) {
    if (!sleepData || sleepData.length === 0) {
      return [];
    }
    
    return sleepData.map(day => {
      // Extract relevant sleep metrics
      const { 
        date,
        score = null,
        total_sleep_duration = null,
        deep_sleep_duration = null, 
        rem_sleep_duration = null,
        resting_heart_rate = null,
        sleep_efficiency = null,
        latency = null
      } = day;
      
      return {
        date,
        score,
        total_sleep_duration,
        deep_sleep_duration,
        rem_sleep_duration,
        resting_heart_rate,
        sleep_efficiency,
        latency
      };
    });
  }
  
  // Prepare readiness data for analysis
  prepareReadinessData(readinessData) {
    if (!readinessData || readinessData.length === 0) {
      return [];
    }
    
    return readinessData.map(day => {
      // Extract relevant readiness metrics
      const { 
        date,
        score = null,
        hrv_balance_score = null,
        temperature_deviation = null,
        recovery_index_score = null
      } = day;
      
      return {
        date,
        score,
        hrv_balance_score,
        temperature_deviation,
        recovery_index_score
      };
    });
  }
  
  // Prepare activity data for analysis
  prepareActivityData(activityData) {
    if (!activityData || activityData.length === 0) {
      return [];
    }
    
    return activityData.map(day => {
      // Extract relevant activity metrics
      const { 
        date,
        score = null,
        daily_movement = null,
        steps = null,
        training_frequency = null,
        training_volume = null,
        activity_burn = null
      } = day;
      
      return {
        date,
        score,
        daily_movement,
        steps,
        training_frequency,
        training_volume,
        activity_burn
      };
    });
  }
  
  // Prepare glucose data for analysis
  prepareGlucoseData(glucoseData) {
    if (!glucoseData || glucoseData.length === 0) {
      return [];
    }
    
    // Group glucose readings by date
    const glucoseByDate = {};
    
    glucoseData.forEach(reading => {
      if (!glucoseByDate[reading.date]) {
        glucoseByDate[reading.date] = [];
      }
      
      glucoseByDate[reading.date].push({
        timestamp: reading.reading_time,
        value: reading.glucose_value,
        trend: reading.trend
      });
    });
    
    // Calculate daily metrics
    return Object.keys(glucoseByDate).map(date => {
      const readings = glucoseByDate[date];
      const values = readings.map(r => r.value);
      
      return {
        date,
        readings_count: readings.length,
        min: Math.min(...values),
        max: Math.max(...values),
        average: values.reduce((sum, val) => sum + val, 0) / values.length,
        readings: readings.length > 20 ? readings.filter((_, i) => i % Math.ceil(readings.length / 20) === 0) : readings
      };
    });
  }
}

module.exports = { PatternDetectionAgent }; 