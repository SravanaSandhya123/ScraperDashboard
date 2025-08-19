// Centralized API configuration for Lavangam multi-port backend (AWS)
const PROD_HOST = '44.244.35.65'; // AWS EC2 public IP

// Force all API calls to use the EC2 public IP and ports
const httpUrl = (port: number) => `http://${PROD_HOST}:${port}`;
const wsUrl = (port: number, path: string = '') => `ws://${PROD_HOST}:${port}${path}`;

export const API_CONFIG = {
  // Core HTTP APIs
  MAIN_API: httpUrl(8000),
  SYSTEM_API: httpUrl(5024),
  DASHBOARD_API: httpUrl(8004),
  ANALYTICS_API: httpUrl(8001),
  ADMIN_METRICS_API: httpUrl(8001),
  ADDITIONAL_ANALYTICS_API: httpUrl(8002),
  FILE_MANAGER_API: httpUrl(5002),
  SCRAPERS_API: httpUrl(5022),
  SCRAPER_HTTP_API: httpUrl(5003),
  EPROC_API: httpUrl(5021), // E-Proc server (used by eproc tool)

  // WebSocket/Sockets bases
  WS_MAIN: wsUrl(8000),
  WS_DASHBOARD: wsUrl(8002),
  // Socket.IO for GEM scraper service (uses HTTP base)
  SCRAPER_SOCKET: httpUrl(5003),
  // Native WS endpoint for scrapers live logs
  SCRAPERS_WS_LOG: wsUrl(5022, '/ws/logs')
};

// Environment variable configuration
export const ENV_CONFIG = {
  // API Keys (these will be set in Render environment variables)
  OPENAI_API_KEY: import.meta.env.VITE_OPENAI_API_KEY,
  GROQ_API_KEY: import.meta.env.VITE_GROQ_API_KEY,
  SUPABASE_URL: import.meta.env.VITE_SUPABASE_URL,
  SUPABASE_KEY: import.meta.env.VITE_SUPABASE_KEY,
  
  // Backend URL (consolidated)
  BACKEND_URL: httpUrl(8000),
  
  // Environment detection
  IS_PRODUCTION: import.meta.env.PROD,
  IS_DEVELOPMENT: import.meta.env.DEV,
  IS_RENDER: window.location.hostname.includes('render.com')
};

// Helper function to get API URL for different services
export const getApiUrl = (
  service: 'main' | 'system' | 'dashboard' | 'analytics' | 'admin' | 'fileManager' | 'scrapers' | 'eproc' = 'main'
) => {
  switch (service) {
    case 'system': return API_CONFIG.SYSTEM_API;
    case 'dashboard': return API_CONFIG.DASHBOARD_API;
    case 'analytics': return API_CONFIG.ANALYTICS_API;
    case 'admin': return API_CONFIG.ADMIN_METRICS_API;
    case 'fileManager': return API_CONFIG.FILE_MANAGER_API;
    case 'scrapers': return API_CONFIG.SCRAPERS_API;
    case 'eproc': return API_CONFIG.EPROC_API;
    case 'main':
    default:
      return API_CONFIG.MAIN_API;
  }
};

// Helper function to get WebSocket/Socket base URL
export const getWsUrl = (
  service: 'main' | 'dashboard' | 'scraper' | 'scrapersLog' = 'main'
) => {
  switch (service) {
    case 'dashboard': return API_CONFIG.WS_DASHBOARD;
    case 'scraper': return API_CONFIG.SCRAPER_SOCKET; // Socket.IO base (http)
    case 'scrapersLog': return API_CONFIG.SCRAPERS_WS_LOG; // native ws
    case 'main':
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
    isConfigured: true // Always configured now with consolidated backend
  };
}; 