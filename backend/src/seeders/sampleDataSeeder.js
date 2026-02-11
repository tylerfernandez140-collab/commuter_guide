const mongoose = require('mongoose');
const Route = require('../models/Route');
const Landmark = require('../models/Landmark');
const Suggestion = require('../models/Suggestion');
const User = require('../models/User');

const sampleRoutes = [
  {
    route_name: 'Route 1 - City Center to Suburbs',
    vehicle_type: 'jeepney',
    start_point: 'City Center',
    end_point: 'Suburbs',
    fare: 15,
    estimated_time: 45,
    route_status: 'active',
    landmarks: ['Central Park', 'City Mall'],
    coordinates: [
      { lat: 14.5995, lng: 120.9842 },
      { lat: 14.6095, lng: 120.9942 }
    ]
  },
  {
    route_name: 'Route 2 - Downtown to Uptown',
    vehicle_type: 'minibus',
    start_point: 'Downtown',
    end_point: 'Uptown',
    fare: 20,
    estimated_time: 30,
    route_status: 'active',
    landmarks: ['Tech Hub', 'University'],
    coordinates: [
      { lat: 14.5895, lng: 120.9742 },
      { lat: 14.6195, lng: 121.0042 }
    ]
  },
  {
    route_name: 'Route 3 - Airport to City',
    vehicle_type: 'ejeepney',
    start_point: 'Airport',
    end_point: 'City Center',
    fare: 25,
    estimated_time: 35,
    route_status: 'active',
    landmarks: ['Airport Terminal', 'Hotel District'],
    coordinates: [
      { lat: 14.5095, lng: 120.9642 },
      { lat: 14.5995, lng: 120.9842 }
    ]
  }
];

const sampleLandmarks = [
  {
    name: 'Central Park',
    type: 'Establishment',
    near_route: 'Route 1 - City Center to Suburbs',
    latitude: 14.5995,
    longitude: 120.9842
  },
  {
    name: 'City Mall',
    type: 'Mall',
    near_route: 'Route 1 - City Center to Suburbs',
    latitude: 14.6095,
    longitude: 120.9942
  },
  {
    name: 'Tech Hub',
    type: 'Establishment',
    near_route: 'Route 2 - Downtown to Uptown',
    latitude: 14.5895,
    longitude: 120.9742
  },
  {
    name: 'University',
    type: 'School',
    near_route: 'Route 2 - Downtown to Uptown',
    latitude: 14.6195,
    longitude: 121.0042
  },
  {
    name: 'Airport Terminal',
    type: 'Airport',
    near_route: 'Route 3 - Airport to City',
    latitude: 14.5095,
    longitude: 120.9642
  },
  {
    name: 'Hotel District',
    type: 'Establishment',
    near_route: 'Route 3 - Airport to City',
    latitude: 14.5295,
    longitude: 120.9742
  },
  {
    name: 'General Hospital',
    type: 'Hospital',
    near_route: 'Route 1 - City Center to Suburbs',
    latitude: 14.5795,
    longitude: 120.9642
  },
  {
    name: 'City Hall',
    type: 'Government Office',
    near_route: 'Route 2 - Downtown to Uptown',
    latitude: 14.5895,
    longitude: 120.9842
  }
];

const sampleSuggestions = [
  {
    landmark_name: 'New Restaurant',
    latitude: 14.5795,
    longitude: 120.9742,
    status: 'pending'
  },
  {
    landmark_name: 'Bus Terminal',
    latitude: 14.5695,
    longitude: 120.9642,
    status: 'pending'
  },
  {
    landmark_name: 'Shopping Center',
    latitude: 14.5895,
    longitude: 120.9942,
    status: 'pending'
  },
  {
    landmark_name: 'Community Center',
    latitude: 14.5995,
    longitude: 120.9542,
    status: 'pending'
  }
];

async function seedSampleData() {
  try {
    // Clear existing data
    await Route.deleteMany({});
    await Landmark.deleteMany({});
    await Suggestion.deleteMany({});
    
    // Get a user to associate with suggestions
    const user = await User.findOne({ role: 'commuter' });
    if (!user) {
      console.log('No commuter user found. Please create a commuter user first.');
      return;
    }

    // Insert sample routes
    const routes = await Route.insertMany(sampleRoutes);
    console.log(`${routes.length} routes inserted`);

    // Insert sample landmarks
    const landmarks = await Landmark.insertMany(sampleLandmarks);
    console.log(`${landmarks.length} landmarks inserted`);

    // Insert sample suggestions with user reference
    const suggestionsWithUser = sampleSuggestions.map(suggestion => ({
      ...suggestion,
      submitted_by: user._id
    }));
    const suggestions = await Suggestion.insertMany(suggestionsWithUser);
    console.log(`${suggestions.length} suggestions inserted`);

    console.log('Sample data seeded successfully!');
  } catch (error) {
    console.error('Error seeding sample data:', error);
  }
}

module.exports = seedSampleData;
