const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// CORS configuration - Allow requests from your Flutter app
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    
    // Allow localhost for development
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
      return callback(null, true);
    }
    
    // Add your production domains here
    const allowedOrigins = [
      'https://your-flutter-web-app.com', // Replace with your actual domain
      // Add more domains as needed
    ];
    
    if (allowedOrigins.indexOf(origin) !== -1 || !origin) {
      callback(null, true);
    } else {
      callback(null, true); // For now, allow all origins. Restrict in production!
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));

// Rate limiting - Prevent abuse
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', limiter);

// Health check endpoint
app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    message: 'VHBC API Server is running',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// Gemini API proxy endpoint
app.post('/api/chat', async (req, res) => {
  try {
    const { contents, model } = req.body;

    // Validate request
    if (!contents || !Array.isArray(contents)) {
      return res.status(400).json({
        error: 'Invalid request',
        message: 'Contents array is required'
      });
    }

    // Get API key from environment variable (stored securely on server)
    const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
    
    if (!GEMINI_API_KEY) {
      console.error('GEMINI_API_KEY not configured');
      return res.status(500).json({
        error: 'Server configuration error',
        message: 'API key not configured'
      });
    }

    // Use provided model or default
    const geminiModel = model || process.env.GEMINI_MODEL || 'gemini-1.5-flash';
    
    // Try multiple API versions as fallback
    const apiVersions = [
      process.env.GEMINI_API_BASE,
      'https://generativelanguage.googleapis.com/v1',
      'https://generativelanguage.googleapis.com/v1beta'
    ].filter(Boolean);

    let lastError = null;
    
    // Try each API version until one works
    for (const baseUrl of apiVersions) {
      try {
        const geminiUrl = `${baseUrl}/models/${geminiModel}:generateContent?key=${GEMINI_API_KEY}`;
        
        const response = await axios.post(
          geminiUrl,
          {
            contents: contents,
            generationConfig: {
              temperature: 0.3,
              maxOutputTokens: 2048,
            }
          },
          {
            headers: {
              'Content-Type': 'application/json',
            },
            timeout: 30000 // 30 second timeout
          }
        );

        // Success! Return the response from Gemini
        return res.json(response.data);
        
      } catch (error) {
        lastError = error;
        // If it's a 404, try the next API version
        if (error.response?.status === 404) {
          console.log(`Model not found in ${baseUrl}, trying next version...`);
          continue;
        }
        // For other errors, throw immediately
        throw error;
      }
    }
    
    // If we get here, all API versions failed
    throw lastError || new Error('All API versions failed');

  } catch (error) {
    console.error('Gemini API Error:', error.response?.data || error.message);
    
    // Handle different error types
    if (error.response) {
      // Gemini API returned an error
      return res.status(error.response.status).json({
        error: 'Gemini API error',
        message: error.response.data?.error?.message || 'Failed to get response from AI',
        statusCode: error.response.status
      });
    } else if (error.request) {
      // Request was made but no response received
      return res.status(503).json({
        error: 'Service unavailable',
        message: 'Could not reach Gemini API'
      });
    } else {
      // Something else happened
      return res.status(500).json({
        error: 'Internal server error',
        message: error.message
      });
    }
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    message: 'The requested endpoint does not exist'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'production' ? 'Something went wrong' : err.message
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 VHBC API Server running on port ${PORT}`);
  console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔑 Gemini API Key: ${process.env.GEMINI_API_KEY ? 'Configured ✓' : 'Missing ✗'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing HTTP server');
  process.exit(0);
});
