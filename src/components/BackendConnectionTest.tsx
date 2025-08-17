import React, { useState, useEffect } from 'react';
import { getApiUrl } from '../config/api';

interface ServiceStatus {
  service: string;
  status: string;
  port_equivalent: string;
  timestamp: string;
}

interface BackendStatus {
  consolidated_backend: boolean;
  main_port: string;
  services: Record<string, ServiceStatus>;
  timestamp: string;
}

export const BackendConnectionTest: React.FC = () => {
  const [backendStatus, setBackendStatus] = useState<BackendStatus | null>(null);
  const [healthStatus, setHealthStatus] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const backendUrl = getApiUrl();

  useEffect(() => {
    testBackendConnection();
  }, []);

  const testBackendConnection = async () => {
    setIsLoading(true);
    setError(null);

    try {
      // Test 1: Health check
      console.log('Testing health endpoint...');
      const healthResponse = await fetch(`${backendUrl}/health`);
      const healthData = await healthResponse.json();
      setHealthStatus(healthData);
      console.log('Health check result:', healthData);

      // Test 2: Service status
      console.log('Testing service status endpoint...');
      const statusResponse = await fetch(`${backendUrl}/services/status`);
      const statusData = await statusResponse.json();
      setBackendStatus(statusData);
      console.log('Service status result:', statusData);

    } catch (err) {
      console.error('Backend connection test failed:', err);
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-white text-lg">Testing backend connection...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <div className="text-red-500 text-xl mb-4">❌ Backend Connection Failed</div>
          <div className="text-gray-300 mb-4">Error: {error}</div>
          <div className="text-gray-400 mb-4">Backend URL: {backendUrl}</div>
          <button
            onClick={testBackendConnection}
            className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded"
          >
            Retry Connection
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900 text-white p-8">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-3xl font-bold mb-8 text-center">
          🚀 Lavangam Backend Connection Status
        </h1>

        {/* Health Status */}
        {healthStatus && (
          <div className="bg-green-900 border border-green-600 rounded-lg p-6 mb-8">
            <h2 className="text-2xl font-semibold mb-4 text-green-300">
              ✅ Backend Health Check
            </h2>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <span className="text-gray-300">Status:</span>
                <div className="text-green-400 font-semibold">{healthStatus.status}</div>
              </div>
              <div>
                <span className="text-gray-300">Service:</span>
                <div className="text-green-400 font-semibold">{healthStatus.service}</div>
              </div>
              <div>
                <span className="text-gray-300">Environment:</span>
                <div className="text-green-400 font-semibold">{healthStatus.environment}</div>
              </div>
              <div>
                <span className="text-gray-300">Port:</span>
                <div className="text-green-400 font-semibold">{healthStatus.port}</div>
              </div>
            </div>
          </div>
        )}

        {/* Service Status */}
        {backendStatus && (
          <div className="bg-blue-900 border border-blue-600 rounded-lg p-6">
            <h2 className="text-2xl font-semibold mb-4 text-blue-300">
              🌐 Consolidated Services Status
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {Object.entries(backendStatus.services).map(([serviceName, service]) => (
                <div key={serviceName} className="bg-gray-800 rounded-lg p-4">
                  <div className="text-lg font-semibold text-blue-300 mb-2">
                    {serviceName.replace(/_/g, ' ').toUpperCase()}
                  </div>
                  <div className="text-sm text-gray-300">
                    <div>Status: <span className="text-green-400">{service.status}</span></div>
                    <div>Port Equivalent: <span className="text-blue-400">{service.port_equivalent}</span></div>
                    <div>URL: <span className="text-purple-400">/{serviceName.replace(/_/g, '-')}/</span></div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Connection Info */}
        <div className="mt-8 text-center">
          <div className="text-gray-400 mb-4">
            Backend URL: <span className="text-blue-400">{backendUrl}</span>
          </div>
          <button
            onClick={testBackendConnection}
            className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg text-lg"
          >
            🔄 Refresh Status
          </button>
        </div>
      </div>
    </div>
  );
};
