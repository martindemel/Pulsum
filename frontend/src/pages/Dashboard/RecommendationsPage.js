import React from 'react';
import { useData } from '../../context/DataContext';

const RecommendationsPage = () => {
  const { recommendations, loadingRecommendations, generateRecommendations } = useData();

  return (
    <div>
      <h1>Recommendations</h1>
      
      <button onClick={generateRecommendations} disabled={loadingRecommendations}>
        Generate New Recommendations
      </button>
      
      {loadingRecommendations ? (
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading recommendations...</p>
        </div>
      ) : (
        <div>
          {recommendations && recommendations.length > 0 ? (
            <ul>
              {recommendations.map((rec, index) => (
                <li key={rec.id || index}>
                  {rec.recommendation_text || rec.text}
                </li>
              ))}
            </ul>
          ) : (
            <p>No recommendations available yet. Click the button above to generate recommendations.</p>
          )}
        </div>
      )}
    </div>
  );
};

export default RecommendationsPage; 