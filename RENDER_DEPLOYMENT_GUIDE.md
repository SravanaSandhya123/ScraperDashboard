# 🚀 **Complete Render Deployment Guide for Lavangam Project**

## 📋 **Project Overview**

Your **Lavangam** project consists of:
- **Frontend**: React + Vite (TypeScript) - Static Site
- **Backend**: Python FastAPI with multiple services - Web Service
- **Database**: MySQL (needs external service)
- **Services**: Main API, Dashboard, Analytics, Admin Metrics
- **🔧 Special Feature**: **Edge WebDriver Support** for web scraping

---

## 🌐 **Frontend Deployment (Static Site)**

### **Step 1: Create Render Static Site**

1. **Go to Render Dashboard**: https://dashboard.render.com
2. **Click "New +"** → **"Static Site"**
3. **Connect your Git repository**
4. **Configure the service**:

```bash
# Build Command
npm run build

# Publish Directory
dist

# Environment Variables (if needed)
NODE_ENV=production
```

### **Step 2: Update Frontend Configuration**

Your frontend is already configured to detect Render domains. Update the API URLs in `src/config/api.ts`:

```typescript
// Replace with your actual Render backend URL
MAIN_API: window.location.hostname === 'localhost' 
  ? 'http://44.244.35.65:8000'
  : window.location.hostname.includes('render.com')
  ? 'https://your-backend-service.onrender.com'  // ← Your backend URL
  : 'http://18.236.173.88:8000'
```

### **Step 3: Deploy Frontend**

- **Branch**: `main` or `master`
- **Auto-deploy**: ✅ Enabled
- **Build**: Automatic on push

---

## 🐍 **Backend Deployment (Web Service) - WITH WEBDIVER SUPPORT**

### **Step 1: Create Render Web Service**

1. **Go to Render Dashboard** → **"New +"** → **"Web Service"**
2. **Connect your Git repository**
3. **Configure the service**:

```bash
# Build Command
chmod +x build.sh && ./build.sh

# Start Command
python render.py

# Environment Variables (set these in Render dashboard)
DB_HOST=18.236.173.88
DB_PORT=3306
DB_NAME=toolinfomation
DB_USER=root
DB_PASSWORD=thanuja
SUPABASE_URL=https://zjfjaezztfydiryzfd.supabase.co
SUPABASE_KEY=your_supabase_key
RENDER_ENVIRONMENT=production
```

### **Step 2: WebDriver Configuration**

**✅ Your Edge WebDriver functionality WILL work on Render!**

The build script automatically:
- **Downloads Linux-compatible Edge WebDriver**
- **Downloads Linux-compatible Chrome WebDriver**
- **Installs all necessary system dependencies**
- **Configures headless mode for cloud environment**

### **Step 3: Database Setup**

**Use your existing AWS MySQL** (keep current setup):
- **DB_HOST**: `18.236.173.88` (your AWS IP)
- **DB_PORT**: `3306`
- **DB_NAME**: `toolinfomation`
- **DB_USER**: `root`
- **DB_PASSWORD**: `thanuja`

---

## 🔧 **Render Configuration Files**

### **Backend Entry Point: `render.py`**
- Consolidates all services under one domain
- **Includes WebDriver support** for scraping
- Handles CORS for Render
- Provides health checks and WebDriver testing

### **WebDriver Manager: `webdriver_manager.py`**
- **Automatically downloads Linux drivers** for Render
- **Manages Edge and Chrome WebDrivers**
- **Configures headless mode** for cloud environment
- **Falls back to local drivers** for development

### **Build Script: `build.sh`**
- **Installs system dependencies** for WebDriver
- **Downloads latest Linux drivers**
- **Tests WebDriver functionality**
- **Ensures everything works** before deployment

### **Requirements: `requirements-render.txt`**
- **Includes Selenium and WebDriver support**
- **Optimized for Render deployment**
- **FastAPI-focused stack**

---

## 🌍 **Service Architecture on Render**

### **Before (Multiple Ports):**
```
http://44.244.35.65:8000  → Main API
http://44.244.35.65:5022  → Scrapers API
http://44.244.35.65:8004  → Dashboard API
http://44.244.35.65:5025  → Admin Metrics
```

### **After (Render - Single Domain + WebDriver):**
```
https://your-backend.onrender.com/main      → Main API
https://your-backend.onrender.com/dashboard → Dashboard API
https://your-backend.onrender.com/admin     → Admin Metrics
https://your-backend.onrender.com/analytics → Analytics API
https://your-backend.onrender.com/test-webdriver → WebDriver Test
```

---

## 🔧 **WebDriver Features on Render**

### **✅ What Works:**
- **Edge WebDriver**: Full support with Linux drivers
- **Chrome WebDriver**: Full support with Linux drivers
- **Web Scraping**: All your scraping functionality
- **Open Edge Function**: Your `/api/open-edge` endpoint
- **Headless Mode**: Optimized for cloud environment

### **🔧 How It Works:**
1. **Build script downloads** Linux-compatible drivers
2. **WebDriver Manager** automatically manages drivers
3. **Headless mode** runs browsers without GUI
4. **All your scraping functions** work exactly the same

