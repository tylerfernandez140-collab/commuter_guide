commuter_guide

Tech Stack

This project leverages a modern and robust tech stack to deliver a seamless experience for commuters.

Frontend (Mobile Application)

The user-facing application is built with Flutter, Google's versatile UI toolkit, enabling cross-platform development from a single codebase.

Key Flutter Packages and Libraries:

Flutter: The core framework for building natively compiled applications.

flutter_polyline_points: For decoding and drawing polylines on maps, crucial for route visualization.

geolocator: Provides access to device location services (GPS, network).

flutter_map: A powerful and flexible map widget for interactive map displays.

latlong2: Utility library for handling latitude and longitude coordinates.

http: For making HTTP requests to communicate with the backend API.

intl: For internationalization and localization, supporting diverse language and formatting needs.

location: Another package for real-time location services.

provider: A widely used state management solution for efficient application state handling.

shared_preferences: For lightweight, persistent key-value storage (e.g., user preferences).

flutter_dotenv: Manages environment variables from .env files for secure configuration.

Backend (API Services)

The backend is developed using Node.js, providing a scalable and efficient environment for server-side logic and API development.

Key Backend Technologies and Libraries:

Node.js: The JavaScript runtime environment.

Express.js: A fast, minimalist web framework for building RESTful APIs.

Mongoose: An Object Data Modeling (ODM) library for MongoDB, simplifying database interactions.

bcryptjs: For securely hashing and comparing passwords.

cors: Middleware to enable Cross-Origin Resource Sharing, allowing frontend-backend communication.

dotenv: Loads environment variables from .env files into process.env.

jsonwebtoken: Implements JSON Web Tokens (JWTs) for secure authentication and authorization.

nodemailer: For sending emails (e.g., user verification, notifications).

openai: Integration with OpenAI's API for AI-powered features (e.g., intelligent search, suggestions).

Database

The project utilizes a flexible and scalable NoSQL database for data storage.

Database Technology:

MongoDB: A document-oriented NoSQL database, known for its flexibility and scalability.

How to Start the Project

Follow these steps to get the Commuter Guide project up and running on your local machine.

Prerequisites

Before you begin, ensure you have the following installed:

Node.js (LTS version recommended)

npm (comes with Node.js)

Flutter SDK (stable channel recommended)

MongoDB (Community Server or Atlas account)

Git

Clone the Repository

First, clone the project repository to your local machine:

git clone <repository_url>
cd commuter_guide


Backend Setup

Navigate to the backend directory, install dependencies, and start the server.

Navigate to the backend directory:

cd backend


Install dependencies:

npm install


Create a .env file:

Create a .env file in the backend directory and add your environment variables. A .env.example file might be provided for reference. Essential variables typically include:

MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret_key
EMAIL_USER=your_email_for_nodemailer
EMAIL_PASS=your_email_password_or_app_password
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=adminpassword


Replace placeholders with your actual values.

Start the backend server:

npm start


The backend server will typically run on http://localhost:3000
.

Frontend Setup (Flutter)

Open a new terminal, navigate to the project root, install Flutter dependencies, and run the application.

Navigate to the project root (if you are still in the backend directory):

cd ..


Install Flutter dependencies:

flutter pub get


Create a .env file for Flutter:

Create a .env file in the root of your Flutter project (e.g., commuter_guide/.env) and add any necessary environment variables, such as API keys or backend URLs.

BASE_URL=http://localhost:3000/api


Ensure this matches your backend server's address.

Run the Flutter application on Chrome:

flutter run -d chrome