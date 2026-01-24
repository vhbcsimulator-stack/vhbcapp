const axios = require('axios');
require('dotenv').config();

async function testGeminiAPI() {
  const apiKey = process.env.GEMINI_API_KEY;
  
  if (!apiKey) {
    console.error('❌ GEMINI_API_KEY not found in .env');
    return;
  }
  
  console.log('🔑 API Key found:', apiKey.substring(0, 10) + '...');
  
  const models = ['gemini-pro', 'gemini-1.5-flash', 'gemini-1.5-pro'];
  const apiVersions = [
    'https://generativelanguage.googleapis.com/v1',
    'https://generativelanguage.googleapis.com/v1beta'
  ];
  
  for (const baseUrl of apiVersions) {
    console.log(`\n📡 Testing ${baseUrl}...`);
    
    for (const model of models) {
      try {
        const url = `${baseUrl}/models/${model}:generateContent?key=${apiKey}`;
        const response = await axios.post(url, {
          contents: [{
            role: 'user',
            parts: [{ text: 'Say hello' }]
          }]
        }, { timeout: 10000 });
        
        const text = response.data?.candidates?.[0]?.content?.parts?.[0]?.text;
        console.log(`✅ ${model}: SUCCESS - "${text?.substring(0, 50)}..."`);
        return; // Stop after first success
        
      } catch (error) {
        if (error.response?.status === 404) {
          console.log(`❌ ${model}: Not found (404)`);
        } else {
          console.log(`❌ ${model}: ${error.response?.data?.error?.message || error.message}`);
        }
      }
    }
  }
}

testGeminiAPI();
