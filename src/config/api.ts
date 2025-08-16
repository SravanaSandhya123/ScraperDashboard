// Centralized API configuration with environment variable support
export const API_CONFIG = {
  // Main API base URL - Updated to use AWS EC2 instance or Render
  MAIN_API: window.location.hostname === 'localhost' 
    ? 'http://localhost:8000'
    : window.location.hostname.includes('render.com')
    ? import.meta.env.VITE_BACKEND_URL || 'https://your-backend-service.onrender.com'  // Use environment variable
    : 'http://18.236.173.88:8000',
  
  // System metrics API
  SYSTEM_API: window.location.hostname === 'localhost' 
    ? 'http://localhost:8001'
    : window.location.hostname.includes('render.com')
    ? import.meta.env.VITE_BACKEND_URL || 'https://your-backend-service.onrender.com'  // Use environment variable
    : 'http://18.236.173.88:8001',
  
  // Dashboard API
  DASHBOARD_API: window.location.hostname === 'localhost' 
    ? 'http://localhost:8004'
    : window.location.hostname.includes('render.com')
    ? import.meta.env.VITE_BACKEND_URL || 'https://your-backend-service.onrender.com'  // Use environment variable
    : 'http://18.236.173.88:8004',
  
  // WebSocket URLs
  WS_MAIN: window.location.hostname === 'localhost'
    ? 'ws://localhost:8002'
    : window.location.hostname.includes('render.com')
    ? (import.meta.env.VITE_BACKEND_URL || 'https://your-backend-service.onrender.com').replace('https://', 'wss://')  // Convert to WSS
    : 'ws://18.236.173.88:8002',
  
  WS_DASHBOARD: window.location.hostname === 'localhost'
    ? 'ws://localhost:8002'
    : window.location.hostname.includes('render.com')
    ? (import.meta.env.VITE_BACKEND_URL || 'https://your-backend-service.onrender.com').replace('https://', 'wss://')  // Convert to WSS
    : 'ws://18.236.173.88:8002'
};

// Environment variable configuration
export const ENV_CONFIG = {
  // API Keys (these will be set in Render environment variables)
  OPENAI_API_KEY: import.meta.env.VITE_OPENAI_API_KEY,
  GROQ_API_KEY: import.meta.env.VITE_GROQ_API_KEY,
  SUPABASE_URL: import.meta.env.VITE_SUPABASE_URL,
  SUPABASE_KEY: import.meta.env.VITE_SUPABASE_KEY,
  
  // Backend URL (set this in Render)
  BACKEND_URL: import.meta.env.VITE_BACKEND_URL,
  
  // Environment detection
  IS_PRODUCTION: import.meta.env.PROD,
  IS_DEVELOPMENT: import.meta.env.DEV,
  IS_RENDER: window.location.hostname.includes('render.com')
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

// Helper function to check if API keys are available
export const checkApiKeys = () => {
  const missingKeys = [];
  
  if (!ENV_CONFIG.OPENAI_API_KEY) missingKeys.push('VITE_OPENAI_API_KEY');
  if (!ENV_CONFIG.GROQ_API_KEY) missingKeys.push('VITE_GROQ_API_KEY');
  if (!ENV_CONFIG.SUPABASE_URL) missingKeys.push('VITE_SUPABASE_URL');
  if (!ENV_CONFIG.SUPABASE_KEY) missingKeys.push('VITE_SUPABASE_KEY');
  
  return {
    hasAllKeys: missingKeys.length === 0,
    missingKeys,
    isConfigured: ENV_CONFIG.IS_RENDER ? !!ENV_CONFIG.BACKEND_URL : true
  };
}; 