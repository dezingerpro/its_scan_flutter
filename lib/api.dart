import 'dart:html' as html;
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:its_scan/models/user_model.dart';
import 'downloads/file_mobile.dart' if (dart.library.html) 'downloads/file_web.dart' as file_helper;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/gate_assingment_model.dart';
import 'models/gates_model.dart';
import 'models/miqaat_model.dart';
import 'models/mohalla_model.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.18.108:8080/'; // Adjusted base URL


  static Future<Map<String, dynamic>> sendITSIDToBackend(String itsId,int memberId,int miqaatId,int gateId,String time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Uncomment these if you want to use values from SharedPreferences
      // final location = prefs.getString('userLocation') ?? 'default';
      // final event = prefs.getString('userEvent') ?? 'default';
      // final location = "AJS";
      // final event = "AJS";

      // Define the URL for your backend endpoint
      final url = Uri.parse('${baseUrl}lookupITS');

      // Send a POST request with ITS ID, location, and event in the request body
      final response = await http.post(
        url,
        body: jsonEncode({
          'itsId': itsId,
          //'location': location,
          //'event': event,
          'miqaatId' : miqaatId,
          'memberId' : memberId,
          'gateId' : gateId,
          'Time_stamp' : time,
        }),
        headers: {
          'Content-Type': 'application/json'
        },
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        print('Data sent successfully to the backend');
        // Assuming the server returns { 'results': ..., 'statistics': ... }
        Map<String, dynamic> statistics = {
          'successCount': int.parse(responseData['statistics']['successCount'].toString()),
          'failedCount': int.parse(responseData['statistics']['failedCount'].toString())
        };
        print(statistics);
        return statistics; // Return statistics to the caller
      } else {
        // Handle unsuccessful response
        print('Failed to send data to the backend, status code: ${response.statusCode}');
        throw Exception('Failed to fetch statistics from the backend');
      }
    } catch (error) {
      // Handle network or server errors
      print('Error sending data to the backend: $error');
      throw Exception('Error sending data to the backend: $error');
    }
  }

  static Future<Map<String, dynamic>> sendOfflineData(int memberId,int miqaatId,int gateId,String time) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> offlineIds = prefs.getStringList('offlineIds') ?? [];
    final url = Uri.parse('${baseUrl}uploadIds');

    if (offlineIds.isNotEmpty) {
      final response = await http.post(
        url,
        body: jsonEncode({
          'itsIds': offlineIds,
          'miqaatId' : miqaatId,
          'memberId' : memberId,
          'gateId' : gateId,
          'Time_stamp' : time,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        await prefs.remove('offlineIds');// Only remove IDs if successful
        Map<String, dynamic> statistics = {
          'successCount': int.parse(responseData['statistics']['successCount'].toString()),
          'failedCount': int.parse(responseData['statistics']['failedCount'].toString())
        };
        print(statistics);
        return statistics;
      } else {
        // Handle errors or retry logic
        print('Failed to send data: ${response.statusCode}');
        throw Exception('Failed to fetch statistics from the backend');
      }
    } else {
      print('No offline data to send');
      throw Exception('Failed to fetch statistics from the backend');
    }
  }

  // Fetch User by ITS ID
  static Future<User> fetchUser(String itsId) async {
    final response = await http.get(Uri.parse('${baseUrl}users/$itsId'));
    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      return User.fromJson(userData); // Parse JSON into User model
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else {
      throw Exception('Error fetching user data');
    }
  }

  static Future<List<User>> fetchUsersByIds(List<int> memberIds) async {
    final response = await http.post(
      Uri.parse('${baseUrl}fetch-users-by-ids'), // Your endpoint to fetch users by IDs
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'memberIds': memberIds}), // Send the list of member IDs
    );

    if (response.statusCode == 200) {
      final List<dynamic> userData = json.decode(response.body); // Decode the JSON response
      return userData.map((userJson) => User.fromJson(userJson)).toList(); // Map JSON to User model
    } else {
      throw Exception('Error fetching users by IDs'); // Error handling
    }
  }

  static Future<List<User>> fetchAllUsers() async {
    try {
      final response = await http.get(Uri.parse('${baseUrl}users')); // Endpoint to fetch all users

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body); // Decode the JSON response

        // Print the raw data received
        print('Raw data received: ${response.body}');

        // Map the data to User objects
        final List<User> users = data.map((userJson) => User.fromJson(userJson)).toList();

        // Print the user models
        users.forEach((user) {
          print('User: ${user.toJson()}'); // Use toJson to print the user model
        });

        return users;
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      print('Error in fetchAllUsers: ${e.toString()}'); // Print the error
      throw e; // Re-throw the error
    }
  }

  // Create a new User
  static Future<void> createUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('${baseUrl}register'), // Ensure correct endpoint
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create user.');
    }
  }

  // Update an existing User
  static Future<void> updateUser(String itsId, Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('${baseUrl}users/$itsId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData), // Ensure data is sent as JSON
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user.');
    }
  }

  // Delete a User by ITS ID
  static Future<void> deleteUser(String itsId) async {
    final response = await http.delete(
      Uri.parse('${baseUrl}users/$itsId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user.');
    }
  }


  static Future<User> login(String itsId, String password) async {
    final response = await http.post(
      Uri.parse('${baseUrl}login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'its_id': itsId,
        'password': password, // Plain-text password for backend verification
      }),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      print(responseData['user']);
      return User.fromJson(responseData['user']); // Parse JSON into User model
    } else if (response.statusCode == 401) {
      throw Exception('Invalid credentials'); // Incorrect password
    } else if (response.statusCode == 404) {
      throw Exception('User not found'); // User not found
    } else {
      throw Exception('Error during login'); // Handle other errors
    }
  }

  // Create Miqaat
  static Future<Miqaat> createMiqaat(String name, String date,
      String status) async {
    final response = await http.post(
      Uri.parse('${baseUrl}miqaat'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'miqaat_name': name,
        'miqaat_date': date,
        'status': status,
      }),
    );

    if (response.statusCode == 201) {
      return Miqaat.fromJson(
          json.decode(response.body)); // Return created Miqaat
    } else {
      throw Exception('Failed to create Miqaat');
    }
  }

