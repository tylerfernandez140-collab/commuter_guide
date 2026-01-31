import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RoutingService {
  // OpenRouteService API Key (for Directions & Geocoding)
  // Reads from .env file
  final String _orsApiKey = dotenv.env['ORS_API_KEY'] ?? '';

  // Directions API (OpenRouteService)
  final String _orsDirectionsUrl =
      'https://api.openrouteservice.org/v2/directions/driving-car';

  // Geocoding API (OpenRouteService)
  final String _orsGeocodeUrl =
      'https://api.openrouteservice.org/geocode/search';

  // Reverse Geocoding API (OpenRouteService)
  final String _orsReverseGeocodeUrl =
      'https://api.openrouteservice.org/geocode/reverse';

  // Get Route using OpenRouteService Directions API
  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    if (_orsApiKey.isEmpty) {
      print('ORS API Key is missing in .env');
      // Fallback to straight line
      return [start, end];
    }

    // ORS uses 'start=long,lat' and 'end=long,lat'
    final url = Uri.parse(
      '$_orsDirectionsUrl?api_key=$_orsApiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['features'] != null && (data['features'] as List).isNotEmpty) {
          final geometry = data['features'][0]['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Convert [long, lat] to LatLng(lat, long)
          final List<LatLng> result = coordinates.map((point) {
            return LatLng(point[1].toDouble(), point[0].toDouble());
          }).toList();

          return result;
        } else {
          print('ORS API Error: No route found');
          return [start, end];
        }
      } else {
        print('Failed to fetch route: ${response.statusCode} ${response.body}');
        return [start, end];
      }
    } catch (e) {
      print('Routing Error: $e');
      return [start, end];
    }
  }

  // Geocode Address (Address -> LatLng)
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    if (_orsApiKey.isEmpty) {
      print('ORS API Key is missing');
      return null;
    }

    final url = Uri.parse(
      '$_orsGeocodeUrl?api_key=$_orsApiKey&text=${Uri.encodeComponent(address)}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['features'] != null && (data['features'] as List).isNotEmpty) {
          final coordinates =
              data['features'][0]['geometry']['coordinates'] as List;
          // ORS returns [long, lat]
          return LatLng(coordinates[1].toDouble(), coordinates[0].toDouble());
        }
      } else {
        print('Geocoding Failed: ${response.body}');
      }
    } catch (e) {
      print('Geocoding Error: $e');
    }
    return null;
  }

  // Reverse Geocode (LatLng -> Address)
  Future<String?> getAddressFromCoordinates(LatLng point) async {
    if (_orsApiKey.isEmpty) {
      print('ORS API Key is missing');
      return null;
    }

    final url = Uri.parse(
      '$_orsReverseGeocodeUrl?api_key=$_orsApiKey&point.lat=${point.latitude}&point.lon=${point.longitude}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['features'] != null && (data['features'] as List).isNotEmpty) {
          final props = data['features'][0]['properties'];
          // Construct a readable address
          String label = props['label'] ?? props['name'] ?? 'Unknown Location';
          return label;
        }
      } else {
        print('Reverse Geocoding Failed: ${response.body}');
      }
    } catch (e) {
      print('Reverse Geocoding Error: $e');
    }
    return null;
  }
}
