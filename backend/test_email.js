require('dotenv').config();
const nodemailer = require('nodemailer');

const testEmail = async () => {
  console.log('Testing Email Configuration...');
  console.log('User:', process.env.EMAIL_USER);
  // Don't log the full password, just check if it exists
  console.log('Pass:', process.env.EMAIL_PASS ? '********' : 'Not Set');

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: process.env.EMAIL_USER, // Send to yourself
    subject: 'Test Email from Commuter Guide',
    text: 'If you receive this, your email configuration is working!',
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('✅ Success! Email sent:', info.response);
  } catch (error) {
    console.error('❌ Failed to send email.');
    console.error('Error:', error.message);
    if (error.code === 'EAUTH') {
      console.error('Hint: Check your email and App Password. Make sure 2FA is on and you are using an App Password, not your login password.');
    }
  }
};

testEmail();
