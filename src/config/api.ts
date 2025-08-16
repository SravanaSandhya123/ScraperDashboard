// Centralized API configuration
export const API_CONFIG = {
  // Main API base URL - Updated to use AWS EC2 instance or Render
  MAIN_API: window.location.hostname === 'localhost' 
    ? 'http://localhost:8000'
    : window.location.hostname.includes('render.com')
    ? 'https://your-backend-service.onrender.com'  // Replace with your Render backend URL
    : 'http://18.236.173.88:8000',
  
  // System metrics API
  SYSTEM_API: window.location.hostname === 'localhost' 
    ? 'http://localhost:8001'
    : window.location.hostname.includes('render.com')
    ? 'https://your-backend-service.onrender.com'  // Replace with your Render backend URL
    : 'http://18.236.173.88:8001',
  
  // Dashboard API
  DASHBOARD_API: window.location.hostname === 'localhost' 
    ? 'http://localhost:8004'
    : window.location.hostname.includes('render.com')
    ? 'https://your-backend-service.onrender.com'  // Replace with your Render backend URL
    : 'http://18.236.173.88:8004',
  
  // WebSocket URLs
  WS_MAIN: window.location.hostname === 'localhost'
    ? 'ws://localhost:8002'
    : window.location.hostname.includes('render.com')
    ? 'wss://your-backend-service.onrender.com'  // Replace with your Render backend URL
    : 'ws://18.236.173.88:8002',
  
  WS_DASHBOARD: window.location.hostname === 'localhost'
    ? 'ws://localhost:8002'
    : window.location.hostname.includes('render.com')
    ? 'wss://your-backend-service.onrender.com'  // Replace with your Render backend URL
    : 'ws://18.236.173.88:8002'
};

// Helper function to get API URL for different services
export const getApiUrl = (service: 'main' | 'system' | 'dashboard' = 'main') => {
  switch (service) {
    case 'system':
      return API_CONFIG.SYSTEM_API;
    case 'dashboard':
      return API_CONFIG.DASHBOARD_API;
    default:
      return API_CONFIG.MAIN_API;
  }
};

// Helper function to get WebSocket URL
export const getWsUrl = (service: 'main' | 'dashboard' = 'main') => {
  switch (service) {
    case 'dashboard':
      return API_CONFIG.WS_DASHBOARD;
    default:
      return API_CONFIG.WS_MAIN;
  }
}; 