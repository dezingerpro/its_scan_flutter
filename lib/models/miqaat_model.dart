class Miqaat {
  final int miqaatId; // Unique identifier
  final String miqaatName;
  final String miqaatDate;
  final String status;

  Miqaat({
    required this.miqaatId,
    required this.miqaatName,
    required this.miqaatDate,
    required this.status,
  });

  // Factory constructor to create Miqaat from JSON
  factory Miqaat.fromJson(Map<String, dynamic> json) {
    return Miqaat(
      miqaatId: json['miqaat_id'] ?? 0, // Default to 0 if not found
      miqaatName: json['miqaat_name'] ?? '',
      miqaatDate: json['miqaat_date'] ?? '',
      status: json['status'] ?? '',
    );
  }

  // Convert Miqaat instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'miqaat_id': miqaatId,
      'miqaat_name': miqaatName,
      'miqaat_date': miqaatDate,
      'status': status,
    };
  }
}
