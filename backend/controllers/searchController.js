const Route = require('../models/Route');
const SearchLog = require('../models/SearchLog');

exports.searchDestination = async (req, res) => {
  try {
    const { destination } = req.body;
    const userId = req.user.id;

    // Simple search logic: find routes that contain the destination in landmarks or end_point
    const routes = await Route.find({
      $or: [
        { landmarks: { $regex: destination, $options: 'i' } },
        { end_point: { $regex: destination, $options: 'i' } }
      ]
    });

    if (routes.length === 0) {
      return res.status(404).json({ message: 'No routes found for this destination' });
    }

    // Pick the best route (first one for now)
    const bestRoute = routes[0];

    // Log the search
    if (userId) {
      await SearchLog.create({
        user_id: userId,
        destination,
        suggested_route: bestRoute.route_name
      });
    }

    // Construct response
    res.json({
      route_name: bestRoute.route_name,
      vehicle_type: bestRoute.vehicle_type,
      fare: bestRoute.fare,
      estimated_time: bestRoute.estimated_time,
      landmarks: bestRoute.landmarks,
      instructions: [
        `Go to ${bestRoute.start_point} terminal`,
        `Take the ${bestRoute.vehicle_type} bound for ${bestRoute.end_point}`,
        `Get off at ${destination} or nearest landmark`
      ]
    });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
