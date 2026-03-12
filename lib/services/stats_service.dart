import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class StatsService {
  static String get _baseUrl => ApiService.baseUrl;
  static Map<String, int>? _cache;
  static DateTime? _lastFetch;
  static const Duration _cacheTtl = Duration(seconds: 60);
  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static Future<Map<String, int>> getDashboardStats({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh && _cache != null && _lastFetch != null) {
      if (now.difference(_lastFetch!) < _cacheTtl) {
        return _cache!;
      }
    }
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats/dashboard'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = <String, int>{
          'routes': _asInt(data['routes']),
          'landmarks': _asInt(data['landmarks']),
          'pendingSuggestions': _asInt(data['pendingSuggestions']),
          'users': _asInt(data['users']),
        };
        _cache = result;
        _lastFetch = now;
        return result;
      } else {
        throw Exception('Failed to load stats');
      }
    } catch (e) {
      return {
        'routes': 0,
        'landmarks': 0,
        'pendingSuggestions': 0,
        'users': 0,
      };
    }
  }
}
