import React from 'react';
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
  Filler
} from 'chart.js';
import { Line, Bar } from 'react-chartjs-2';
import styles from './DataOverview.module.css';

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
  Filler
);

const DataOverview = ({ ouraData, dexcomData, loadingOura, loadingDexcom, hasDexcom }) => {
  // Prepare sleep data for chart
  const prepareSleepData = () => {
    if (!ouraData.sleep || ouraData.sleep.length === 0) {
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
  
  // Prepare readiness data for chart
  const prepareReadinessData = () => {
    if (!ouraData.readiness || ouraData.readiness.length === 0) {
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
  
  // Prepare activity data for chart
  const prepareActivityData = () => {
    if (!ouraData.activity || ouraData.activity.length === 0) {
      return null;
    }
    
    // Get last 14 days of data
    const activityData = [...ouraData.activity].slice(-14);
    
    // Sort by date
    activityData.sort((a, b) => new Date(a.date) - new Date(b.date));
    
    const labels = activityData.map(day => {
      const date = new Date(day.date);
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    });
    
    const steps = activityData.map(day => day.steps || 0);
    
    return {
      labels,
      datasets: [
        {
          label: 'Steps',
          data: steps,
          backgroundColor: 'rgba(34, 197, 94, 0.6)',
          borderRadius: 4,
        }
      ]
    };
  };
  
  // Prepare glucose data for chart
  const prepareGlucoseData = () => {
    if (!hasDexcom || !dexcomData.dailyStats || dexcomData.dailyStats.length === 0) {
      return null;
    }
    
    // Get last 14 days of data
    const glucoseData = [...dexcomData.dailyStats].slice(-14);
    
    // Sort by date
    glucoseData.sort((a, b) => new Date(a.date) - new Date(b.date));
    
    const labels = glucoseData.map(day => {
      const date = new Date(day.date);
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    });
    
    const avgValues = glucoseData.map(day => day.avg || 0);
    const minValues = glucoseData.map(day => day.min || 0);
    const maxValues = glucoseData.map(day => day.max || 0);
    
    return {
      labels,
      datasets: [
        {
          label: 'Average Glucose',
          data: avgValues,
          borderColor: 'rgba(59, 130, 246, 1)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          fill: false,
          tension: 0.3,
          pointRadius: 3,
          pointHoverRadius: 6,
        },
        {
          label: 'Min Glucose',
          data: minValues,
          borderColor: 'rgba(59, 130, 246, 0.5)',
          backgroundColor: 'transparent',
          borderDash: [5, 5],
          fill: false,
          pointRadius: 0,
        },
        {
          label: 'Max Glucose',
          data: maxValues,
          borderColor: 'rgba(59, 130, 246, 0.5)',
          backgroundColor: 'transparent',
          borderDash: [5, 5],
          fill: false,
          pointRadius: 0,
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
    },
    scales: {
      y: {
        beginAtZero: false,
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
      legend: {
        display: false,
      },
      tooltip: {
        mode: 'index',
        intersect: false,
      },
    },
    scales: {
      y: {
        beginAtZero: true,
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
  
  const glucoseChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        position: 'top',
      },
      tooltip: {
        mode: 'index',
        intersect: false,
      },
    },
    scales: {
      y: {
        beginAtZero: false,
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
  
  // Prepare chart data
  const sleepData = prepareSleepData();
  const readinessData = prepareReadinessData();
  const activityData = prepareActivityData();
  const glucoseData = prepareGlucoseData();
  
  return (
    <div className={styles.dataOverview}>
      {loadingOura ? (
        <div className={styles.loading}>
          <div className={styles.loadingSpinner}></div>
          <p>Loading health data...</p>
        </div>
      ) : (
        <>
          {sleepData && (
            <div className={styles.chartCard}>
              <h3 className={styles.chartTitle}>Sleep Score</h3>
              <div className={styles.chartContainer}>
                <Line data={sleepData} options={lineChartOptions} />
              </div>
            </div>
          )}
          
          {readinessData && (
            <div className={styles.chartCard}>
              <h3 className={styles.chartTitle}>Readiness Score</h3>
              <div className={styles.chartContainer}>
                <Line data={readinessData} options={lineChartOptions} />
              </div>
            </div>
          )}
          
          {activityData && (
            <div className={styles.chartCard}>
              <h3 className={styles.chartTitle}>Daily Steps</h3>
              <div className={styles.chartContainer}>
                <Bar data={activityData} options={barChartOptions} />
              </div>
            </div>
          )}
          
          {hasDexcom && (
            <>
              {loadingDexcom ? (
                <div className={styles.loading}>
                  <div className={styles.loadingSpinner}></div>
                  <p>Loading glucose data...</p>
                </div>
              ) : (
                glucoseData && (
                  <div className={styles.chartCard}>
                    <h3 className={styles.chartTitle}>Glucose (mg/dL)</h3>
                    <div className={styles.chartContainer}>
                      <Line data={glucoseData} options={glucoseChartOptions} />
                    </div>
                  </div>
                )
              )}
            </>
          )}
          
          {!sleepData && !readinessData && !activityData && (!hasDexcom || !glucoseData) && (
            <div className={styles.noData}>
              <p>No health data available. Please connect your Oura Ring and sync data.</p>
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default DataOverview; 