// Get all Miqaats
  static Future<List<Miqaat>> getAllMiqaats() async {
    final response = await http.get(Uri.parse('${baseUrl}miqaat'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Miqaat.fromJson(json))
          .toList(); // Convert to Miqaat objects
    } else {
      throw Exception('Failed to fetch Miqaats');
    }
  }

// Get single Miqaat by ID
  static Future<Miqaat> getMiqaatById(int miqaatId) async {
    final response = await http.get(Uri.parse('${baseUrl}miqaat/$miqaatId'));

    if (response.statusCode == 200) {
      return Miqaat.fromJson(json.decode(response.body)); // Return the Miqaat
    } else {
      throw Exception('Failed to fetch Miqaat');
    }
  }

// Update Miqaat
  static Future<void> updateMiqaat(int miqaatId, String name, String date,
      String status) async {
    final response = await http.put(
      Uri.parse('${baseUrl}miqaat/$miqaatId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'miqaat_name': name,
        'miqaat_date': date,
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update Miqaat');
    }
  }

// Delete Miqaat
  static Future<void> deleteMiqaat(int miqaatId) async {
    final response = await http.delete(
      Uri.parse('${baseUrl}miqaat/$miqaatId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete Miqaat');
    }
  }

  static Future<void> assignMembersToMiqaat(int miqaatId, List<int> memberIds) async {
    final response = await http.post(
      Uri.parse('${baseUrl}assign-members'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'miqaat_id': miqaatId,  // Change miqaat_id to match your API endpoint
        'member_ids': memberIds,  // Change member_ids to match your API endpoint
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to assign members to miqaat");
    }
  }

  static Future<List<Mohalla>> fetchMohallas() async {
    final response = await http.get(Uri.parse('${baseUrl}mohallas')); // Endpoint to fetch all mohallas

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body); // Decode JSON
      return data.map((mohalla) => Mohalla.fromJson(mohalla)).toList(); // Convert to Mohalla objects
    } else {
      throw Exception('Failed to fetch mohallas'); // Handle error
    }
  }

  // CREATE Gate
  static Future<void> createGate(String gateName, int mohallaId) async {
    final response = await http.post(
      Uri.parse('${baseUrl}gates'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'gate_name': gateName,
        'mohalla_id': mohallaId,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create gate');
    }
  }

  // READ All Gates
  static Future<List<Gate>> fetchAllGates() async {
    final response = await http.get(Uri.parse('${baseUrl}gates'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((gateJson) => Gate.fromJson(gateJson)).toList(); // Use your Gate model
    } else {
      throw Exception('Failed to fetch gates');
    }
  }

  // READ Single Gate by ID
  static Future<Gate> fetchGateById(int gateId) async {
    final response = await http.get(Uri.parse('${baseUrl}gates/$gateId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Gate.fromJson(data); // Convert JSON to Gate model
    } else {
      throw Exception('Failed to fetch gate');
    }
  }

  static Future<List<GateAssignment>> fetchGateAssignments(int eventId) async {
    final response = await http.get(Uri.parse('${baseUrl}fetch-gate-assignments/$eventId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((assignment) => GateAssignment.fromJson(assignment)).toList();
    } else {
      throw Exception('Failed to fetch gate assignments');
    }
  }

  // UPDATE Gate
  static Future<void> updateGate(int gateId, String gateName, int mohallaId) async {
    final response = await http.put(
      Uri.parse('${baseUrl}gates/$gateId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'gate_name': gateName,
        'mohalla_id': mohallaId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update gate');
    }
  }

  // DELETE Gate
  static Future<void> deleteGate(int gateId) async {
    final response = await http.delete(
      Uri.parse('${baseUrl}gates/$gateId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete gate');
    }
  }

  static Future<void> createGateAssignment(int gateId, int miqaatId, int memberId) async {
    print("Hello");
    final response = await http.post(
      Uri.parse('${baseUrl}gate-assignments'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'gate_id': gateId,
        'miqaat_id': miqaatId,
        'member_id': memberId,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create gate assignment');
    }
  }

  static Future<List<dynamic>> fetchMiqaatsForUser(int memberId) async {
    //memberId = 5;
    final response = await http.get(Uri.parse('${baseUrl}miqaats_for_user/$memberId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load miqaats');
    }
  }

  static Future<List<dynamic>> fetchGatesForUser(int miqaatId, int memberId) async {
    final response = await http.get(Uri.parse('${baseUrl}gates_for_user/$miqaatId/$memberId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load gates');
    }
  }

  static Future<bool> insertScannedDataShort({
    required int itsId,
    required String fullName,
    required int gateId,
    required String seatNumber,
    required String gender,
    required int memberId,
    required int miqaatId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}insert-scanned-data-short'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'itsId': itsId,
          'fullName': fullName,
          'gateId': gateId,
          'seatNumber': seatNumber,
          'gender': gender,
          'memberId': memberId,
          'miqaatId': miqaatId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to insert scanned data short: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception during insertScannedDataShort: $e');
      return false;
    }
  }

  // Export Miqaat
  static Future<String> moveMiqaatData(String tableName, String miqaatId) async {
    final response = await http.post(
      Uri.parse('${baseUrl}moveMiqaatData'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tableName': tableName, 'miqaatId': miqaatId}),
    );

    if (response.statusCode == 200) {
      //openFile(tableName);
      // Get the local path where the file should be saved or accessed
      var filePath = await file_helper.getLocalPath('$tableName.xlsx');
      // This check helps avoid path issues on platforms that don't support local file storage (like web)
      if (!kIsWeb) {
        // Download the file to the path on mobile
        await Dio().download(
            '$baseUrl/downloadExcel/$tableName',
            filePath
        );
      } else {
        print("HELLO");
        // For web, this might need to handle direct download differently
        // Maybe just return a URL for direct download via the browser
        filePath = '${baseUrl}downloadExcel/$tableName';
        final html.AnchorElement anchor = html.AnchorElement(href: filePath)
          ..target = '_blank'
          ..download = '$tableName.xlsx'
          ..click();
      }
      return filePath;
    } else {
      throw Exception('Failed to move and download data');
    }
  }
}