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
import { Line, Bar, Radar } from 'react-chartjs-2';
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

const SleepPage = () => {
  const { ouraData, loadingOura } = useData();

  // Prepare sleep score data for line chart
  const prepareSleepScoreData = () => {
    if (!ouraData?.sleep || ouraData.sleep.length === 0) {
      return null;
    }
    
    // Get last 14 days of data
    const sleepData = [...ouraData.sleep].slice(-14);
    
    // Sort by date
    sleepData.sort((a, b) => new Date(a.date) - new Date(b.date));
    
    const labels = sleepData.map(day => {
      const date = new Date(day.date);
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    });
    
    const scores = sleepData.map(day => day.score || 0);
    
    return {
      labels,
      datasets: [
        {
          label: 'Sleep Score',
          data: scores,
          borderColor: 'rgba(76, 101, 255, 1)',
          backgroundColor: 'rgba(76, 101, 255, 0.1)',
          fill: true,
          tension: 0.3,
          pointRadius: 3,
          pointHoverRadius: 6,
        }
      ]
    };
  };

  // Prepare sleep stages data for bar chart
  const prepareSleepStagesData = () => {
    if (!ouraData?.sleep || ouraData.sleep.length === 0) {
      return null;
    }
    
    // Get last 7 days of data
    const sleepData = [...ouraData.sleep].slice(-7);
    
    // Sort by date
    sleepData.sort((a, b) => new Date(a.date) - new Date(b.date));
    
    const labels = sleepData.map(day => {
      const date = new Date(day.date);
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    });
    
    const deepSleep = sleepData.map(day => (day.deep || 0) / 60); // convert to hours
    const remSleep = sleepData.map(day => (day.rem || 0) / 60);
    const lightSleep = sleepData.map(day => (day.light || 0) / 60);
    const awake = sleepData.map(day => (day.awake || 0) / 60);
    
    return {
      labels,
      datasets: [
        {
          label: 'Deep Sleep',
          data: deepSleep,
          backgroundColor: 'rgba(53, 162, 235, 0.7)',
          stack: 'Stack 0',
        },
        {
          label: 'REM Sleep',
          data: remSleep,
          backgroundColor: 'rgba(255, 99, 132, 0.7)',
          stack: 'Stack 0',
        },
        {
          label: 'Light Sleep',
          data: lightSleep,
          backgroundColor: 'rgba(75, 192, 192, 0.7)',
          stack: 'Stack 0',
        },
        {
          label: 'Awake',
          data: awake,
          backgroundColor: 'rgba(255, 206, 86, 0.7)',
          stack: 'Stack 0',
        }
      ]
    };
  };

  // Prepare sleep metrics data for radar chart
  const prepareSleepMetricsData = () => {
    if (!ouraData?.sleep || ouraData.sleep.length === 0) {
      return null;
    }
    
    // Get the most recent sleep data
    const latestSleep = [...ouraData.sleep].sort((a, b) => 
      new Date(b.date) - new Date(a.date)
    )[0];
    
    return {
      labels: ['Efficiency', 'Latency', 'Restfulness', 'Timing', 'Total Sleep'],
      datasets: [
        {
          label: 'Sleep Metrics',
          data: [
            latestSleep.efficiency || 0,
            Math.max(0, 100 - (latestSleep.latency || 0)), // Invert latency (lower is better)
            latestSleep.restfulness || 0,
            latestSleep.timing || 0,
            latestSleep.total_sleep || 0,
          ],
          backgroundColor: 'rgba(76, 101, 255, 0.2)',
          borderColor: 'rgba(76, 101, 255, 1)',
          borderWidth: 2,
          pointBackgroundColor: 'rgba(76, 101, 255, 1)',
          pointBorderColor: '#fff',
          pointHoverBackgroundColor: '#fff',
          pointHoverBorderColor: 'rgba(76, 101, 255, 1)',
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
        text: 'Sleep Scores (Last 14 Days)',
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
  
  const barChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      tooltip: {
        mode: 'index',
        intersect: false,
      },
      title: {
        display: true,
        text: 'Sleep Stages (Last 7 Days)',
        font: {
          size: 16,
        },
      },
    },
    scales: {
      y: {
        stacked: true,
        beginAtZero: true,
        title: {
          display: true,
          text: 'Hours',
        },
        grid: {
          color: 'rgba(0, 0, 0, 0.05)',
        },
      },
      x: {
        stacked: true,
        grid: {
          display: false,
        },
      },
    },
  };
  
  const radarChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      title: {
        display: true,
        text: 'Sleep Quality Metrics (Latest Night)',
        font: {
          size: 16,
        },
      },
    },
    scales: {
      r: {
        angleLines: {
          display: true,
        },
        suggestedMin: 0,
        suggestedMax: 100,
      },
    },
  };
  
  // Prepare chart data
  const sleepScoreData = prepareSleepScoreData();
  const sleepStagesData = prepareSleepStagesData();
  const sleepMetricsData = prepareSleepMetricsData();
  
  // Latest sleep metrics for display
  const getLatestSleepMetrics = () => {
    if (!ouraData?.sleep || ouraData.sleep.length === 0) {
      return null;
    }
    
    const latestSleep = [...ouraData.sleep].sort((a, b) => 
      new Date(b.date) - new Date(a.date)
    )[0];
    
    return {
      date: new Date(latestSleep.date).toLocaleDateString('en-US', { 
        weekday: 'long', 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
      }),
      score: latestSleep.score || 0,
      totalSleep: Math.round((latestSleep.total || 0) / 60 * 10) / 10, // Convert to hours with 1 decimal
      deepSleep: Math.round((latestSleep.deep || 0) / 60 * 10) / 10,
      remSleep: Math.round((latestSleep.rem || 0) / 60 * 10) / 10,
      lightSleep: Math.round((latestSleep.light || 0) / 60 * 10) / 10,
      efficiency: latestSleep.efficiency || 0,
      latency: latestSleep.latency || 0,
      hrAvg: latestSleep.hr_average || 0,
      hrvAvg: latestSleep.hrv_average || 0,
      respirationRate: latestSleep.breath_average || 0,
    };
  };
  
  const latestSleepMetrics = getLatestSleepMetrics();

  return (
    <div className="detail-page">
      <h1>Sleep Data</h1>
      {loadingOura ? (
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading sleep data...</p>
        </div>
      ) : ouraData?.sleep?.length > 0 ? (
        <div className="detail-content">
          {/* Latest Sleep Summary Section */}
          {latestSleepMetrics && (
            <div className="summary-section">
              <h2>Latest Sleep Summary - {latestSleepMetrics.date}</h2>
              <div className="metrics-grid">
                <div className="metric-card">
                  <h3>Sleep Score</h3>
                  <div className="metric-value">{latestSleepMetrics.score}</div>
                </div>
                <div className="metric-card">
                  <h3>Total Sleep</h3>
                  <div className="metric-value">{latestSleepMetrics.totalSleep} hrs</div>
                </div>
                <div className="metric-card">
                  <h3>Sleep Efficiency</h3>
                  <div className="metric-value">{latestSleepMetrics.efficiency}%</div>
                </div>
                <div className="metric-card">
                  <h3>Deep Sleep</h3>
                  <div className="metric-value">{latestSleepMetrics.deepSleep} hrs</div>
                </div>
                <div className="metric-card">
                  <h3>REM Sleep</h3>
                  <div className="metric-value">{latestSleepMetrics.remSleep} hrs</div>
                </div>
                <div className="metric-card">
                  <h3>Light Sleep</h3>
                  <div className="metric-value">{latestSleepMetrics.lightSleep} hrs</div>
                </div>
                <div className="metric-card">
                  <h3>Avg Heart Rate</h3>
                  <div className="metric-value">{latestSleepMetrics.hrAvg} bpm</div>
                </div>
                <div className="metric-card">
                  <h3>Avg HRV</h3>
                  <div className="metric-value">{latestSleepMetrics.hrvAvg} ms</div>
                </div>
              </div>
            </div>
          )}
          
          {/* Charts Section */}
          <div className="charts-section">
            {sleepScoreData && (
              <div className="chart-container">
                <Line data={sleepScoreData} options={lineChartOptions} />
              </div>
            )}
            
            {sleepStagesData && (
              <div className="chart-container">
                <Bar data={sleepStagesData} options={barChartOptions} />
              </div>
            )}
            
            {sleepMetricsData && (
              <div className="chart-container radar-container">
                <Radar data={sleepMetricsData} options={radarChartOptions} />
              </div>
            )}
          </div>
        </div>
      ) : (
        <div className="no-data-message">
          <p>No sleep data available. Please connect your Oura Ring or other sleep tracking device.</p>
        </div>
      )}
    </div>
  );
};

export default SleepPage; 