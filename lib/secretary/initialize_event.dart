import 'package:flutter/material.dart';

import '../api.dart';
import 'gate_assingment.dart';

class InitializeEventPage extends StatefulWidget {
  final String selectedEvent;
  final int eventId;
  InitializeEventPage({required this.selectedEvent,required this.eventId});

  @override
  _InitializeEventPageState createState() => _InitializeEventPageState(eventId);
}

class _InitializeEventPageState extends State<InitializeEventPage> {
  int eventIds = 0;
  List<Map<String, dynamic>> members = []; // List of all members
  List<int> selectedMembers = []; // IDs of selected members
  bool selectAll = false; // Toggle for "Select All"
  bool isLoading = true;

  _InitializeEventPageState(eventId){
    eventIds = eventId;
  }


  @override
  void initState() {
    super.initState();
    _fetchMembers(); // Fetch members on initialization
  }

  Future<void> _fetchMembers() async {
    try {
      final membersList = await ApiService.fetchAllUsers(); // Fetch all users
      final memberNames = membersList.map((member) => {
        'id': member.memberId, // Use the correct field for 'id'
        'name': member.username.isNotEmpty ? member.username : 'Unknown', // Default to 'Unknown' if empty
      }).toList(); // Convert each User object to a Map with 'id' and 'name'

      setState(() {
        members = memberNames; // Store the processed list
        isLoading = false; // Indicate loading is complete
      });
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading on error
      });
      _showError("Failed to fetch members: ${e.toString()}"); // Provide an error message
    }
  }

  void _showError_(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)), // Display the error in a snack bar
    );
  }

  void _toggleSelectAll() {
    setState(() {
      if (selectAll) {
        selectedMembers = [];
        selectAll = false;
      } else {
        selectedMembers = members
            .map((m) => m['id']) // Use the original value
            .whereType<int>() // Keep only `int` values, discarding non-int or null
            .toList();
        selectAll = true;
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _assignMembersToMiqaat() async {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GateAssignmentPage(memberIds: selectedMembers, eventId: eventIds),
      ),
    );
    // try {
    //   await ApiService.assignMembersToMiqaat(widget.selectedEvent as int, selectedMembers); // Send to API
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text("Members assigned to miqaat '${widget.selectedEvent}' successfully")),
    //   );
    //   Navigator.pop(context); // Navigate back upon success
    // } catch (e) {
    //   _showError("Error assigning members: ${e.toString()}");
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Initialize Event: ${widget.selectedEvent}"),
        backgroundColor: Colors.indigo,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Loading indicator while fetching
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _toggleSelectAll, // Select All / Unselect All
              child: Text(selectAll ? "Unselect All" : "Select All"),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final memberId = member['id']; // Ensure non-null value

                  return CheckboxListTile(
                    title: Text(member['name']), // Display only the member's name
                    value: selectedMembers.contains(memberId), // Ensure value is valid
                    onChanged: (bool? value) {
                      if (memberId != null) { // Check if ID is valid
                        setState(() {
                          if (value!) {
                            selectedMembers.add(memberId);
                          } else {
                            selectedMembers.remove(memberId);
                          }
                        });
                      }
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _assignMembersToMiqaat, // Assign selected members to the event
              child: const Text("Assign Members"),
            ),
          ],
        ),
      ),
    );
  }
}
