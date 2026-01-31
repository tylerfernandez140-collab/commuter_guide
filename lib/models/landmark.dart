class Landmark {
  final String id;
  final String name;
  final String type;
  final String nearRoute;
  final double latitude;
  final double longitude;

  Landmark({
    required this.id,
    required this.name,
    required this.type,
    required this.nearRoute,
    required this.latitude,
    required this.longitude,
  });

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: json['_id'],
      name: json['name'],
      type: json['type'],
      nearRoute: json['near_route'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'near_route': nearRoute,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
