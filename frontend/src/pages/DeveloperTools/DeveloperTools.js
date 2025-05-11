import React, { useState, useEffect, useRef } from 'react';
import { useAuth } from '../../context/AuthContext';
import { useData } from '../../context/DataContext';
import { 
  FaSync, FaChevronDown, FaChevronUp, FaEye, FaEyeSlash, 
  FaNetworkWired, FaMemory, FaSpinner, FaClock, FaExclamationTriangle
} from 'react-icons/fa';
import styles from './DeveloperTools.module.css';
import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';

// Register ChartJS components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

const DeveloperTools = () => {
  const { ouraStatus, dexcomStatus } = useAuth();
  const { 
    ouraData, 
    dexcomData,
    dashboardSummary,
    wellnessScores,
    journalEntries,
    recommendations,
    chatHistory
  } = useData();
  
  const [logs, setLogs] = useState([]);
  const [expandedSections, setExpandedSections] = useState({
    auth: true,
    data: false,
    logs: true,
    performance: true,
    network: true
  });
  
  const [secretsVisible, setSecretsVisible] = useState(false);
  
  // Performance monitoring
  const [performanceMetrics, setPerformanceMetrics] = useState({
    memory: [],
    fps: [],
    loadTimes: {},
    errors: []
  });
  
  // Network request tracking
  const [networkRequests, setNetworkRequests] = useState([]);
  const [networkStats, setNetworkStats] = useState({
    total: 0,
    success: 0,
    failed: 0,
    avgResponseTime: 0
  });
  
  const perfInterval = useRef(null);
  
  // Collect logs from console
  useEffect(() => {
    const originalConsoleLog = console.log;
    const originalConsoleError = console.error;
    const originalConsoleWarn = console.warn;
    
    const interceptLog = (type, args) => {
      const logMessage = Array.from(args).map(arg => {
        if (typeof arg === 'object') {
          return JSON.stringify(arg, null, 2);
        }
        return String(arg);
      }).join(' ');
      
      setLogs(prevLogs => [
        { 
          type, 
          message: logMessage, 
          timestamp: new Date().toISOString() 
        },
        ...prevLogs.slice(0, 99) // Keep only the latest 100 logs
      ]);
      
      return args;
    };
    
    console.log = (...args) => {
      originalConsoleLog(...interceptLog('log', args));
    };
    
    console.error = (...args) => {
      originalConsoleError(...interceptLog('error', args));
      
      // Also track errors in performance metrics
      const errorMessage = Array.from(args).map(arg => {
        if (typeof arg === 'object') {
          return JSON.stringify(arg, null, 2);
        }
        return String(arg);
      }).join(' ');
      
      setPerformanceMetrics(prev => ({
        ...prev,
        errors: [...prev.errors, {
          message: errorMessage,
          timestamp: new Date().toISOString()
        }].slice(-20) // Keep only the latest 20 errors
      }));
    };
    
    console.warn = (...args) => {
      originalConsoleWarn(...interceptLog('warn', args));
    };
    
    // Add some initial logs
    console.log('Developer tools initialized');
    
    return () => {
      console.log = originalConsoleLog;
      console.error = originalConsoleError;
      console.warn = originalConsoleWarn;
    };
  }, []);
  
  // Set up network request monitoring
  useEffect(() => {
    const originalFetch = window.fetch;
    
    window.fetch = async (...args) => {
      const url = args[0].url || args[0];
      const method = args[1]?.method || 'GET';
      const startTime = performance.now();
      const requestId = Date.now();
      
      // Record the start of the request
      setNetworkRequests(prev => [
        ...prev,
        {
          id: requestId,
          url: url.toString(),
          method,
          status: 'pending',
          startTime,
          endTime: null,
          duration: null
        }
      ].slice(-50)); // Keep only the latest 50 requests
      
      try {
        const response = await originalFetch(...args);
        const endTime = performance.now();
        const duration = endTime - startTime;
        
        // Update the request with the response details
        setNetworkRequests(prev => prev.map(req => 
          req.id === requestId
            ? {
                ...req,
                status: response.ok ? 'success' : 'error',
                statusCode: response.status,
                endTime,
                duration
              }
            : req
        ));
        
        // Update network stats
        setNetworkStats(prev => {
          const newTotal = prev.total + 1;
          const newSuccess = prev.success + (response.ok ? 1 : 0);
          const newFailed = prev.failed + (response.ok ? 0 : 1);
          const newAvgTime = ((prev.avgResponseTime * prev.total) + duration) / newTotal;
          
          return {
            total: newTotal,
            success: newSuccess,
            failed: newFailed,
            avgResponseTime: newAvgTime
          };
        });
        
        // Clone the response so we can still use it
        const clone = response.clone();
        return clone;
      } catch (error) {
        const endTime = performance.now();
        const duration = endTime - startTime;
        
        // Update the request with the error details
        setNetworkRequests(prev => prev.map(req => 
          req.id === requestId
            ? {
                ...req,
                status: 'failed',
                error: error.message,
                endTime,
                duration
              }
            : req
        ));
        
        // Update network stats
        setNetworkStats(prev => ({
          total: prev.total + 1,
          success: prev.success,
          failed: prev.failed + 1,
          avgResponseTime: ((prev.avgResponseTime * prev.total) + duration) / (prev.total + 1)
        }));
        
        throw error;
      }
    };
    
    return () => {
      window.fetch = originalFetch;
    };
  }, []);
  
  // Set up performance monitoring
  useEffect(() => {
    // Start collecting performance metrics
    const collectMetrics = () => {
      // Memory usage (if available)
      if (performance.memory) {
        const now = new Date();
        const memory = performance.memory.usedJSHeapSize / (1024 * 1024); // Convert to MB
        
        setPerformanceMetrics(prev => ({
          ...prev,
          memory: [...prev.memory, {
            value: Math.round(memory * 100) / 100,
            timestamp: now.toISOString()
          }].slice(-30) // Keep only the latest 30 data points
        }));
      }
      
      // Page load metrics
      const pageLoadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
      const domReadyTime = performance.timing.domComplete - performance.timing.domLoading;
      
      setPerformanceMetrics(prev => ({
        ...prev,
        loadTimes: {
          ...prev.loadTimes,
          pageLoad: pageLoadTime,
          domReady: domReadyTime,
        }
      }));
      
      // FPS approximation using requestAnimationFrame
      let lastTime = performance.now();
      let frames = 0;
      
      const calculateFPS = () => {
        const now = performance.now();
        frames++;
        
        if (now >= lastTime + 1000) {
          const fps = Math.round((frames * 1000) / (now - lastTime));
          
          setPerformanceMetrics(prev => ({
            ...prev,
            fps: [...prev.fps, {
              value: fps,
              timestamp: new Date().toISOString()
            }].slice(-30) // Keep only the latest 30 data points
          }));
          
          frames = 0;
          lastTime = now;
        }
        
        requestAnimationFrame(calculateFPS);
      };
      
      requestAnimationFrame(calculateFPS);
    };
    
    // Start collecting metrics
    collectMetrics();
    perfInterval.current = setInterval(collectMetrics, 5000);
    
    // Clean up
    return () => {
      if (perfInterval.current) {
        clearInterval(perfInterval.current);
      }
    };
  }, []);
  
  // Toggle section expansion
  const toggleSection = (section) => {
    setExpandedSections(prev => ({
      ...prev,
      [section]: !prev[section]
    }));
  };
  
  // Toggle secrets visibility
  const toggleSecrets = () => {
    setSecretsVisible(!secretsVisible);
  };
  
  // Clear logs
  const clearLogs = () => {
    setLogs([]);
    console.log('Logs cleared');
  };
  
  // Format data for display
  const formatData = (data) => {
    if (!data) return 'No data';
    return JSON.stringify(data, null, 2);
  };
  
  // Mask sensitive data
  const maskSecrets = (text) => {
    if (!text || secretsVisible) return text;
    
    // Replace patterns that look like tokens
    return text.replace(/(["']?token["']?\s*:\s*["'])[^"']+?(["'])/gi, '$1********$2')
               .replace(/(["']?access_token["']?\s*:\s*["'])[^"']+?(["'])/gi, '$1********$2')
               .replace(/(["']?refresh_token["']?\s*:\s*["'])[^"']+?(["'])/gi, '$1********$2')
               .replace(/(["']?api_key["']?\s*:\s*["'])[^"']+?(["'])/gi, '$1********$2')
               .replace(/(Bearer\s+)[^\s"']+/gi, '$1********');
  };
  
  // Prepare chart data for memory usage
  const memoryChartData = {
    labels: performanceMetrics.memory.map((_, i) => i),
    datasets: [
      {
        label: 'Memory Usage (MB)',
        data: performanceMetrics.memory.map(m => m.value),
        borderColor: 'rgba(54, 162, 235, 1)',
        backgroundColor: 'rgba(54, 162, 235, 0.2)',
        tension: 0.4,
        fill: true,
      },
    ],
  };
  
  // Prepare chart data for FPS
  const fpsChartData = {
    labels: performanceMetrics.fps.map((_, i) => i),
    datasets: [
      {
        label: 'FPS',
        data: performanceMetrics.fps.map(f => f.value),
        borderColor: 'rgba(75, 192, 192, 1)',
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        tension: 0.4,
        fill: true,
      },
    ],
  };
  
  // Chart options
  const chartOptions = {
    responsive: true,
    scales: {
      y: {
        beginAtZero: true,
      },
    },
    animation: false,
  };
  
  return (
    <div className={styles.developerTools}>
      <h1 className={styles.heading}>Developer Tools</h1>
      
      {/* Authentication Status Section */}
      <div className={styles.section}>
        <div className={styles.sectionHeader} onClick={() => toggleSection('auth')}>
          <h2>Authentication Status</h2>
          {expandedSections.auth ? <FaChevronUp /> : <FaChevronDown />}
        </div>
        
        {expandedSections.auth && (
          <div className={styles.sectionContent}>
            <div className={styles.statusItem}>
              <h3>Oura</h3>
              <p><strong>Authenticated:</strong> {ouraStatus.isAuthenticated ? 'Yes' : 'No'}</p>
              <p><strong>Needs Refresh:</strong> {ouraStatus.needsRefresh ? 'Yes' : 'No'}</p>
            </div>
            
            <div className={styles.statusItem}>
              <h3>Dexcom</h3>
              <p><strong>Authenticated:</strong> {dexcomStatus.isAuthenticated ? 'Yes' : 'No'}</p>
              <p><strong>Needs Refresh:</strong> {dexcomStatus.needsRefresh ? 'Yes' : 'No'}</p>
              <p><strong>Enabled:</strong> {dexcomStatus.isEnabled ? 'Yes' : 'No'}</p>
            </div>
          </div>
        )}
      </div>
      
      {/* Performance Monitoring Section */}
      <div className={styles.section}>
        <div className={styles.sectionHeader} onClick={() => toggleSection('performance')}>
          <h2><FaMemory /> Performance Metrics</h2>
          {expandedSections.performance ? <FaChevronUp /> : <FaChevronDown />}
        </div>
        
        {expandedSections.performance && (
          <div className={styles.sectionContent}>
            <div className={styles.metricsGrid}>
              <div className={styles.metricCard}>
                <h3>Page Load Times</h3>
                <div className={styles.metricsTable}>
                  <div className={styles.metricRow}>
                    <span>Total Load Time:</span>
                    <span>{performanceMetrics.loadTimes.pageLoad ? `${(performanceMetrics.loadTimes.pageLoad / 1000).toFixed(2)}s` : 'N/A'}</span>
                  </div>
                  <div className={styles.metricRow}>
                    <span>DOM Ready:</span>
                    <span>{performanceMetrics.loadTimes.domReady ? `${(performanceMetrics.loadTimes.domReady / 1000).toFixed(2)}s` : 'N/A'}</span>
                  </div>
                </div>
              </div>
              
              <div className={styles.metricCard}>
                <h3>Memory Usage</h3>
                {performanceMetrics.memory.length > 0 ? (
                  <>
                    <div className={styles.metricValue}>
                      {performanceMetrics.memory[performanceMetrics.memory.length - 1].value} MB
                    </div>
                    <div className={styles.miniChart}>
                      <Line data={memoryChartData} options={chartOptions} height={100} />
                    </div>
                  </>
                ) : (
                  <div className={styles.noData}>No memory data available</div>
                )}
              </div>
              
              <div className={styles.metricCard}>
                <h3>FPS (Frame Rate)</h3>
                {performanceMetrics.fps.length > 0 ? (
                  <>
                    <div className={styles.metricValue}>
                      {performanceMetrics.fps[performanceMetrics.fps.length - 1].value} FPS
                    </div>
                    <div className={styles.miniChart}>
                      <Line data={fpsChartData} options={chartOptions} height={100} />
                    </div>
                  </>
                ) : (
                  <div className={styles.noData}>No FPS data available</div>
                )}
              </div>
              
              <div className={styles.metricCard}>
                <h3>Recent Errors</h3>
                {performanceMetrics.errors.length > 0 ? (
                  <div className={styles.errorsList}>
                    {performanceMetrics.errors.slice(0, 3).map((error, index) => (
                      <div key={index} className={styles.errorItem}>
                        <FaExclamationTriangle className={styles.errorIcon} />
                        <span>{error.message.substring(0, 100)}{error.message.length > 100 ? '...' : ''}</span>
                      </div>
                    ))}
                    {performanceMetrics.errors.length > 3 && (
                      <div className={styles.moreErrors}>
                        +{performanceMetrics.errors.length - 3} more errors
                      </div>
                    )}
                  </div>
                ) : (
                  <div className={styles.noData}>No errors recorded</div>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
      
      {/* Network Monitoring Section */}
      <div className={styles.section}>
        <div className={styles.sectionHeader} onClick={() => toggleSection('network')}>
          <h2><FaNetworkWired /> Network Monitoring</h2>
          {expandedSections.network ? <FaChevronUp /> : <FaChevronDown />}
        </div>
        
        {expandedSections.network && (
          <div className={styles.sectionContent}>
            <div className={styles.networkStats}>
              <div className={`${styles.networkStatCard} ${styles.totalRequests}`}>
                <div className={styles.statValue}>{networkStats.total}</div>
                <div className={styles.statLabel}>Total Requests</div>
              </div>
              
              <div className={`${styles.networkStatCard} ${styles.successfulRequests}`}>
                <div className={styles.statValue}>{networkStats.success}</div>
                <div className={styles.statLabel}>Successful</div>
              </div>
              
              <div className={`${styles.networkStatCard} ${styles.failedRequests}`}>
                <div className={styles.statValue}>{networkStats.failed}</div>
                <div className={styles.statLabel}>Failed</div>
              </div>
              
              <div className={`${styles.networkStatCard} ${styles.avgResponse}`}>
                <div className={styles.statValue}>{networkStats.avgResponseTime.toFixed(0)}ms</div>
                <div className={styles.statLabel}>Avg Response Time</div>
              </div>
            </div>
            
            <div className={styles.networkTable}>
              <div className={styles.networkTableHeader}>
                <div className={styles.method}>Method</div>
                <div className={styles.url}>URL</div>
                <div className={styles.status}>Status</div>
                <div className={styles.duration}>Duration</div>
              </div>
              
              {networkRequests.length > 0 ? (
                networkRequests.slice(0, 10).map((request, index) => (
                  <div 
                    key={index} 
                    className={`${styles.networkTableRow} ${
                      request.status === 'success' ? styles.success :
                      request.status === 'error' ? styles.error :
                      request.status === 'failed' ? styles.failed :
                      styles.pending
                    }`}
                  >
                    <div className={styles.method}>{request.method}</div>
                    <div className={styles.url} title={request.url}>
                      {request.url.substring(request.url.lastIndexOf('/') + 1) || request.url}
                    </div>
                    <div className={styles.status}>
                      {request.status === 'pending' ? (
                        <FaSpinner className={styles.spinnerIcon} />
                      ) : request.status === 'success' ? (
                        request.statusCode
                      ) : (
                        request.error || 'Error'
                      )}
                    </div>
                    <div className={styles.duration}>
                      {request.duration ? `${request.duration.toFixed(0)}ms` : '-'}
                    </div>
                  </div>
                ))
              ) : (
                <div className={styles.noData}>No network requests recorded yet</div>
              )}
            </div>
          </div>
        )}
      </div>
      
      {/* Data Overview Section */}
      <div className={styles.section}>
        <div className={styles.sectionHeader} onClick={() => toggleSection('data')}>
          <h2>Data Overview</h2>
          {expandedSections.data ? <FaChevronUp /> : <FaChevronDown />}
        </div>
        
        {expandedSections.data && (
          <div className={styles.sectionContent}>
            <div className={styles.dataControls}>
              <button 
                className={styles.toggleButton}
                onClick={toggleSecrets}
                title={secretsVisible ? "Hide sensitive data" : "Show sensitive data"}
              >
                {secretsVisible ? <FaEyeSlash /> : <FaEye />}
                {secretsVisible ? "Hide Secrets" : "Show Secrets"}
              </button>
            </div>
            
            <div className={styles.dataBlock}>
              <h3>Dashboard Summary</h3>
              <pre>{maskSecrets(formatData(dashboardSummary))}</pre>
            </div>
            
            <div className={styles.dataBlock}>
              <h3>Wellness Scores</h3>
              <pre>{maskSecrets(formatData(wellnessScores))}</pre>
            </div>
            
            <div className={styles.dataBlock}>
              <h3>Oura Data</h3>
              <pre>{maskSecrets(formatData(ouraData))}</pre>
            </div>
            
            {dexcomStatus.isEnabled && (
              <div className={styles.dataBlock}>
                <h3>Dexcom Data</h3>
                <pre>{maskSecrets(formatData(dexcomData))}</pre>
              </div>
            )}
            
            <div className={styles.dataBlock}>
              <h3>Journal Entries</h3>
              <pre>{maskSecrets(formatData(journalEntries))}</pre>
            </div>
            
            <div className={styles.dataBlock}>
              <h3>Recommendations</h3>
              <pre>{maskSecrets(formatData(recommendations))}</pre>
            </div>
            
            <div className={styles.dataBlock}>
              <h3>Chat History</h3>
              <pre>{maskSecrets(formatData(chatHistory))}</pre>
            </div>
          </div>
        )}
      </div>
      
      {/* Logs Section */}
      <div className={styles.section}>
        <div className={styles.sectionHeader} onClick={() => toggleSection('logs')}>
          <h2>Logs</h2>
          {expandedSections.logs ? <FaChevronUp /> : <FaChevronDown />}
        </div>
        
        {expandedSections.logs && (
          <div className={styles.sectionContent}>
            <div className={styles.logControls}>
              <button className={styles.clearButton} onClick={clearLogs}>
                Clear Logs
              </button>
              <button 
                className={styles.toggleButton}
                onClick={toggleSecrets}
              >
                {secretsVisible ? <FaEyeSlash /> : <FaEye />}
                {secretsVisible ? "Hide Secrets" : "Show Secrets"}
              </button>
            </div>
            
            <div className={styles.logs}>
              {logs.length === 0 ? (
                <p className={styles.emptyState}>No logs yet</p>
              ) : (
                logs.map((log, index) => (
                  <div key={index} className={`${styles.logEntry} ${styles[log.type]}`}>
                    <span className={styles.logTime}>
                      {new Date(log.timestamp).toLocaleTimeString()}
                    </span>
                    <span className={styles.logType}>{log.type}</span>
                    <span className={styles.logMessage}>
                      {maskSecrets(log.message)}
                    </span>
                  </div>
                ))
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default DeveloperTools; 