const Route = require('../models/Route');
const Landmark = require('../models/Landmark');
const SearchLog = require('../models/SearchLog');

exports.searchDestination = async (req, res) => {
  try {
    const { destination } = req.body;
    const userId = req.user ? req.user.id : null;

    // 1. Search LANDMARKS collection
    // Use regex for partial match (case-insensitive)
    const landmark = await Landmark.findOne({
      name: { $regex: destination, $options: 'i' }
    });

    let route;
    let targetLocation = destination;

    if (landmark) {
      // 2. If landmark found, find ROUTE using near_route
      route = await Route.findOne({ route_name: landmark.near_route });
      targetLocation = landmark.name;
    } else {
      // FALLBACK: Check if the destination is actually a known route endpoint or in route's landmark array
      route = await Route.findOne({
        $or: [
          { end_point: { $regex: destination, $options: 'i' } },
          { landmarks: { $regex: destination, $options: 'i' } },
          { route_name: { $regex: destination, $options: 'i' } }
        ]
      });
    }

    // Edge Case: Destination not found
    if (!route) {
      return res.status(404).json({ message: 'Destination not found. Please try another landmark.' });
    }

    // Edge Case: Route inactive
    if (route.route_status !== 'active') {
      return res.status(400).json({ message: 'Route is currently unavailable.' });
    }

    // 3. Generate INSTRUCTIONS
    const instructions = [
      `Pumunta sa ${route.start_point} terminal`,
      `Sumakay ng ${route.vehicle_type} na ${route.route_name}`,
      `Bumaba sa ${targetLocation}`
    ];

    // 4. Log the search
    if (userId) {
      await SearchLog.create({
        user_id: userId,
        destination,
        suggested_route: route.route_name
      });
    }

    // 5. Return response
    res.json({
      route_name: route.route_name,
      vehicle_type: route.vehicle_type,
      fare: route.fare,
      estimated_time: route.estimated_time,
      landmarks: route.landmarks,
      coordinates: route.coordinates,
      instructions
    });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
