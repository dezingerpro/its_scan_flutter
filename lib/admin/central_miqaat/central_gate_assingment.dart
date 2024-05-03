import 'package:flutter/material.dart';
import '../../../api.dart';
import '../../models/gates_model.dart';
import '../../models/user_model.dart';

class GateAssignmentIntPage extends StatefulWidget {
  final List<int> memberIds;
  final int eventId;

  GateAssignmentIntPage({required this.memberIds, required this.eventId});

  @override
  _GateAssignmentIntPageState createState() => _GateAssignmentIntPageState();
}

class _GateAssignmentIntPageState extends State<GateAssignmentIntPage> {
  List<User> _members = [];
  List<Gate> _gates = [];
  Map<int, List<int>> _assignments = {};

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    _fetchGates();
    _fetchExistingAssignments();
  }

  Future<void> _fetchMembers() async {
    try {
      final members = await ApiService.fetchUsersByIds(widget.memberIds);
      setState(() {
        _members = members;
      });
    } catch (e) {
      _showError("Failed to fetch members: ${e.toString()}");
    }
  }

  Future<void> _fetchGates() async {
    try {
      final gates = await ApiService.fetchAllGates();
      setState(() {
        _gates = gates;
      });
    } catch (e) {
      _showError("Failed to fetch gates: ${e.toString()}");
    }
  }

  Future<void> _fetchExistingAssignments() async {
    try {
      final assignments = await ApiService.fetchGateAssignments(widget.eventId);
      setState(() {
        assignments.forEach((assignment) {
          _assignments.putIfAbsent(assignment.memberId, () => []).add(assignment.gateId);
        });
      });
    } catch (e) {
      _showError("Failed to fetch gate assignments: ${e.toString()}");
    }
  }

  void _assignAll() {
    setState(() {
      for (var member in _members) {
        _assignments[member.memberId] = List<int>.from(_gates.map((g) => g.gateId));
      }
    });
  }

  void _unassignAll() {
    setState(() {
      _assignments.clear();
    });
  }

  Future<void> _submitAssignments() async {
    try {
      for (var memberId in _assignments.keys) {
        final assignedGates = _assignments[memberId];
        if (assignedGates != null) {
          for (var gateId in assignedGates) {
            print('${gateId}${widget.eventId}${memberId}');
            await ApiService.createGateAssignment(gateId, widget.eventId, memberId);
          }
        }
      }
      _showSuccess("Gate assignments updated successfully!");
    } catch (e) {
      _showError("Failed to submit gate assignments: ${e.toString()}");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _addAssignment(int memberId, int gateId) {
    setState(() {
      _assignments.putIfAbsent(memberId, () => []).add(gateId);
    });
  }

  void _removeAssignment(int memberId, int gateId) {
    setState(() {
      if (_assignments[memberId]?.contains(gateId) == true) {
        _assignments[memberId]?.remove(gateId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gate Assignments"),
        actions: [
          IconButton(
            icon: Icon(Icons.group_add),
            onPressed: _assignAll,
            tooltip: "Assign all gates to all members",
          ),
          IconButton(
            icon: Icon(Icons.group_remove),
            onPressed: _unassignAll,
            tooltip: "Remove all gate assignments",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                final assignedGates = _assignments[member.memberId] ?? [];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Member: ${member.username}"),
                        Wrap(
                          spacing: 8,
                          children: assignedGates.map((gateId) {
                            final gate = _gates.firstWhere((g) => g.gateId == gateId);
                            return Chip(
                              label: Text(gate.gateName),
                              onDeleted: () => _removeAssignment(member.memberId, gateId),
                            );
                          }).toList(),
                        ),
                        DropdownButtonFormField<int>(
                          items: _gates.map((gate) {
                            return DropdownMenuItem<int>(
                              value: gate.gateId,
                              child: Text(gate.gateName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _addAssignment(member.memberId, value);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: "Assign Gate",
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ElevatedButton(
              onPressed: _submitAssignments,
              style: ElevatedButton.styleFrom(
                primary: Colors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
              child: Text("Save All Assignments"),
            ),
          ),
        ],
      ),
    );
  }
}
