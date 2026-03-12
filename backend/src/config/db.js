const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const uri = process.env.MONGO_URI || process.env.MONGODB_URI;
    if (!uri) {
      console.warn('No MONGO_URI/MONGODB_URI set. Skipping DB connection.');
      return;
    }
    const conn = await mongoose.connect(uri);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
    
    // Seed Admin User
    const seedAdmin = require('../utils/adminSeeder');
    await seedAdmin();

  } catch (error) {
    console.error(`Error: ${error.message}`);
    // Do not crash on startup; allow health checks
  }
};

module.exports = connectDB;
