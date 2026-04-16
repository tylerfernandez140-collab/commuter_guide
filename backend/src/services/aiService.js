const axios = require("axios");

const apiKey = process.env.GEMINI_API_KEY;
const apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

exports.askAI = async (userQuestion, lat, lng, landmarks) => {
  if (!apiKey) {
    return "I'm sorry, I can't process that right now. Please configure the Gemini API key.";
  }

  const prompt = `You are an AI commuter assistant for Parañaque City in Metro Manila.
Your job is to help users understand their current location and nearby landmarks.

Rules:
- Only use the provided latitude, longitude, and landmark data.
- Do NOT guess locations.
- Explain in simple, clear, and friendly language.
- If landmarks are given, describe where the user is based on them.
- Keep answers short and helpful.

User GPS location:
Latitude: ${lat || "Unknown"}
Longitude: ${lng || "Unknown"}

Nearby landmarks:
${landmarks && landmarks.length > 0 ? landmarks.join(", ") : "None detected"}

User question: ${userQuestion}`;

  try {
    const response = await axios.post(
      `${apiUrl}?key=${apiKey}`,
      {
        contents: [
          {
            parts: [
              {
                text: prompt
              }
            ]
          }
        ]
      },
      {
        headers: {
          "Content-Type": "application/json"
        }
      }
    );

    const reply = response.data.candidates?.[0]?.content?.parts?.[0]?.text;
    return reply || "I'm sorry, I couldn't generate a response.";
  } catch (error) {
    console.error("=== GEMINI ERROR START ===");
    console.error(error.response?.data || error.message);
    console.error("=== GEMINI ERROR END ===");
    return "I'm having trouble connecting to the AI service. Please try again later.";
  }
};
