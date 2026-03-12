require('dotenv').config();
const axios = require('axios');

const testRegistration = async () => {
  try {
    console.log('Testing registration endpoint...');
    
    const response = await axios.post('http://localhost:3000/api/auth/register', {
      full_name: 'Test User',
      email: `test${Date.now()}@example.com`,
      password: 'password123'
    }, {
      timeout: 15000 // 15 second timeout
    });
    
    console.log('✅ Registration successful!');
    console.log('Response:', response.data);
  } catch (error) {
    console.error('❌ Registration failed:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else if (error.request) {
      console.error('No response received:', error.message);
    } else {
      console.error('Error:', error.message);
    }
  }
};

testRegistration();