---

## 📱 **Frontend-Backend Integration**

### **Automatic Detection:**
Your frontend automatically detects the environment:
- **Localhost**: Uses local ports
- **Render**: Uses Render backend URLs
- **AWS**: Uses AWS IP addresses

### **API Calls:**
```typescript
// Frontend automatically routes to correct backend
const apiUrl = API_CONFIG.MAIN_API; // Adapts to environment
const response = await fetch(`${apiUrl}/health`);
```

---

## 🚀 **Deployment Steps Summary**

### **1. Frontend (Static Site)**
```bash
# 1. Create Render Static Site
# 2. Connect Git repository
# 3. Set build command: npm run build
# 4. Set publish directory: dist
# 5. Deploy
```

### **2. Backend (Web Service) - WITH WEBDIVER**
```bash
# 1. Create Render Web Service
# 2. Connect Git repository
# 3. Set build command: chmod +x build.sh && ./build.sh
# 4. Set start command: python render.py
# 5. Configure environment variables
# 6. Deploy (WebDrivers will be installed automatically)
```

### **3. Database**
```bash
# 1. Use existing AWS MySQL (18.236.173.88)
# 2. Set environment variables in Render
# 3. Test connection
```

### **4. Update URLs**
```bash
# 1. Get your Render service URLs
# 2. Update frontend config/api.ts
# 3. Test WebDriver functionality
# 4. Verify all scraping features work
```

---

## 🔍 **Testing Your Render Deployment**

### **Frontend Test:**
```bash
# Visit your frontend URL
https://your-frontend-service.onrender.com

# Check if it loads correctly
# Verify API calls work
```

### **Backend Test:**
```bash
# Health check
curl https://your-backend-service.onrender.com/health

# Root endpoint
curl https://your-backend-service.onrender.com/

# WebDriver test
curl https://your-backend-service.onrender.com/test-webdriver

# WebDriver status
curl https://your-backend-service.onrender.com/webdriver-status
```

### **WebDriver Test:**
```bash
# Test Edge WebDriver functionality
curl -X POST https://your-backend-service.onrender.com/main/api/open-edge \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.google.com"}'
```

---

## 💰 **Render Pricing & Limits**

### **Free Tier:**
- **Static Sites**: Unlimited
- **Web Services**: 750 hours/month
- **WebDriver Support**: ✅ Included

### **Paid Plans:**
- **Web Services**: $7/month (unlimited)
- **WebDriver Support**: ✅ Included

---

## 🎯 **Benefits of Render Deployment**

1. **🌍 Global CDN**: Fast loading worldwide
2. **🔌 No Port Management**: Single domain for all services
3. **📱 Mobile Friendly**: Works on all devices
4. **⚡ Auto-deploy**: Updates on Git push
5. **🛡️ HTTPS**: Automatic SSL certificates
6. **📊 Monitoring**: Built-in performance tracking
7. **💰 Cost Effective**: Free tier available
8. **🔧 WebDriver Support**: Your scraping functionality works!

---

## 🚨 **Important Notes**

### **WebDriver on Render:**
- **✅ Edge WebDriver**: Fully supported
- **✅ Chrome WebDriver**: Fully supported
- **✅ Web Scraping**: All functionality preserved
- **✅ Headless Mode**: Optimized for cloud
- **⚠️ GUI Mode**: Not available (headless only)

### **Recommendations:**
- **Start with free tier** to test
- **Use existing AWS MySQL** for simplicity
- **Test WebDriver functionality** after deployment
- **Monitor Render logs** for any issues

---

## 🎉 **Next Steps**

1. **✅ Create Render account**
2. **🔧 Set up frontend static site**
3. **🐍 Set up backend web service (with WebDriver)**
4. **🗄️ Configure database (use AWS MySQL)**
5. **🔗 Update service URLs**
6. **🧪 Test WebDriver functionality**
7. **🚀 Go live with full scraping support!**

---

## 📞 **Support & Troubleshooting**

### **Common Issues:**
- **Build failures**: Check build script permissions
- **WebDriver errors**: Check system dependencies
- **Database connection**: Verify environment variables
- **CORS errors**: Check CORS configuration

### **WebDriver Issues:**
- **Driver not found**: Check build script execution
- **Headless mode**: Verify browser options
- **System dependencies**: Ensure all packages installed

### **Render Resources:**
- **Documentation**: https://render.com/docs
- **Community**: https://community.render.com
- **Status**: https://status.render.com

---

## 🎯 **Your Edge WebDriver Functionality on Render**

### **✅ What You Keep:**
- **All scraping functions** work exactly the same
- **Open Edge functionality** (`/api/open-edge`)
- **WebDriver automation** for tender scraping
- **Captcha handling** and form submission
- **Data extraction** and processing

### **🔧 What Changes:**
- **Windows drivers** → **Linux drivers** (automatic)
- **GUI mode** → **Headless mode** (cloud optimized)
- **Local paths** → **Automatic download** (webdriver-manager)

---

**Your Lavangam project with Edge WebDriver support is now ready for Render deployment! 🚀🔧**

**Questions?** Check the troubleshooting section or Render documentation.
