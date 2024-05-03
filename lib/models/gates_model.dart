class Gate {
  final int gateId; // The unique ID of the gate
  final String gateName; // The name of the gate
  final int mohallaId; // The ID of the corresponding Mohalla

  Gate({
    required this.gateId,
    required this.gateName,
    required this.mohallaId,
  });

  // Create a Gate instance from a JSON map
  factory Gate.fromJson(Map<String, dynamic> json) {
    return Gate(
      gateId: json['gate_id'] ?? 0, // Default to 0 if the key doesn't exist
      gateName: json['gate_name'] ?? 'Unknown', // Default name if the key is missing
      mohallaId: json['mohalla_id'] ?? 0, // Default to 0 if the key doesn't exist
    );
  }

  // Convert a Gate instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'gate_id': gateId,
      'gate_name': gateName,
      'mohalla_id': mohallaId,
    };
  }
}
