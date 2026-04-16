class RouteModel {
  final String id;
  final String routeName;
  final String vehicleType;
  final String startPoint;
  final String endPoint;
  final double? fare; // Legacy fare field (optional for backward compatibility)
  final double? discountedFare; // For student/elderly/disabled
  final double? regularFare; // For regular passengers
  final int estimatedTime;
  final List<String> landmarks;
  final List<Map<String, double>> coordinates;
  final List<double>? startLatLng;
  final List<double>? endLatLng;

  RouteModel({
    required this.id,
    required this.routeName,
    required this.vehicleType,
    required this.startPoint,
    required this.endPoint,
    this.fare, // Optional for backward compatibility
    this.discountedFare,
    this.regularFare,
    required this.estimatedTime,
    required this.landmarks,
    required this.coordinates,
    this.startLatLng,
    this.endLatLng,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['_id'],
      routeName: json['route_name'],
      vehicleType: json['vehicle_type'],
      startPoint: json['start_point'],
      endPoint: json['end_point'],
      fare: json['fare'] != null ? (json['fare'] as num).toDouble() : null, // Legacy fare
      discountedFare: json['discounted_fare'] != null ? (json['discounted_fare'] as num).toDouble() : null,
      regularFare: json['regular_fare'] != null ? (json['regular_fare'] as num).toDouble() : null,
      estimatedTime: json['estimated_time'],
      landmarks: List<String>.from(json['landmarks']),
      coordinates: (json['coordinates'] as List)
          .map(
            (c) => {
              'lat': (c['lat'] as num).toDouble(),
              'lng': (c['lng'] as num).toDouble(),
            },
          )
          .toList(),
      startLatLng: json['start_lat_lng'] != null
          ? List<double>.from((json['start_lat_lng'] as List).map((e) => (e as num).toDouble()))
          : null,
      endLatLng: json['end_lat_lng'] != null
          ? List<double>.from((json['end_lat_lng'] as List).map((e) => (e as num).toDouble()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_name': routeName,
      'vehicle_type': vehicleType,
      'start_point': startPoint,
      'end_point': endPoint,
      'fare': fare, // Legacy fare for backward compatibility
      'discounted_fare': discountedFare,
      'regular_fare': regularFare,
      'estimated_time': estimatedTime,
      'landmarks': landmarks,
      'coordinates': coordinates,
      'start_lat_lng': startLatLng,
      'end_lat_lng': endLatLng,
    };
  }
}
