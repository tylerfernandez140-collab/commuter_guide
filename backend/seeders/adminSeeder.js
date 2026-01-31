const bcrypt = require('bcryptjs');
const User = require('../models/User');

const seedAdmin = async () => {
  try {
    const adminEmail = process.env.ADMIN_EMAIL || 'admin@commuterguide.com';
    const adminPassword = process.env.ADMIN_PASSWORD || 'admin123';
    const adminName = process.env.ADMIN_NAME || 'Admin User';

    // Check if admin exists
    const existingAdmin = await User.findOne({ role: 'admin' });

    if (existingAdmin) {
      console.log('Admin account already exists.');
      return;
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(adminPassword, salt);

    // Create admin
    const newAdmin = new User({
      full_name: adminName,
      email: adminEmail,
      password: hashedPassword,
      role: 'admin'
    });

    await newAdmin.save();
    console.log('Admin account created successfully.');
    console.log(`Email: ${adminEmail}`);
    console.log(`Password: ${adminPassword}`);

  } catch (error) {
    console.error('Error seeding admin:', error);
  }
};

module.exports = seedAdmin;
