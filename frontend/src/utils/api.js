import axios from 'axios';

// Create axios instance with default config
const api = axios.create({
  baseURL: '/',
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Initialize cache
const cache = {
  data: {},
  timestamp: {},
  maxAge: {}
};

// Default cache maxAge (in milliseconds)
const DEFAULT_CACHE_MAX_AGE = 60 * 1000; // 1 minute

/**
 * Get data from cache if valid, otherwise fetch from server
 * 
 * @param {string} url The URL to fetch
 * @param {object} options Request options including caching controls
 * @returns {Promise} Promise that resolves with the response data
 */
const cachedGet = async (url, options = {}) => {
  const {
    params = {},
    maxAge = DEFAULT_CACHE_MAX_AGE,
    bypassCache = false,
    onSuccess = null,
    onError = null
  } = options;
  
  // Create a cache key based on URL and params
  const queryParams = params ? JSON.stringify(params) : '';
  const cacheKey = `${url}:${queryParams}`;
  
  // Check if we have a valid cached response
  const now = Date.now();
  if (
    !bypassCache &&
    cache.data[cacheKey] &&
    cache.timestamp[cacheKey] &&
    now - cache.timestamp[cacheKey] < (cache.maxAge[cacheKey] || maxAge)
  ) {
    return cache.data[cacheKey];
  }
  
  // Otherwise, make a new request
  try {
    const response = await api.get(url, { params });
    
    // Cache the response
    cache.data[cacheKey] = response.data;
    cache.timestamp[cacheKey] = now;
    cache.maxAge[cacheKey] = maxAge;
    
    // Call success callback if provided
    if (onSuccess) {
      onSuccess(response.data);
    }
    
    return response.data;
  } catch (error) {
    // Call error callback if provided
    if (onError) {
      onError(error);
    }
    
    throw error;
  }
};

/**
 * Clear cache for a specific URL or all cache if URL not provided
 * 
 * @param {string} url Optional URL to clear from cache
 */
const clearCache = (url = null) => {
  if (url) {
    // Clear cache for a specific URL pattern
    Object.keys(cache.data).forEach(key => {
      if (key.startsWith(`${url}:`)) {
        delete cache.data[key];
        delete cache.timestamp[key];
        delete cache.maxAge[key];
      }
    });
  } else {
    // Clear all cache
    cache.data = {};
    cache.timestamp = {};
    cache.maxAge = {};
  }
};

// Add request interceptor for authentication
api.interceptors.request.use(
  config => {
    // Get the token from localStorage
    const token = localStorage.getItem('authToken');
    
    // If token exists, add to header
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    return config;
  },
  error => {
    return Promise.reject(error);
  }
);

// Add response interceptor for error handling
api.interceptors.response.use(
  response => {
    return response;
  },
  error => {
    // Handle 401 Unauthorized errors
    if (error.response && error.response.status === 401) {
      // Clear token and redirect to login page
      localStorage.removeItem('authToken');
      window.location.href = '/';
    }
    
    return Promise.reject(error);
  }
);

// Export enhanced API with caching
export default {
  get: api.get,
  post: api.post,
  put: api.put,
  delete: api.delete,
  patch: api.patch,
  cachedGet,
  clearCache
}; 