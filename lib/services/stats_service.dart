import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StatsService {
  static const String _baseUrl = 'http://localhost:3000/api';

  static Future<Map<String, int>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats/dashboard'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'routes': data['routes'] ?? 0,
          'landmarks': data['landmarks'] ?? 0,
          'pendingSuggestions': data['pendingSuggestions'] ?? 0,
          'users': data['users'] ?? 0,
        };
      } else {
        throw Exception('Failed to load stats');
      }
    } catch (e) {
      // Return default values if API fails
      return {
        'routes': 0,
        'landmarks': 0,
        'pendingSuggestions': 0,
        'users': 0,
      };
    }
  }
}
