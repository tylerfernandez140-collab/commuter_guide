require('dotenv').config();
const mongoose = require('mongoose');
const express = require('express');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

// Import Routes
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const routeRoutes = require('./routes/routeRoutes');
const landmarkRoutes = require('./routes/landmarkRoutes');
const searchRoutes = require('./routes/searchRoutes');
const suggestionRoutes = require('./routes/suggestionRoutes');
const chatRoutes = require('./routes/chatRoutes');

// Use Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/routes', routeRoutes);
app.use('/api/landmarks', landmarkRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/suggestions', suggestionRoutes);
app.use('/api/chat', chatRoutes);

// Import models
const User = require('./models/User');
const Route = require('./models/Route');
const Landmark = require('./models/Landmark');
const SearchLog = require('./models/SearchLog');
const Suggestion = require('./models/Suggestion');
const ChatLog = require('./models/ChatLog');

const seedAdmin = require('./seeders/adminSeeder');

const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI;

mongoose.connect(MONGO_URI)
  .then(async () => {
    console.log('Connected to MongoDB');
    
    // Seed Admin User
    await seedAdmin();

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server is running on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('Database connection error:', err);
  });
