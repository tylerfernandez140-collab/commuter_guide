import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/route_model.dart';
import '../models/landmark.dart';
import '../models/suggestion.dart';
import '../models/user.dart';

class ApiService {
  static const Duration _cacheTtl = Duration(seconds: 60);
  static List<RouteModel>? _routesCache;
  static DateTime? _routesLastFetch;
  static List<Landmark>? _landmarksCache;
  static DateTime? _landmarksLastFetch;
  static List<User>? _usersCache;
  static DateTime? _usersLastFetch;
  static int? get routesCachedCount => _routesCache?.length;
  static int? get landmarksCachedCount => _landmarksCache?.length;
  static int? get usersCachedCount => _usersCache?.length;
  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return 'https://commuter-guide.onrender.com/api';
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('Attempting login to $baseUrl/auth/login');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');

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
      debugPrint('Network error: $e');
      throw Exception('Cannot connect to server. Ensure backend is running.');
    } catch (e) {
      debugPrint('Login error: $e');
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
  Future<List<RouteModel>> getRoutes({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh && _routesCache != null && _routesLastFetch != null) {
      if (now.difference(_routesLastFetch!) < _cacheTtl) {
        return _routesCache!;
      }
    }
    final response = await http.get(Uri.parse('$baseUrl/routes'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final result = data.map((json) => RouteModel.fromJson(json)).toList();
      _routesCache = result;
      _routesLastFetch = now;
      return result;
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
    // Clear cache after successful delete
    _routesCache = null;
    _routesLastFetch = null;
  }

  // Landmarks
  Future<List<Landmark>> getLandmarks({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh && _landmarksCache != null && _landmarksLastFetch != null) {
      if (now.difference(_landmarksLastFetch!) < _cacheTtl) {
        return _landmarksCache!;
      }
    }
    final response = await http.get(Uri.parse('$baseUrl/landmarks'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final result = data.map((json) => Landmark.fromJson(json)).toList();
      _landmarksCache = result;
      _landmarksLastFetch = now;
      return result;
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
    // Clear cache after successful delete
    _landmarksCache = null;
    _landmarksLastFetch = null;
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

  // Users
  Future<List<User>> getUsers({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh && _usersCache != null && _usersLastFetch != null) {
      if (now.difference(_usersLastFetch!) < _cacheTtl) {
        return _usersCache!;
      }
    }
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final result = data.map((json) => User.fromJson(json)).toList();
      _usersCache = result;
      _usersLastFetch = now;
      return result;
    }
    try {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to load users (${response.statusCode})');
    } catch (_) {
      throw Exception('Failed to load users (${response.statusCode})');
    }
  }
}
