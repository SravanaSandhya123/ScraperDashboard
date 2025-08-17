import React from 'react';
import { Link, useLocation } from 'react-router-dom';

export const SimpleNav: React.FC = () => {
  const location = useLocation();

  const navItems = [
    { path: '/', label: '🏠 Home', description: 'Main landing page' },
    { path: '/auth', label: '🔐 Auth', description: 'Authentication page' },
    { path: '/dashboard', label: '📊 Dashboard', description: 'Main dashboard' },
    { path: '/backend-test', label: '🔗 Backend Test', description: 'Test backend connection' },
  ];

  return (
    <nav className="bg-gray-800 text-white p-4">
      <div className="max-w-6xl mx-auto">
        <div className="flex flex-wrap items-center justify-between">
          <div className="text-xl font-bold text-blue-400">
            🚀 Lavangam Frontend
          </div>
          
          <div className="flex flex-wrap gap-4">
            {navItems.map((item) => (
              <Link
                key={item.path}
                to={item.path}
                className={`px-4 py-2 rounded-lg transition-colors ${
                  location.pathname === item.path
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-700 hover:bg-gray-600 text-gray-200'
                }`}
                title={item.description}
              >
                {item.label}
              </Link>
            ))}
          </div>
        </div>
        
        {/* Current page indicator */}
        <div className="mt-4 text-sm text-gray-400">
          Current page: <span className="text-blue-400">{location.pathname}</span>
        </div>
      </div>
    </nav>
  );
};
