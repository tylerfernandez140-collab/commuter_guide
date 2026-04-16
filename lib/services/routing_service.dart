import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RoutingService {
  // OpenRouteService API Key (for Directions & Geocoding)
  // Reads from .env file
  final String _orsApiKey = dotenv.env['ORS_API_KEY'] ?? '';
  
  // Google Maps API Key (for Directions API travel time)
  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Directions API (OpenRouteService)
  final String _orsDirectionsUrl =
      'https://api.openrouteservice.org/v2/directions/driving-car';

  // Geocoding API (OpenRouteService)
  final String _orsGeocodeUrl =
      'https://api.openrouteservice.org/geocode/search';

  // Reverse Geocoding API (OpenRouteService)
  final String _orsReverseGeocodeUrl =
      'https://api.openrouteservice.org/geocode/reverse';
      
  // Google Directions API (for travel time)
  final String _googleDirectionsUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  // Get Route using OpenRouteService Directions API
  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    if (_orsApiKey.isEmpty) {
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

          // Validate route has enough points
          if (result.length < 2) {
            return [start, end];
          }

          return result;
        } else {
          return [start, end];
        }
      } else {
        return [start, end];
      }
    } catch (e) {
      return [start, end];
    }
  }
  
  // Get travel time using Google Directions API
  Future<int?> getTravelTime(LatLng start, LatLng end, {bool useTraffic = true}) async {
    if (_googleApiKey.isEmpty) {
      return null;
    }

    // Build URL with optional traffic-aware departure_time
    String url = '$_googleDirectionsUrl'
        '?origin=${start.latitude},${start.longitude}'
        '&destination=${end.latitude},${end.longitude}'
        '&mode=driving'
        '&key=$_googleApiKey';

    // Add traffic-aware timing if requested
    if (useTraffic) {
      url += '&departure_time=now';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final duration = data['routes'][0]['legs'][0]['duration']['value'] as int;

          // Also check for traffic duration if available
          if (useTraffic && data['routes'][0]['legs'][0].containsKey('duration_in_traffic')) {
            final trafficDuration = data['routes'][0]['legs'][0]['duration_in_traffic']['value'] as int;
            return trafficDuration;
          }

          return duration;
        }
      }
    } catch (e) {
      // Silently handle error
    }

    return null;
  }

  // Geocode Address (Address -> LatLng)
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    if (_orsApiKey.isEmpty) {
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
          final result = LatLng(coordinates[1].toDouble(), coordinates[0].toDouble());

          return result;
        }
      }
    } catch (e) {
      // Silently handle error
    }
    return null;
  }

  // Reverse Geocode (LatLng -> Address)
  Future<String?> getAddressFromCoordinates(LatLng point) async {
    if (_orsApiKey.isEmpty) {
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
      }
    } catch (e) {
      // Silently handle error
    }
    return null;
  }
}
