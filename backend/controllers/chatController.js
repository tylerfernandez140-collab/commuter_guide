const Route = require("../models/Route");
const Landmark = require("../models/Landmark");
const ChatLog = require("../models/ChatLog");

exports.chat = async (req, res) => {
  try {
    const { message, lat, lng, landmarks } = req.body;

    if (!message) {
      return res.status(400).json({
        reply: "Please enter a destination, route, or landmark."
      });
    }

    const normalize = (text) => text.toLowerCase().trim();
    const queryWords = normalize(message).split(" ");

    // Fetch latest data from MongoDB for real-time responses
    const routes = await Route.find();
    const landmarksData = await Landmark.find();

    // Smart token-based matching across all route fields
    let matchedRoute = routes.find((route) => {
      const searchable = [
        route.end_point,
        route.route_name,
        route.start_point,
      ]
        .join(" ")
        .toLowerCase();

      return queryWords.some((word) => searchable.includes(word));
    });

    if (matchedRoute) {
      // Log the interaction if user is authenticated
      if (req.user) {
        await ChatLog.create({
          user_id: req.user.id,
          question: message,
          ai_response: `To reach ${matchedRoute.end_point}, ride ${matchedRoute.route_name}. Estimated fare is ₱${matchedRoute.fare}.`
        });
      }

      return res.json({
        reply: `To reach ${matchedRoute.end_point}, ride ${matchedRoute.route_name}. Estimated fare is ₱${matchedRoute.fare}.`
      });
    }

    // Smart token-based landmark matching
    const matchedLandmark = landmarksData.find((landmark) => {
      const landmarkWords = normalize(landmark.name).split(" ");
      return queryWords.some((word) => landmarkWords.includes(word));
    });

    if (matchedLandmark) {
      // Log the interaction if user is authenticated
      if (req.user) {
        await ChatLog.create({
          user_id: req.user.id,
          question: message,
          ai_response: `${matchedLandmark.name} is near ${matchedLandmark.near_route}.`
        });
      }

      return res.json({
        reply: `${matchedLandmark.name} is near ${matchedLandmark.near_route}.`
      });
    }

    // No matches found
    if (req.user) {
      await ChatLog.create({
        user_id: req.user.id,
        question: message,
        ai_response: "Sorry, no matching route or landmark was found in the live commuter database."
      });
    }

    return res.json({
      reply: "Sorry, no matching route or landmark was found in the live commuter database."
    });
  } catch (error) {
    console.error("Chat database error:", error);
    return res.status(500).json({
      reply: "Server error while checking the commuter database."
    });
  }
};
