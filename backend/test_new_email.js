require('dotenv').config();
const { sendEmail } = require('./src/services/emailService');

const testEmail = async () => {
  console.log('Testing new email service...');
  console.log('NODE_ENV:', process.env.NODE_ENV);
  
  try {
    await sendEmail({
      to: process.env.EMAIL_USER,
      subject: 'Test Email from New Service',
      text: 'This is a test email using the new email service.',
      html: '<p>This is a <b>test email</b> using the new email service.</p>'
    });
    console.log('✅ Email sent successfully!');
  } catch (error) {
    console.error('❌ Email failed:', error.message);
  }
};

testEmail();
