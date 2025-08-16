# 🔐 Frontend Environment Variables Template

## 📝 **Copy these variables to Render Dashboard**

**⚠️ NEVER commit actual API keys to Git!**

### **Frontend Environment Variables (Render Dashboard)**

```bash
# Backend URL (set this after deploying backend on Render)
VITE_BACKEND_URL=https://your-backend-service.onrender.com

# OpenAI API Key (for AI Assistant)
VITE_OPENAI_API_KEY=sk-your-openai-api-key-here

# GROQ API Key (for AI Assistant)
VITE_GROQ_API_KEY=gsk-your-groq-api-key-here

# Supabase Configuration
VITE_SUPABASE_URL=https://zjfjaezztfydiryzfd.supabase.co
VITE_SUPABASE_KEY=your-supabase-anon-key-here
```

### **Backend Environment Variables (Render Dashboard)**

```bash
# Database Configuration (Your AWS MySQL)
DB_HOST=18.236.173.88
DB_PORT=3306
DB_NAME=toolinfomation
DB_USER=root
DB_PASSWORD=thanuja

# Supabase Configuration
SUPABASE_URL=https://zjfjaezztfydiryzfd.supabase.co
SUPABASE_KEY=your-supabase-service-role-key-here

# OpenAI API Key (for AI Assistant)
OPENAI_API_KEY=sk-your-openai-api-key-here

# Render Environment
RENDER_ENVIRONMENT=production
```

## 🚨 **Security Notes**

1. **Frontend Variables** (`VITE_*`): These are exposed to the browser
2. **Backend Variables**: These are server-side only and secure
3. **Never commit** `.env` files to Git
4. **Use Render Dashboard** to set environment variables
5. **Test API calls** after setting variables

## 🔧 **How to Set in Render**

1. **Frontend (Static Site)**: Environment Variables section
2. **Backend (Web Service)**: Environment Variables section
3. **Click "+ Add Environment Variable"** for each variable
4. **Save and redeploy** after adding variables
