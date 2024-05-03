import 'package:flutter/material.dart';
import 'package:its_scan/api.dart';
import 'package:its_scan/models/user_model.dart';

class editMembers extends StatefulWidget {
  @override
  _editMembersState createState() => _editMembersState();
}

class _editMembersState extends State<editMembers> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _itsIdController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _mohallaController = TextEditingController();
  String _selectedMohallaName = ''; // New variable to store the displayed name

  List<Map<String, dynamic>> _users = []; // To store fetched users
  List<Map<String, dynamic>> _mohallas = []; // To store fetched Mohallas
  final List<String> _roles = ["admin", "secretary", "scan"];
  final List<String> _designations = ["Secretary", "Office Bearer", "Member", "admin"];

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Load users on initialization
    _fetchMohallas(); // Load Mohallas
  }

  Future<void> _fetchMohallas() async {
    try {
      // Fetch Mohallas from the API
      final mohallas = await ApiService.fetchMohallas();

      // Convert to List<Map<String, dynamic>>
      final mohallaMaps = mohallas.map((mohalla) => mohalla.toJson()).toList();

      setState(() {
        _mohallas = mohallaMaps; // Store the converted list
      });

    } catch (e) {
      _showError("Failed to fetch Mohallas: ${e.toString()}"); // Display error message
    }
  }

  Future<void> _deleteUser(String itsId) async {
    try {
      await ApiService.deleteUser(itsId); // Use ApiService to delete user
      _fetchUsers(); // Refresh the list
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await ApiService.fetchAllUsers(); // Fetch all users from the API
      setState(() {
        _users = users.map((user) => user.toJson()).toList(); // Convert to a list of maps
      });
    } catch (e) {
      _showError("Failed to fetch users: ${e.toString()}"); // Display error
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)), // Show error feedback
    );
  }

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = User(
          memberId: 0, // Auto-increment
          itsId: int.parse(_itsIdController.text),
          username: _usernameController.text,
          password: _itsIdController.text, // Placeholder
          role: _roleController.text,
          mohalla_id: int.parse(_mohallaController.text), // Convert to int
          designation: _designationController.text,
        );

        await ApiService.createUser(user.toJson()); // Create user with Mohalla ID
        _fetchUsers(); // Refresh the list
        _clearForm(); // Clear the form
      } catch (e) {
        _showError("Error creating user: ${e.toString()}");
      }
    }
  }

  Future<void> _updateUser(String itsId) async {
    if (_formKey.currentState!.validate()) {
      try {
        final userData = {
          'name': _usernameController.text,
          'role': _roleController.text,
          'mohalla_id': int.parse(_mohallaController.text), // Convert to int
          'designation': _designationController.text,
        };
        await ApiService.updateUser(itsId, userData); // Update user
        _fetchUsers(); // Refresh the list
        _clearForm(); // Clear the form
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  void _clearForm() {
    _itsIdController.clear();
    _usernameController.clear();
    _roleController.clear();
    _mohallaController.clear();
    _designationController.clear();
  }

  void _showInputDialog(BuildContext context, {int? itsId}) {
    final isUpdating = itsId != null;
    if (isUpdating) {
      final user = _users.firstWhere((u) => u['its_id'] == itsId);
      _itsIdController.text = user['its_id'].toString();
      _usernameController.text = user['name'];
      _roleController.text = user['role'];
      _mohallaController.text = user['mohalla_id'].toString(); // Store the ID
      // Find the corresponding name and store it in _selectedMohallaName
      final selectedMohalla = _mohallas.firstWhere(
            (m) => m['mohalla_id'].toString() == _mohallaController.text,
      );
      _selectedMohallaName = selectedMohalla['mohalla_name'];
    } else {
      _clearForm();
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isUpdating ? "Update User" : "Add New User"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _itsIdController,
                  decoration: const InputDecoration(
                    labelText: 'ITS ID',
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter ITS ID' : null,
                ),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter Username' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _roleController.text.isNotEmpty ? _roleController.text : null,
                  items: _roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _roleController.text = value!;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Role',
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: _designationController.text.isNotEmpty
                      ? _designationController.text
                      : null,
                  items: _designations.map((designation) {
                    return DropdownMenuItem(
                      value: designation,
                      child: Text(designation),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _designationController.text = value!;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Designation',
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedMohallaName.isNotEmpty ? _selectedMohallaName : null, // Use _selectedMohallaName
                  items: _mohallas.map((mohalla) {
                    final mohallaName = mohalla['mohalla_name'] as String;
                    return DropdownMenuItem(
                      value: mohallaName,
                      child: Text(mohallaName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    // Find the corresponding ID for the selected name
                    final selectedMohalla = _mohallas.firstWhere(
                          (m) => m['mohalla_name'] == value,
                    );
                    _selectedMohallaName = value!; // Update displayed name
                    _mohallaController.text = selectedMohalla['mohalla_id'].toString(); // Store Mohalla ID
                  print(_mohallaController.text);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Mohalla',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (isUpdating) {
                  print("YAHA CHE MASLO");
                  _updateUser(itsId.toString());
                } else {
                  _createUser();
                }
                Navigator.pop(context); // Close dialog
              },
              child: Text(isUpdating ? "Update User" : "Create User"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin User CRUD'),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ITS ID: ${user['its_id']}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text("Username: ${user['name']}"),
                  Text("Role: ${user['role']}"),
                  Text("Mohalla ID: ${user['mohalla_id']}"),
                  Text("Designation: ${user['designation']}"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showInputDialog(context, itsId: user['its_id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteUser(user['its_id']),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInputDialog(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
