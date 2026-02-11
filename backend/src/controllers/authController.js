const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const nodemailer = require('nodemailer');

// Transporter configuration
const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com', // Explicitly define Gmail's SMTP host
  port: 587, // Use port 587 for STARTTLS
  secure: false, // Set to false for STARTTLS
  requireTLS: true, // Enforce STARTTLS
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
  logger: true, // Enable logging
  debug: true, // Enable debug output
});

// Register
exports.register = async (req, res) => {
  try {
    const { full_name, email, password } = req.body;

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already exists' });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Generate verification token
    const verificationToken = crypto.randomBytes(20).toString('hex');

    // Create user (Role is forced to 'commuter')
    const user = new User({
      full_name,
      email,
      password: hashedPassword,
      role: 'commuter',
      isVerified: false,
      verificationToken
    });

    await user.save();

    // Send verification email
    // Use the request host to construct the link
    // Note: For local development with Android emulator, localhost might refer to the device.
    // Ideally use a configured BASE_URL env var.
    const verificationUrl = `${req.protocol}://${req.get('host')}/api/auth/verify?token=${verificationToken}`;
    
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Verify your email',
      html: `<p>Please verify your email by clicking the following link: <a href="${verificationUrl}">${verificationUrl}</a></p>`
    };

    // Send email (awaiting to ensure it works)
    try {
      await transporter.sendMail(mailOptions);
      console.log('Verification email sent to:', email);
    } catch (emailError) {
      console.error('Error sending email:', emailError);
      // Optional: Delete user if email fails so they can try again?
      // await User.deleteOne({ _id: user._id });
      return res.status(500).json({ 
        message: 'User registered, but failed to send verification email. Please contact support or try again.',
        error: emailError.message 
      });
    }

    res.status(201).json({ message: 'Check your email to verify your account' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Verify Email
exports.verifyEmail = async (req, res) => {
  try {
    const { token } = req.query;

    if (!token) {
        return res.status(400).json({ message: 'Invalid token' });
    }

    const user = await User.findOne({ verificationToken: token });
    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired token' });
    }

    user.isVerified = true;
    user.verificationToken = undefined; // Clear the token
    await user.save();

    res.status(200).json({ message: 'Email verified successfully. You can now login.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Check user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // Check verification
    if (!user.isVerified) {
        return res.status(400).json({ message: 'Please verify your email first' });
    }

    // Validate password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // Create token
    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET || 'secretKey',
      { expiresIn: '1d' }
    );

    res.json({
      token,
      user: {
        id: user._id,
        full_name: user.full_name,
        email: user.email,
        role: user.role
      }
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Resend Verification Email
exports.resendVerification = async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (user.isVerified) {
      return res.status(400).json({ message: 'Account already verified' });
    }

    // Generate new token if missing
    let verificationToken = user.verificationToken;
    if (!verificationToken) {
        verificationToken = crypto.randomBytes(20).toString('hex');
        user.verificationToken = verificationToken;
        await user.save();
    }

    const verificationUrl = `${req.protocol}://${req.get('host')}/api/auth/verify?token=${verificationToken}`;
    
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Resend: Verify your email',
      html: `<p>Please verify your email by clicking the following link: <a href="${verificationUrl}">${verificationUrl}</a></p>`
    };

    await transporter.sendMail(mailOptions);
    
    res.status(200).json({ message: 'Verification email resent successfully' });
  } catch (err) {
    console.error('Resend Error:', err);
    res.status(500).json({ message: 'Failed to send email', error: err.message });
  }
};
