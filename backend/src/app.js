const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');

// Load env vars
dotenv.config();

// Connect to database
connectDB();

const app = express();

// Middleware
app.use(express.json());
app.use(cors());

// Route files
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const routeRoutes = require('./routes/routeRoutes');
const landmarkRoutes = require('./routes/landmarkRoutes');
const searchRoutes = require('./routes/searchRoutes');
const suggestionRoutes = require('./routes/suggestionRoutes');
const chatRoutes = require('./routes/chatRoutes');

// Mount routers
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/routes', routeRoutes);
app.use('/api/landmarks', landmarkRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/suggestions', suggestionRoutes);
app.use('/api/chat', chatRoutes);

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;
