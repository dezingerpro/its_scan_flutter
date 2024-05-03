class Mohalla {
  final int mohallaId; // Unique identifier for the Mohalla
  final String mohallaName; // Name of the Mohalla

  Mohalla({
    required this.mohallaId, // Ensure it's non-null
    required this.mohallaName,
  });

  // Factory constructor to create Mohalla from JSON
  factory Mohalla.fromJson(Map<String, dynamic> json) {
    return Mohalla(
      mohallaId: json['mohalla_id'] ?? 0, // Default to 0 if key is missing
      mohallaName: json['mohalla_name'] ?? 'Unknown', // Default to 'Unknown'
    );
  }

  // Convert Mohalla instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'mohalla_id': mohallaId,
      'mohalla_name': mohallaName,
    };
  }
}
