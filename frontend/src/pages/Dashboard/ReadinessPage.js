import React from 'react';
import { useData } from '../../context/DataContext';
import { 
  Chart as ChartJS, 
  CategoryScale, 
  LinearScale, 
  PointElement, 
  LineElement, 
  BarElement,
  Title, 
  Tooltip, 
  Legend, 
  Filler,
  RadialLinearScale,
  ArcElement
} from 'chart.js';
import { Line, Bar, PolarArea } from 'react-chartjs-2';
import './DetailPages.css';

// Register ChartJS components
ChartJS.register(
  CategoryScale, 
  LinearScale, 
  PointElement, 
  LineElement, 
  BarElement,
  Title, 
  Tooltip, 
  Legend, 
  Filler,
  RadialLinearScale,
  ArcElement
);

const ReadinessPage = () => {
  const { ouraData, loadingOura } = useData();

  // Prepare readiness score data for line chart
  const prepareReadinessScoreData = () => {
    if (!ouraData?.readiness || ouraData.readiness.length === 0) {
      return null;
    }
    
    // Get last 14 days of data
    const readinessData = [...ouraData.readiness].slice(-14);
    
    // Sort by date
    readinessData.sort((a, b) => new Date(a.date) - new Date(b.date));
    
    const labels = readinessData.map(day => {
      const date = new Date(day.date);
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    });
    
    const scores = readinessData.map(day => day.score || 0);
    
    return {
      labels,
      datasets: [
        {
          label: 'Readiness Score',
          data: scores,
          borderColor: 'rgba(255, 107, 144, 1)',
          backgroundColor: 'rgba(255, 107, 144, 0.1)',
          fill: true,
          tension: 0.3,
          pointRadius: 3,
          pointHoverRadius: 6,
        }
      ]
    };
  };

  // Prepare recovery index data for line chart
  const prepareRecoveryIndexData = () => {
    if (!ouraData?.readiness || ouraData.readiness.length === 0) {
      return null;
    }
    
    // Get last 14 days of data
    const readinessData = [...ouraData.readiness].slice(-14);
    
    // Sort by date
    readinessData.sort((a, b) => new Date(a.date) - new Date(b.date));
    
    const labels = readinessData.map(day => {
      const date = new Date(day.date);
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    });
    
    const recoveryIndex = readinessData.map(day => day.recovery_index || 0);
    const hrBalanceScore = readinessData.map(day => day.resting_hr_balance_contrib || 0);
    const hrvBalanceScore = readinessData.map(day => day.hrv_balance_contrib || 0);
    
    return {
      labels,
      datasets: [
        {
          label: 'Recovery Index',
          data: recoveryIndex,
          borderColor: 'rgba(124, 58, 237, 1)',
          backgroundColor: 'rgba(124, 58, 237, 0.1)',
          fill: false,
          tension: 0.3,
          pointRadius: 3,
          pointHoverRadius: 6,
        },
        {
          label: 'Heart Rate Balance',
          data: hrBalanceScore,
          borderColor: 'rgba(236, 72, 153, 1)',
          backgroundColor: 'rgba(236, 72, 153, 0.1)',
          fill: false,
          tension: 0.3,
          pointRadius: 3,
          pointHoverRadius: 6,
        },
        {
          label: 'HRV Balance',
          data: hrvBalanceScore,
          borderColor: 'rgba(59, 130, 246, 1)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          fill: false,
          tension: 0.3,
          pointRadius: 3,
          pointHoverRadius: 6,
        }
      ]
    };
  };

  // Prepare readiness contributors data for polar area chart
  const prepareReadinessContributorsData = () => {
    if (!ouraData?.readiness || ouraData.readiness.length === 0) {
      return null;
    }
    
    // Get the most recent readiness data
    const latestReadiness = [...ouraData.readiness].sort((a, b) => 
      new Date(b.date) - new Date(a.date)
    )[0];
    
    return {
      labels: [
        'Sleep', 
        'Previous Day Activity', 
        'Activity Balance', 
        'Body Temperature',
        'Resting HR',
        'HRV Balance',
        'Recovery Index'
      ],
      datasets: [
        {
          data: [
            latestReadiness.sleep_balance_contrib || 0,
            latestReadiness.previous_day_activity_contrib || 0,
            latestReadiness.activity_balance_contrib || 0,
            latestReadiness.temperature_contrib || 0,
            latestReadiness.resting_hr_contrib || 0,
            latestReadiness.hrv_balance_contrib || 0,
            latestReadiness.recovery_index_contrib || 0
          ],
          backgroundColor: [
            'rgba(255, 99, 132, 0.7)',
            'rgba(54, 162, 235, 0.7)',
            'rgba(255, 206, 86, 0.7)',
            'rgba(75, 192, 192, 0.7)',
            'rgba(153, 102, 255, 0.7)',
            'rgba(255, 159, 64, 0.7)',
            'rgba(199, 210, 254, 0.7)'
          ],
          borderWidth: 1,
        }
      ]
    };
  };

  // Chart options
  const lineChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: false,
      },
      tooltip: {
        mode: 'index',
        intersect: false,
      },
      title: {
        display: true,
        text: 'Readiness Scores (Last 14 Days)',
        font: {
          size: 16,
        },
      },
    },
    scales: {
      y: {
        beginAtZero: false,
        min: 0,
        max: 100,
        title: {
          display: true,
          text: 'Score',
        },
        grid: {
          color: 'rgba(0, 0, 0, 0.05)',
        },
      },
      x: {
        grid: {
          display: false,
        },
      },
    },
  };
  
  const recoveryChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      tooltip: {
        mode: 'index',
        intersect: false,
      },
      title: {
        display: true,
        text: 'Recovery Metrics (Last 14 Days)',
        font: {
          size: 16,
        },
      },
    },
    scales: {
      y: {
        beginAtZero: true,
        title: {
          display: true,
          text: 'Value',
        },
        grid: {
          color: 'rgba(0, 0, 0, 0.05)',
        },
      },
      x: {
        grid: {
          display: false,
        },
      },
    },
  };
  
  const polarChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      tooltip: {
        mode: 'index',
        intersect: false,
      },
      title: {
        display: true,
        text: 'Readiness Contributors (Latest Day)',
        font: {
          size: 16,
        },
      },
      legend: {
        position: 'right',
      },
    },
    scales: {
      r: {
        ticks: {
          backdropColor: 'transparent',
        },
      },
    },
  };
  
  // Prepare chart data
  const readinessScoreData = prepareReadinessScoreData();
  const recoveryIndexData = prepareRecoveryIndexData();
  const readinessContributorsData = prepareReadinessContributorsData();
  
  // Latest readiness metrics for display
  const getLatestReadinessMetrics = () => {
    if (!ouraData?.readiness || ouraData.readiness.length === 0) {
      return null;
    }
    
    const latestReadiness = [...ouraData.readiness].sort((a, b) => 
      new Date(b.date) - new Date(a.date)
    )[0];
    
    return {
      date: new Date(latestReadiness.date).toLocaleDateString('en-US', { 
        weekday: 'long', 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
      }),
      score: latestReadiness.score || 0,
      recoveryIndex: latestReadiness.recovery_index || 0,
      restingHR: latestReadiness.resting_heart_rate || 0,
      hrvBalance: latestReadiness.hrv_balance || 0,
      bodyTemperature: (latestReadiness.temperature_deviation || 0).toFixed(2),
      sleepBalance: latestReadiness.sleep_balance || 0,
      activityBalance: latestReadiness.activity_balance || 0,
      readinessTemperatureStatus: latestReadiness.temperature_status || 'Normal',
      readinessHRVStatus: latestReadiness.hrv_balance_status || 'Normal',
    };
  };
  
  const latestReadinessMetrics = getLatestReadinessMetrics();

  return (
    <div className="detail-page">
      <h1>Readiness Data</h1>
      {loadingOura ? (
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading readiness data...</p>
        </div>
      ) : ouraData?.readiness?.length > 0 ? (
        <div className="detail-content">
          {/* Latest Readiness Summary Section */}
          {latestReadinessMetrics && (
            <div className="summary-section">
              <h2>Latest Readiness Summary - {latestReadinessMetrics.date}</h2>
              <div className="metrics-grid">
                <div className="metric-card">
                  <h3>Readiness Score</h3>
                  <div className="metric-value">{latestReadinessMetrics.score}</div>
                </div>
                <div className="metric-card">
                  <h3>Recovery Index</h3>
                  <div className="metric-value">{latestReadinessMetrics.recoveryIndex}</div>
                </div>
                <div className="metric-card">
                  <h3>Resting Heart Rate</h3>
                  <div className="metric-value">{latestReadinessMetrics.restingHR} bpm</div>
                </div>
                <div className="metric-card">
                  <h3>HRV Balance</h3>
                  <div className="metric-value">{latestReadinessMetrics.hrvBalance}</div>
                </div>
                <div className="metric-card">
                  <h3>Temperature Deviation</h3>
                  <div className="metric-value">{latestReadinessMetrics.bodyTemperature}°C</div>
                </div>
                <div className="metric-card">
                  <h3>Sleep Balance</h3>
                  <div className="metric-value">{latestReadinessMetrics.sleepBalance}</div>
                </div>
                <div className="metric-card">
                  <h3>Activity Balance</h3>
                  <div className="metric-value">{latestReadinessMetrics.activityBalance}</div>
                </div>
                <div className="metric-card">
                  <h3>Temperature Status</h3>
                  <div className="metric-value">{latestReadinessMetrics.readinessTemperatureStatus}</div>
                </div>
              </div>
            </div>
          )}
          
          {/* Charts Section */}
          <div className="charts-section">
            {readinessScoreData && (
              <div className="chart-container">
                <Line data={readinessScoreData} options={lineChartOptions} />
              </div>
            )}
            
            {recoveryIndexData && (
              <div className="chart-container">
                <Line data={recoveryIndexData} options={recoveryChartOptions} />
              </div>
            )}
            
            {readinessContributorsData && (
              <div className="chart-container">
                <PolarArea data={readinessContributorsData} options={polarChartOptions} />
              </div>
            )}
          </div>
        </div>
      ) : (
        <div className="no-data-message">
          <p>No readiness data available. Please connect your Oura Ring or other health tracking device.</p>
        </div>
      )}
    </div>
  );
};

export default ReadinessPage; 