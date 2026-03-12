const sgMail = require('@sendgrid/mail');
require('dotenv').config();

const NODE_ENV = process.env.NODE_ENV || 'development';

// --- Setup SendGrid ---
if (NODE_ENV === 'production') {
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);
}

// --- Email sending function ---
async function sendEmail({ to, subject, text, html }) {
  if (NODE_ENV === 'production') {
    // --- Send via SendGrid ---
    const msg = {
      to,
      from: process.env.MAIL_FROM || process.env.EMAIL_USER,
      subject,
      text,
      html,
    };
    try {
      await sgMail.send(msg);
      console.log(`Email sent to ${to} via SendGrid`);
    } catch (error) {
      console.error('SendGrid error:', error.response?.body || error.message);
      throw error;
    }
  } else {
    // --- Development: Fallback to Gmail/Nodemailer ---
    const nodemailer = require('nodemailer');
    
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
      pool: true,
      maxConnections: 1,
      maxMessages: 100,
      rateDelta: 1000,
      rateLimit: 5
    });

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to,
      subject,
      text,
      html,
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log(`Email sent to ${to} via Gmail (development)`);
    } catch (error) {
      console.error('Gmail error:', error.message);
      throw error;
    }
  }
}

module.exports = { sendEmail };
