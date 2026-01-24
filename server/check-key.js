const axios = require('axios');
require('dotenv').config();

async function checkAPIKey() {
  const apiKey = process.env.GEMINI_API_KEY;
  
  if (!apiKey) {
    console.error('❌ GEMINI_API_KEY not found in .env');
    return;
  }
  
  console.log('🔑 Testing API Key:', apiKey.substring(0, 15) + '...');
  
  try {
    // Try to list available models
    const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`;
    const response = await axios.get(url);
    
    console.log('\n✅ API Key is VALID!');
    console.log('\n📋 Available models:');
    response.data.models?.forEach(model => {
      if (model.supportedGenerationMethods?.includes('generateContent')) {
        console.log(`  - ${model.name} (${model.displayName})`);
      }
    });
    
  } catch (error) {
    console.error('\n❌ API Key test FAILED:');
    console.error('Status:', error.response?.status);
    console.error('Message:', error.response?.data?.error?.message || error.message);
  }
}

checkAPIKey();
