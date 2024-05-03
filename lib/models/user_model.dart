class User {
  final int memberId; // Reflects the auto-increment primary key in the database
  final int itsId; // ITS identifier
  final String username;
  final String password;
  final String role;
  final int mohalla_id; // Changed from tkmMohalla to reflect correct field name
  final String? mohallaName;
  final String designation;

  User({
    required this.memberId, // Ensure these are non-null
    required this.itsId,
    required this.username,
    required this.password,
    required this.role,
    required this.mohalla_id,
    this.mohallaName,
    required this.designation,
  });

  // Factory constructor to create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      memberId: json['member_id'] ?? 0, // Default to 0 if key is missing
      itsId: json['its_id'] ?? 0,
      username: json['name'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? '',
      mohalla_id: json['mohalla_id'] ?? '', // Changed to correct field name
      designation: json['designation'] ?? '',
      mohallaName: json['mohalla_name'] ?? '',
    );
  }

  // Convert User instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'its_id': itsId,
      'name': username,
      'password': password,
      'role': role,
      'mohalla_id': mohalla_id, // Changed to correct field name
      'mohalla_name': mohallaName, // Changed to correct field name
      'designation': designation,
    };
  }
}
