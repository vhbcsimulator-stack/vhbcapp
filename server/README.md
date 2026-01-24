# VHBC API Server

Secure API server for VHBC IntelliApp that proxies requests to Google Gemini API, keeping your API key safe and hidden from the client app.

## Features

- 🔒 Secure API key storage (server-side only)
- 🚀 Fast Express.js server
- 🛡️ Rate limiting to prevent abuse
- 🌐 CORS enabled for Flutter app
- 📊 Health check endpoints
- 🔄 Easy deployment to Render

## Local Development

### Prerequisites

- Node.js 18+ installed
- npm or yarn package manager

### Setup

1. Install dependencies:
```bash
cd server
npm install
```

2. Create `.env` file:
```bash
cp .env.example .env
```

3. Edit `.env` and add your Gemini API key:
```env
GEMINI_API_KEY=your_actual_gemini_api_key_here
GEMINI_MODEL=gemini-1.5-flash
PORT=3000
NODE_ENV=development
```

4. Start the development server:
```bash
npm run dev
```

The server will run on `http://localhost:3000`

### Testing

Test the health endpoint:
```bash
curl http://localhost:3000/api/health
```

Test the chat endpoint:
```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [
      {
        "role": "user",
        "parts": [{"text": "Hello, what is VHBC?"}]
      }
    ]
  }'
```

## Deployment to Render

### Method 1: Using Render Dashboard (Recommended)

1. **Create a Render account** at https://render.com

2. **Create a new Web Service**:
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Or use "Deploy from Git URL" if repo is public

3. **Configure the service**:
   - **Name**: `vhbc-api-server` (or your preferred name)
   - **Region**: Choose closest to your users
   - **Branch**: `main` (or your default branch)
   - **Root Directory**: `server`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Instance Type**: `Free` (or paid for better performance)

4. **Add Environment Variables**:
   - Click "Environment" tab
   - Add the following variables:
     - `GEMINI_API_KEY`: Your actual Gemini API key
     - `GEMINI_MODEL`: `gemini-1.5-flash`
     - `NODE_ENV`: `production`

5. **Deploy**:
   - Click "Create Web Service"
   - Render will automatically deploy your server
   - You'll get a URL like: `https://vhbc-api-server.onrender.com`

### Method 2: Using render.yaml (Infrastructure as Code)

The `render.yaml` file in the root directory can be used for automatic deployment.

1. Push your code to GitHub
2. In Render dashboard, click "New +" → "Blueprint"
3. Connect your repository
4. Render will detect `render.yaml` and set up everything automatically
5. Add environment variables in the Render dashboard

### After Deployment

1. **Test your deployed server**:
```bash
curl https://your-app-name.onrender.com/api/health
```

2. **Copy your server URL** (e.g., `https://vhbc-api-server.onrender.com`)

3. **Update your Flutter app**:
   - Add `SERVER_URL=https://your-app-name.onrender.com` to `assets/env.txt`
   - Remove `GEMINI_API_KEY` from `assets/env.txt`

## API Endpoints

### GET /
Health check - Returns server status

**Response:**
```json
{
  "status": "ok",
  "message": "VHBC API Server is running",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### GET /api/health
Detailed health check

**Response:**
```json
{
  "status": "healthy",
  "uptime": 12345.67,
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### POST /api/chat
Proxy to Gemini API for chat completions

**Request Body:**
```json
{
  "contents": [
    {
      "role": "user",
      "parts": [
        {
          "text": "Your question here"
        }
      ]
    }
  ],
  "model": "gemini-1.5-flash"
}
```

**Response:**
```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "AI response here"
          }
        ],
        "role": "model"
      }
    }
  ]
}
```

## Security Features

- ✅ API key stored only on server (never exposed to client)
- ✅ Rate limiting (100 requests per 15 minutes per IP)
- ✅ CORS protection
- ✅ Helmet.js security headers
- ✅ Request validation
- ✅ Error handling without exposing sensitive info

## Monitoring

### Render Dashboard
- View logs in real-time
- Monitor CPU and memory usage
- Check request metrics
- Set up alerts

### Logs
Access logs via Render dashboard or CLI:
```bash
render logs -s your-service-name
```

## Troubleshooting

### Server won't start
- Check that `GEMINI_API_KEY` is set in environment variables
- Verify Node.js version is 18+
- Check Render logs for specific errors

### API requests failing
- Verify server URL is correct in Flutter app
- Check CORS settings if getting CORS errors
- Ensure rate limit hasn't been exceeded
- Check Render logs for error details

### Free tier limitations
- Render free tier spins down after 15 minutes of inactivity
- First request after spin-down may take 30-60 seconds
- Consider upgrading to paid tier for production use

## Upgrading

To upgrade to a paid Render plan:
1. Go to your service in Render dashboard
2. Click "Settings" → "Instance Type"
3. Select a paid plan (starts at $7/month)
4. Benefits: No spin-down, better performance, more resources

## Support

For issues or questions:
- Check Render documentation: https://render.com/docs
- Review server logs in Render dashboard
- Contact VHBC development team

## License

MIT
