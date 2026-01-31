class Suggestion {
  final String id;
  final String landmarkName;
  final double latitude;
  final double longitude;
  final String status;
  final String submittedBy;

  Suggestion({
    required this.id,
    required this.landmarkName,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.submittedBy,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['_id'],
      landmarkName: json['landmark_name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'],
      submittedBy: json['submitted_by'] is Map ? json['submitted_by']['full_name'] : json['submitted_by'],
    );
  }
}
