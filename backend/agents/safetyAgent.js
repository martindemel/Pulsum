class SafetyAgent {
  constructor(openai) {
    this.openai = openai;
    
    // Define risk categories and response templates
    this.riskCategories = {
      suicide: {
        keywords: ['kill myself', 'end my life', 'commit suicide', 'want to die', 'no reason to live'],
        response: `I notice you're expressing thoughts about harming yourself. This is something I take very seriously. 

Please reach out to one of these resources right away:
• National Suicide Prevention Lifeline: 988 or 1-800-273-8255
• Crisis Text Line: Text HOME to 741741
• Or go to your nearest emergency room

These professionals are trained to help with exactly what you're going through. You deserve support, and help is available.`
      },
      selfHarm: {
        keywords: ['cut myself', 'hurt myself', 'self harm', 'harming myself', 'injure myself'],
        response: `I'm concerned about what you're saying regarding self-harm. 

Please consider reaching out to:
• Crisis Text Line: Text HOME to 741741
• National Suicide Prevention Lifeline: 988 or 1-800-273-8255
• Your doctor or therapist

These resources can provide immediate support and help you develop healthier coping strategies. You're not alone in these feelings, and professionals can help.`
      },
      harmToOthers: {
        keywords: ['kill them', 'hurt someone', 'attack', 'harm others', 'want to hurt'],
        response: `I notice you're expressing thoughts that may involve harm to others. I'm not able to provide guidance on this topic.

If you're having thoughts about harming others:
• Call your local emergency services
• Speak with a mental health professional
• Contact a crisis helpline: 988 or 1-800-273-8255

These resources can provide immediate support in a confidential manner.`
      },
      severeDistress: {
        keywords: ['can\'t take it anymore', 'unbearable', 'extreme anxiety', 'panic attack', 'breaking down'],
        response: `I can tell you're experiencing significant distress right now. 

Some immediate steps that might help:
• Take slow, deep breaths for a few minutes
• Ground yourself by naming 5 things you can see, 4 things you can touch, 3 things you can hear, 2 things you can smell, and 1 thing you can taste
• Call a supportive friend or family member
• Contact a crisis support line: 988 or text HOME to 741741

Please consider speaking with a mental health professional who can provide personalized support for what you're going through.`
      }
    };
  }
  
  // Check if a message contains safety concerns
  async checkMessage(message) {
    try {
      // First, do a quick keyword check
      const quickCheck = this.quickKeywordCheck(message);
      if (quickCheck.hasRisk) {
        return {
          isSafe: false,
          response: quickCheck.response
        };
      }
      
      // If not caught by keywords, use OpenAI for more nuanced detection
      const response = await this.openai.chat.completions.create({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: `You are a safety evaluation system for a health and wellness app. 
            Your task is to analyze user messages for serious safety concerns including:
            1. Suicide or self-harm ideation
            2. Intent to harm others
            3. Severe psychological distress
            
            For each message, return a JSON object with:
            {
              "hasSafetyConcern": boolean,
              "concernType": null or one of ["suicide", "selfHarm", "harmToOthers", "severeDistress"],
              "confidenceLevel": number from 0-1
            }
            
            Be conservative - only flag messages with clear indicators of risk.
            Do not flag messages that merely mention depression, anxiety, or other mental health conditions
            unless they include explicit risk indicators.`
          },
          {
            role: 'user',
            content: message
          }
        ],
        temperature: 0.1,
        max_tokens: 150,
        response_format: { type: "json_object" }
      });
      
      // Parse the response
      const content = response.choices[0].message.content;
      const analysis = JSON.parse(content);
      
      if (analysis.hasSafetyConcern && analysis.confidenceLevel > 0.7) {
        const riskType = analysis.concernType;
        const responseTemplate = this.getRiskResponse(riskType);
        
        return {
          isSafe: false,
          response: responseTemplate
        };
      }
      
      return {
        isSafe: true
      };
    } catch (error) {
      console.error('Safety check error:', error);
      // Fail open - if the safety check fails, return true (assume safe)
      return {
        isSafe: true
      };
    }
  }
  
  // Quick keyword check for immediate risk detection
  quickKeywordCheck(message) {
    const normalizedMessage = message.toLowerCase();
    
    for (const [riskType, riskInfo] of Object.entries(this.riskCategories)) {
      for (const keyword of riskInfo.keywords) {
        if (normalizedMessage.includes(keyword)) {
          return {
            hasRisk: true,
            riskType,
            response: riskInfo.response
          };
        }
      }
    }
    
    return {
      hasRisk: false
    };
  }
  
  // Get appropriate response template based on risk type
  getRiskResponse(riskType) {
    if (this.riskCategories[riskType]) {
      return this.riskCategories[riskType].response;
    }
    
    // Default response if risk type not found
    return `I notice you might be going through a difficult time. Please consider reaching out to a professional who can provide appropriate support:

• National Suicide Prevention Lifeline: 988 or 1-800-273-8255
• Crisis Text Line: Text HOME to 741741
• Your doctor or a mental health professional

These resources can provide immediate and confidential support.`;
  }
  
  // Filter an outgoing response for safety
  async filterResponse(response) {
    try {
      const safetyCheck = await this.openai.chat.completions.create({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: `You are a safety filter for health and wellness advice. Check if the following response
            contains any potentially harmful, dangerous, or unethical advice. This includes:
            
            1. Recommending dangerous activities or harmful behaviors
            2. Providing specific medical advice without appropriate qualifications
            3. Promoting restrictive diets or extreme exercise regimens
            4. Suggesting supplements or treatments without acknowledging risks
            5. Other content that could put a user's wellbeing at risk
            
            Return a JSON object with:
            {
              "isProblematic": boolean,
              "concerns": list of strings describing issues found,
              "safeVersion": revised version of the response that addresses concerns (if any)
            }`
          },
          {
            role: 'user',
            content: response
          }
        ],
        temperature: 0.1,
        max_tokens: 1000,
        response_format: { type: "json_object" }
      });
      
      // Parse the response
      const content = safetyCheck.choices[0].message.content;
      const analysis = JSON.parse(content);
      
      if (analysis.isProblematic && analysis.safeVersion) {
        return analysis.safeVersion;
      }
      
      return response;
    } catch (error) {
      console.error('Response filtering error:', error);
      // If filtering fails, return the original response
      return response;
    }
  }
}

module.exports = { SafetyAgent }; 