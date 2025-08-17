// Centralized API configuration for Lavangam Consolidated Backend
export const API_CONFIG = {
  // Main consolidated API base URL
  MAIN_API: window.location.hostname === 'localhost' 
    ? 'http://localhost:8000'
    : 'https://lavangam-backend.onrender.com',
  
  // All services now consolidated under one backend
  SYSTEM_API: window.location.hostname === 'localhost' 
    ? 'http://localhost:8000'
    : 'https://lavangam-backend.onrender.com',
  
  // Dashboard API (consolidated)
  DASHBOARD_API: window.location.hostname === 'localhost' 
    ? 'http://localhost:8000'
    : 'https://lavangam-backend.onrender.com',
  
  // WebSocket URLs (consolidated)
  WS_MAIN: window.location.hostname === 'localhost'
    ? 'ws://localhost:8000'
    : 'wss://lavangam-backend.onrender.com',
  
  WS_DASHBOARD: window.location.hostname === 'localhost'
    ? 'ws://localhost:8000'
    : 'wss://lavangam-backend.onrender.com'
};

// Environment variable configuration
export const ENV_CONFIG = {
  // API Keys (these will be set in Render environment variables)
  OPENAI_API_KEY: import.meta.env.VITE_OPENAI_API_KEY,
  GROQ_API_KEY: import.meta.env.VITE_GROQ_API_KEY,
  SUPABASE_URL: import.meta.env.VITE_SUPABASE_URL,
  SUPABASE_KEY: import.meta.env.VITE_SUPABASE_KEY,
  
  // Backend URL (consolidated)
  BACKEND_URL: 'https://lavangam-backend.onrender.com',
  
  // Environment detection
  IS_PRODUCTION: import.meta.env.PROD,
  IS_DEVELOPMENT: import.meta.env.DEV,
  IS_RENDER: window.location.hostname.includes('render.com')
};

// Helper function to get API URL for different services (all consolidated)
export const getApiUrl = (service: 'main' | 'system' | 'dashboard' = 'main') => {
  // All services now use the same consolidated backend
  return API_CONFIG.MAIN_API;
};

// Helper function to get WebSocket URL (consolidated)
export const getWsUrl = (service: 'main' | 'dashboard' = 'main') => {
  // All WebSocket connections now use the same consolidated backend
  return API_CONFIG.WS_MAIN;
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
    isConfigured: true // Always configured now with consolidated backend
  };
}; 