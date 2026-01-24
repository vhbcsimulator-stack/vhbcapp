# VHBC API Server - Deployment Guide

This guide will walk you through deploying your secure API server to Render.

## 📋 Prerequisites

- [ ] GitHub account
- [ ] Render account (free at https://render.com)
- [ ] Your Gemini API key ready
- [ ] Git installed on your computer

## 🚀 Step-by-Step Deployment

### Step 1: Prepare Your Repository

1. **Initialize Git** (if not already done):
```bash
git init
git add .
git commit -m "Add secure API server"
```

2. **Create a GitHub repository**:
   - Go to https://github.com/new
   - Name it: `vhbc-intelliapp` (or your preferred name)
   - Don't initialize with README (you already have files)
   - Click "Create repository"

3. **Push to GitHub**:
```bash
git remote add origin https://github.com/YOUR_USERNAME/vhbc-intelliapp.git
git branch -M main
git push -u origin main
```

### Step 2: Deploy to Render

#### Option A: Using Render Dashboard (Easiest)

1. **Sign up/Login to Render**:
   - Go to https://render.com
   - Sign up with GitHub (recommended)

2. **Create New Web Service**:
   - Click "New +" button
   - Select "Web Service"
   - Click "Connect account" to link GitHub
   - Find and select your `vhbc-intelliapp` repository

3. **Configure Service**:
   Fill in these settings:
   
   - **Name**: `vhbc-api-server`
   - **Region**: `Singapore` (or closest to your users)
   - **Branch**: `main`
   - **Root Directory**: `server`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Instance Type**: `Free`

4. **Add Environment Variables**:
   Click "Advanced" → "Add Environment Variable"
   
   Add these variables:
   
   | Key | Value |
   |-----|-------|
   | `GEMINI_API_KEY` | `AIzaSyAS3bB2x8Zr4893l18XMkz2l06xZyMy-LM` |
   | `GEMINI_MODEL` | `gemini-1.5-flash` |
   | `NODE_ENV` | `production` |

5. **Deploy**:
   - Click "Create Web Service"
   - Wait 2-3 minutes for deployment
   - You'll see build logs in real-time

6. **Get Your Server URL**:
   - After deployment, you'll see a URL like:
   - `https://vhbc-api-server.onrender.com`
   - **Copy this URL** - you'll need it for the Flutter app!

#### Option B: Using Blueprint (render.yaml)

1. **Push render.yaml to GitHub** (already done)

2. **In Render Dashboard**:
   - Click "New +" → "Blueprint"
   - Select your repository
   - Render will detect `render.yaml`
   - Click "Apply"

3. **Add GEMINI_API_KEY**:
   - Go to your service
   - Click "Environment"
   - Add `GEMINI_API_KEY` with your actual key
   - Click "Save Changes"

### Step 3: Verify Deployment

1. **Test Health Endpoint**:
```bash
curl https://your-app-name.onrender.com/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "uptime": 123.45,
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

2. **Test Chat Endpoint**:
```bash
curl -X POST https://your-app-name.onrender.com/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [
      {
        "role": "user",
        "parts": [{"text": "Hello"}]
      }
    ]
  }'
```

### Step 4: Update Flutter App

1. **Update `assets/env.txt`**:
```env
SUPABASE_URL=https://rbtalswsegpuaielvkuv.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJidGFsc3dzZWdwdWFpZWx2a3V2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyODMxODksImV4cCI6MjA3Njg1OTE4OX0.LVFF2f2Nv3-D59rOjVP8S4Pfr5jvcyky9iROnZaaNQQ
SERVER_URL=https://your-app-name.onrender.com
GEMINI_MODEL=gemini-1.5-flash
```

**Important**: Remove `GEMINI_API_KEY` from this file!

2. **The Flutter app code will be updated** to use the server endpoint instead of calling Gemini directly.

### Step 5: Test Your App

1. Run your Flutter app
2. Go to the Hermosa chat
3. Send a message
4. Verify you get a response

## 🔍 Monitoring & Logs

### View Logs
1. Go to Render Dashboard
2. Click on your service
3. Click "Logs" tab
4. See real-time logs

### Check Metrics
- CPU usage
- Memory usage
- Request count
- Response times

## ⚠️ Important Notes

### Free Tier Limitations
- **Spin down**: Server sleeps after 15 minutes of inactivity
- **Cold start**: First request after sleep takes 30-60 seconds
- **Monthly hours**: 750 hours/month (enough for most use cases)

### For Production
Consider upgrading to paid tier ($7/month):
- No spin down
- Better performance
- More resources
- Custom domains

## 🔒 Security Best Practices

✅ **DO**:
- Keep `GEMINI_API_KEY` only in Render environment variables
- Use HTTPS (Render provides this automatically)
- Monitor your usage in Render dashboard
- Set up alerts for errors

❌ **DON'T**:
- Never commit `.env` file to Git
- Don't share your Render dashboard access
- Don't expose your API key in client code
- Don't disable rate limiting

## 🐛 Troubleshooting

### Server won't start
**Check**:
- Environment variables are set correctly
- Build logs for errors
- Node.js version compatibility

**Solution**:
```bash
# View logs in Render dashboard
# Or use Render CLI:
render logs -s vhbc-api-server
```

### API requests failing
**Check**:
- Server URL is correct in Flutter app
- CORS settings
- Rate limits
- Network connectivity

**Solution**:
- Test with curl first
- Check Render logs
- Verify environment variables

### Slow responses
**Cause**: Free tier spin down

**Solutions**:
1. Keep server warm with periodic pings
2. Upgrade to paid tier
3. Accept 30-60s delay on first request

## 📊 Usage Monitoring

### Check API Usage
1. Render Dashboard → Your Service
2. View metrics:
   - Request count
   - Response times
   - Error rates

### Gemini API Usage
1. Go to https://aistudio.google.com
2. Check your API quota
3. Monitor costs (if on paid plan)

## 🔄 Updating Your Server

### Method 1: Git Push (Automatic)
```bash
# Make changes to server code
git add .
git commit -m "Update server"
git push

# Render auto-deploys on push
```

### Method 2: Manual Deploy
1. Render Dashboard → Your Service
2. Click "Manual Deploy"
3. Select branch
4. Click "Deploy"

## 📞 Support

### Render Support
- Documentation: https://render.com/docs
- Community: https://community.render.com
- Status: https://status.render.com

### Common Issues
- **504 Gateway Timeout**: Server is spinning up (wait 60s)
- **CORS Error**: Check CORS settings in `index.js`
- **Rate Limited**: Wait 15 minutes or upgrade plan

## ✅ Deployment Checklist

- [ ] Code pushed to GitHub
- [ ] Render service created
- [ ] Environment variables set
- [ ] Health endpoint working
- [ ] Chat endpoint tested
- [ ] Flutter app updated with SERVER_URL
- [ ] GEMINI_API_KEY removed from Flutter app
- [ ] App tested end-to-end
- [ ] Monitoring set up
- [ ] Logs reviewed

## 🎉 Success!

Your API server is now deployed and secure! Your Gemini API key is safely stored on the server and never exposed to users.

**Next Steps**:
1. Monitor your server for the first few days
2. Set up alerts in Render
3. Consider upgrading to paid tier for production
4. Add custom domain (optional)

---

**Need Help?** Check the `server/README.md` for more details or contact the development team.
