import React from 'react';
import { useData } from '../../context/DataContext';
import { useAuth } from '../../context/AuthContext';

const GlucosePage = () => {
  const { dexcomData, loadingDexcom } = useData();
  const { dexcomStatus } = useAuth();

  return (
    <div>
      <h1>Glucose Data</h1>
      {!dexcomStatus.isEnabled ? (
        <div>
          <p>Dexcom integration is not enabled. Please enable it in your account settings.</p>
        </div>
      ) : loadingDexcom ? (
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading glucose data...</p>
        </div>
      ) : (
        <div>
          <p>This page will display detailed glucose data and analytics.</p>
          {dexcomData?.allReadings?.length > 0 ? (
            <p>Data available for {dexcomData.dailyStats?.length || 0} days</p>
          ) : (
            <p>No glucose data available. Please connect your Dexcom device.</p>
          )}
        </div>
      )}
    </div>
  );
};

export default GlucosePage; 