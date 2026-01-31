const OpenAI = require("openai");

const token = process.env.GITHUB_TOKEN;
const endpoint = "https://models.github.ai/inference";
const modelName = "openai/gpt-4o-mini";

exports.askAI = async (userQuestion, lat, lng, landmarks) => {
  if (!token) {
    console.warn("GITHUB_TOKEN is not set. Using fallback response.");
    return "I'm sorry, I can't process that right now. Please configure the AI token.";
  }

  try {
    const client = new OpenAI({ baseURL: endpoint, apiKey: token });

    const response = await client.chat.completions.create({
      model: modelName,
      temperature: 0.3,
      max_tokens: 300,
      messages: [
        {
          role: "system",
          content: `You are an AI commuter assistant for Parañaque City in Metro Manila.
Your job is to help users understand their current location and nearby landmarks.

Rules:
- Only use the provided latitude, longitude, and landmark data.
- Do NOT guess locations.
- Explain in simple, clear, and friendly language.
- If landmarks are given, describe where the user is based on them.
- Keep answers short and helpful.`
        },
        {
          role: "user",
          content: `
User GPS location:
Latitude: ${lat}
Longitude: ${lng}

Nearby landmarks:
${landmarks && landmarks.length > 0 ? landmarks.join(", ") : "None detected"}

User question:
${userQuestion}
        `
        }
      ]
    });

    return response.choices[0].message.content;
  } catch (error) {
    console.error("AI Service Error:", error);
    return "I'm having trouble connecting to the AI service. Please try again later.";
  }
};
