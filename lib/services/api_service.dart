import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/route_model.dart';
import '../models/landmark.dart';
import '../models/suggestion.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting login to $baseUrl/auth/login');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data['user']));
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to login');
      }
    } on SocketException catch (e) {
      print('Network error: $e');
      throw Exception('Cannot connect to server. Ensure backend is running.');
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<void> register(String fullName, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
        'role': 'commuter', // Force commuter role
      }),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to register');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Routes
  Future<List<RouteModel>> getRoutes() async {
    final response = await http.get(Uri.parse('$baseUrl/routes'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RouteModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load routes: ${response.body}');
    }
  }

  Future<void> createRoute(RouteModel route) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/routes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(route.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create route: ${response.body}');
    }
  }

  Future<void> updateRoute(String id, RouteModel route) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/routes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(route.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update route: ${response.body}');
    }
  }

  Future<void> deleteRoute(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/routes/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete route: ${response.body}');
    }
  }

  // Landmarks
  Future<List<Landmark>> getLandmarks() async {
    final response = await http.get(Uri.parse('$baseUrl/landmarks'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Landmark.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load landmarks');
    }
  }

  Future<void> createLandmark(Landmark landmark) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/landmarks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(landmark.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create landmark: ${response.body}');
    }
  }

  Future<void> updateLandmark(String id, Landmark landmark) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/landmarks/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(landmark.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update landmark: ${response.body}');
    }
  }

  Future<void> deleteLandmark(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/landmarks/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete landmark: ${response.body}');
    }
  }

  // Suggestions
  Future<List<Suggestion>> getSuggestions() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/suggestions'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Suggestion.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  Future<void> submitSuggestion(String name, double lat, double lng) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/suggestions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'landmark_name': name,
        'latitude': lat,
        'longitude': lng,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to submit suggestion: ${response.body}');
    }
  }

  Future<void> approveSuggestion(String id) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/suggestions/$id/approve'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to approve suggestion');
    }
  }

  Future<void> rejectSuggestion(String id) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/suggestions/$id/reject'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reject suggestion');
    }
  }

  // Search
  Future<Map<String, dynamic>> searchDestination(String destination) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/search'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'destination': destination}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Search failed');
    }
  }

  // Chat
  Future<String> chat(
    String message, {
    double? lat,
    double? lng,
    List<String>? landmarks,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'message': message,
        'lat': lat,
        'lng': lng,
        'landmarks': landmarks ?? [],
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['reply'];
    } else {
      throw Exception('Chat failed');
    }
  }
}
