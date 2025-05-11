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
  ArcElement,
  DoughnutController
} from 'chart.js';
import { Line, Bar, Doughnut } from 'react-chartjs-2';
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
  ArcElement,
  DoughnutController
);

const ActivityPage = () => {
  const { ouraData, loadingOura } = useData();

  // Prepare activity score data for line chart
  const prepareActivityScoreData = () => {
    if (!ouraData?.activity || ouraData.activity.length === 0) {
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
    
    const scores = activityData.map(day => day.score || 0);
    
    return {
      labels,
      datasets: [
        {
          label: 'Activity Score',
          data: scores,
          borderColor: 'rgba(34, 197, 94, 1)',
          backgroundColor: 'rgba(34, 197, 94, 0.1)',
          fill: true,
          tension: 0.3,
          pointRadius: 3,
          pointHoverRadius: 6,
        }
      ]
    };
  };

  // Prepare steps data for bar chart
  const prepareStepsData = () => {
    if (!ouraData?.activity || ouraData.activity.length === 0) {
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
          backgroundColor: 'rgba(34, 197, 94, 0.7)',
          borderRadius: 4,
        }
      ]
    };
  };

  // Prepare calories data
  const prepareCaloriesData = () => {
    if (!ouraData?.activity || ouraData.activity.length === 0) {
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
    
    const totalCalories = activityData.map(day => day.calories || 0);
    const activeCalories = activityData.map(day => day.calories_active || 0);
    
    return {
      labels,
      datasets: [
        {
          label: 'Total Calories',
          data: totalCalories,
          backgroundColor: 'rgba(251, 146, 60, 0.7)',
          borderColor: 'rgba(251, 146, 60, 1)',
          borderRadius: 4,
        },
        {
          label: 'Active Calories',
          data: activeCalories,
          backgroundColor: 'rgba(249, 115, 22, 0.7)',
          borderColor: 'rgba(249, 115, 22, 1)',
          borderRadius: 4,
        }
      ]
    };
  };

  // Prepare activity breakdown data for doughnut chart
  const prepareActivityBreakdownData = () => {
    if (!ouraData?.activity || ouraData.activity.length === 0) {
      return null;
    }
    
    // Get the most recent activity data
    const latestActivity = [...ouraData.activity].sort((a, b) => 
      new Date(b.date) - new Date(a.date)
    )[0];
    
    // Convert minutes to hours for better visualization
    const sedentaryHours = Math.round((latestActivity.inactive_time || 0) / 60 * 10) / 10;
    const lightHours = Math.round((latestActivity.low_activity_time || 0) / 60 * 10) / 10;
    const moderateHours = Math.round((latestActivity.medium_activity_time || 0) / 60 * 10) / 10;
    const highHours = Math.round((latestActivity.high_activity_time || 0) / 60 * 10) / 10;
    
    return {
      labels: ['Sedentary', 'Light Activity', 'Moderate Activity', 'High Activity'],
      datasets: [
        {
          data: [sedentaryHours, lightHours, moderateHours, highHours],
          backgroundColor: [
            'rgba(148, 163, 184, 0.7)',
            'rgba(74, 222, 128, 0.7)',
            'rgba(34, 197, 94, 0.7)', 
            'rgba(22, 163, 74, 0.7)'
          ],
          borderColor: [
            'rgba(148, 163, 184, 1)',
            'rgba(74, 222, 128, 1)',
            'rgba(34, 197, 94, 1)', 
            'rgba(22, 163, 74, 1)'
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
        text: 'Activity Scores (Last 14 Days)',
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
      legend: {
        display: false,
      },
      tooltip: {
        mode: 'index',
        intersect: false,
      },
      title: {
        display: true,
        text: 'Daily Steps (Last 14 Days)',
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
          text: 'Steps',
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
  
  const caloriesChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      tooltip: {
        mode: 'index',
        intersect: false,
      },
      title: {
        display: true,
        text: 'Daily Calories (Last 14 Days)',
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
          text: 'Calories',
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
  
  const doughnutChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'right',
      },
      title: {
        display: true,
        text: 'Latest Activity Breakdown (Hours)',
        font: {
          size: 16,
        },
      },
    },
    cutout: '60%',
  };
  
  // Prepare chart data
  const activityScoreData = prepareActivityScoreData();
  const stepsData = prepareStepsData();
  const caloriesData = prepareCaloriesData();
  const activityBreakdownData = prepareActivityBreakdownData();
  
  // Latest activity metrics for display
  const getLatestActivityMetrics = () => {
    if (!ouraData?.activity || ouraData.activity.length === 0) {
      return null;
    }
    
    const latestActivity = [...ouraData.activity].sort((a, b) => 
      new Date(b.date) - new Date(a.date)
    )[0];
    
    return {
      date: new Date(latestActivity.date).toLocaleDateString('en-US', { 
        weekday: 'long', 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
      }),
      score: latestActivity.score || 0,
      steps: latestActivity.steps || 0,
      totalCalories: latestActivity.calories || 0,
      activeCalories: latestActivity.calories_active || 0,
      distance: Math.round((latestActivity.distance || 0) / 1000 * 10) / 10, // km with 1 decimal
      moveTime: Math.round((latestActivity.low_activity_time + latestActivity.medium_activity_time + latestActivity.high_activity_time || 0) / 60 * 10) / 10, // hours
      dailyMovementGoal: latestActivity.daily_movement_goal_reached ? 'Achieved' : 'Not Achieved',
      stayActiveGoal: latestActivity.stay_active_goal_reached ? 'Achieved' : 'Not Achieved',
    };
  };
  
  const latestActivityMetrics = getLatestActivityMetrics();

  return (
    <div className="detail-page">
      <h1>Activity Data</h1>
      {loadingOura ? (
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading activity data...</p>
        </div>
      ) : ouraData?.activity?.length > 0 ? (
        <div className="detail-content">
          {/* Latest Activity Summary Section */}
          {latestActivityMetrics && (
            <div className="summary-section">
              <h2>Latest Activity Summary - {latestActivityMetrics.date}</h2>
              <div className="metrics-grid">
                <div className="metric-card">
                  <h3>Activity Score</h3>
                  <div className="metric-value">{latestActivityMetrics.score}</div>
                </div>
                <div className="metric-card">
                  <h3>Steps</h3>
                  <div className="metric-value">{latestActivityMetrics.steps.toLocaleString()}</div>
                </div>
                <div className="metric-card">
                  <h3>Distance</h3>
                  <div className="metric-value">{latestActivityMetrics.distance} km</div>
                </div>
                <div className="metric-card">
                  <h3>Active Time</h3>
                  <div className="metric-value">{latestActivityMetrics.moveTime} hrs</div>
                </div>
                <div className="metric-card">
                  <h3>Total Calories</h3>
                  <div className="metric-value">{latestActivityMetrics.totalCalories.toLocaleString()}</div>
                </div>
                <div className="metric-card">
                  <h3>Active Calories</h3>
                  <div className="metric-value">{latestActivityMetrics.activeCalories.toLocaleString()}</div>
                </div>
                <div className="metric-card">
                  <h3>Movement Goal</h3>
                  <div className="metric-value">{latestActivityMetrics.dailyMovementGoal}</div>
                </div>
                <div className="metric-card">
                  <h3>Stay Active Goal</h3>
                  <div className="metric-value">{latestActivityMetrics.stayActiveGoal}</div>
                </div>
              </div>
            </div>
          )}
          
          {/* Charts Section */}
          <div className="charts-section">
            {activityScoreData && (
              <div className="chart-container">
                <Line data={activityScoreData} options={lineChartOptions} />
              </div>
            )}
            
            {stepsData && (
              <div className="chart-container">
                <Bar data={stepsData} options={barChartOptions} />
              </div>
            )}
            
            {caloriesData && (
              <div className="chart-container">
                <Bar data={caloriesData} options={caloriesChartOptions} />
              </div>
            )}
            
            {activityBreakdownData && (
              <div className="chart-container">
                <Doughnut data={activityBreakdownData} options={doughnutChartOptions} />
              </div>
            )}
          </div>
        </div>
      ) : (
        <div className="no-data-message">
          <p>No activity data available. Please connect your Oura Ring or other activity tracking device.</p>
        </div>
      )}
    </div>
  );
};

export default ActivityPage; 