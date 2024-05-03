import 'package:flutter/material.dart';
import 'package:its_scan/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'initialize_event.dart';
import '../models/gates_model.dart';

class SecretaryPage extends StatefulWidget {
  @override
  _SecretaryPageState createState() => _SecretaryPageState();
}

class _SecretaryPageState extends State<SecretaryPage> {
  List<Map<String, dynamic>> miqaats = []; // Store Miqaat ID and name
  List<Gate> _gates = []; // Store Gate data
  bool isLoading = true; // For loading state

  @override
  void initState() {
    super.initState();
    _fetchMiqaats(); // Fetch Miqaat names on initialization
    _fetchGates(); // Fetch Gates on initialization
  }

  Future<void> _fetchMiqaats() async {
    try {
      final fetchedMiqaats = await ApiService.getAllMiqaats(); // Fetch all Miqaats
      setState(() {
        miqaats = fetchedMiqaats.map((miqaat) {
          return {
            'miqaat_id': miqaat.miqaatId, // Fetch the ID
            'miqaat_name': miqaat.miqaatName, // Fetch the name
          };
        }).toList(); // Convert to list of maps
        isLoading = false; // Stop loading when fetched
      });
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading on error
      });
      _showError(e.toString());
    }
  }

  Future<void> _fetchGates() async {
    try {
      final fetchedGates = await ApiService.fetchAllGates(); // Fetch all Gates
      setState(() {
        _gates = fetchedGates; // Store fetched Gates
      });
    } catch (e) {
      _showError("Failed to fetch Gates: ${e.toString()}");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $message")), // Display error message
    );
  }

  // Dialog to add or edit a gate
  void _showGateDialog(BuildContext context, {Gate? gate}) {
    final gateNameController = TextEditingController(text: gate?.gateName ?? '');
    final isEditing = gate != null; // Check if the dialog is for editing or creating

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? "Edit Gate" : "Create New Gate"),
          content: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: gateNameController,
                  decoration: const InputDecoration(labelText: "Gate Name"),
                  validator: (value) => value!.isEmpty ? "Enter Gate Name" : null,
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
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                int mohalla_id = prefs.getInt('userLocation') as int;
                if (isEditing) {
                  _updateGate(gate.gateId, gateNameController.text,mohalla_id); // Update gate
                } else {
                  _createGate(gateNameController.text,mohalla_id); // Create gate
                }
                Navigator.pop(context); // Close dialog
              },
              child: Text(isEditing ? "Update Gate" : "Create Gate"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createGate(String gateName, int mohallaId) async {
    try {
      await ApiService.createGate(gateName, mohallaId); // Create a new gate
      _fetchGates(); // Reload the gate list after creation
    } catch (e) {
      _showError("Error creating gate: ${e.toString()}");
    }
  }

  Future<void> _updateGate(int gateId, String gateName, int mohallaId) async {
    try {
      await ApiService.updateGate(gateId, gateName, mohallaId); // Update the gate
      _fetchGates(); // Reload after updating
    } catch (e) {
      _showError("Error updating gate: ${e.toString()}");
    }
  }

  Future<void> _deleteGate(int gateId) async {
    try {
      await ApiService.deleteGate(gateId); // Delete gate
      _fetchGates(); // Refresh gate list
    } catch (e) {
      _showError("Error deleting gate: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secretary Dashboard"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? Center(child: CircularProgressIndicator()) // Display loading indicator
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => CreateEventPage()),
                // );
              },
              child: const Text("Create Local Event"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: const InputDecoration(
                labelText: "Select Miqaat to Initialize",
              ),
              items: miqaats.map((miqaat) {
                return DropdownMenuItem(
                  value: miqaat, // Map containing Miqaat ID and name
                  child: Text(miqaat['miqaat_name']), // Display Miqaat name
                );
              }).toList(),
              onChanged: (selectedMiqaat) {
                // Navigate to InitializeEventPage with the selected Miqaat's details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InitializeEventPage(
                      selectedEvent: selectedMiqaat!['miqaat_name'],
                      eventId: selectedMiqaat['miqaat_id'], // Pass Miqaat ID
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              "Gate Management",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _gates.length, // Number of Gates
                itemBuilder: (context, index) {
                  final gate = _gates[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text("Gate: ${gate.gateName}"),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showGateDialog(context, gate: gate); // Edit gate
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteGate(gate.gateId); // Delete gate
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showGateDialog(context); // Create new gate
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
