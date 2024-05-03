import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:its_scan/api.dart';
import '../models/miqaat_model.dart';

class MiqaatPage extends StatefulWidget {
  const MiqaatPage({Key? key}) : super(key: key);

  @override
  _MiqaatPageState createState() => _MiqaatPageState();
}

class _MiqaatPageState extends State<MiqaatPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _miqaatNameController = TextEditingController();
  final TextEditingController _miqaatDateController = TextEditingController();
  final TextEditingController _miqaatStatusController = TextEditingController();

  List<Miqaat> _miqaatList = [];

  @override
  void initState() {
    super.initState();
    _loadMiqaats();
  }

  Future<void> _loadMiqaats() async {
    try {
      final miqaats = await ApiService.getAllMiqaats();
      setState(() {
        _miqaatList = miqaats;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _clearForm() {
    _miqaatNameController.clear();
    _miqaatDateController.clear();
    _miqaatStatusController.clear();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showInputDialog(BuildContext context, {int? miqaatId}) {
    final isUpdating = miqaatId != null;

    if (isUpdating) {
      final miqaat = _miqaatList.firstWhere((m) => m.miqaatId == miqaatId);
      _miqaatNameController.text = miqaat.miqaatName;
      _miqaatDateController.text = miqaat.miqaatDate;
      _miqaatStatusController.text = miqaat.status;
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isUpdating ? "Update Miqaat" : "Create New Miqaat"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _miqaatNameController,
                  decoration: InputDecoration(labelText: "Miqaat Name"),
                  validator: (value) => value!.isEmpty ? "Enter Miqaat Name" : null,
                ),
                TextFormField(
                  controller: _miqaatDateController,
                  decoration: InputDecoration(
                    labelText: "Miqaat Date",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      _miqaatDateController.text =
                          DateFormat("yyyy-MM-dd").format(pickedDate);
                    }
                  },
                ),
                TextFormField(
                  controller: _miqaatStatusController,
                  decoration: InputDecoration(labelText: "Miqaat Status"),
                  validator: (value) => value!.isEmpty ? "Enter Miqaat Status" : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close the dialog
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (isUpdating) {
                    _updateMiqaat(miqaatId);
                  } else {
                    _createMiqaat();
                  }
                }
                Navigator.pop(context); // Close the dialog after success
              },
              child: Text(isUpdating ? "Update Miqaat" : "Create Miqaat"),
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
        title: const Text("Miqaat Management"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: _miqaatList.length,
        itemBuilder: (context, index) {
          final miqaat = _miqaatList[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Miqaat Name: ${miqaat.miqaatName}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text("Miqaat Date: ${miqaat.miqaatDate}"),
                  Text("Miqaat Status: ${miqaat.status}"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showInputDialog(context, miqaatId: miqaat.miqaatId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteMiqaat(miqaat.miqaatId),
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
        onPressed: () => _showInputDialog(context), // Use the correct context
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createMiqaat() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ApiService.createMiqaat(
          _miqaatNameController.text,
          _miqaatDateController.text,
          _miqaatStatusController.text,
        );
        _loadMiqaats(); // Reload after creation
        _clearForm(); // Clear form after creation
      } catch (e) {
        _showError("Error creating miqaat: ${e.toString()}");
      }
    }
  }

  Future<void> _updateMiqaat(int miqaatId) async {
    if (_formKey.currentState!.validate()) {
      try {
        await ApiService.updateMiqaat(
          miqaatId,
          _miqaatNameController.text,
          _miqaatDateController.text,
          _miqaatStatusController.text,
        );
        _loadMiqaats(); // Reload after update
        _clearForm(); // Clear form after update
      } catch (e) {
        _showError("Error updating miqaat: ${e.toString()}");
      }
    }
  }

  Future<void> _deleteMiqaat(int miqaatId) async {
    try {
      await ApiService.deleteMiqaat(miqaatId); // Delete by ID
      _loadMiqaats(); // Reload after deletion
    } catch (e) {
      _showError("Error deleting miqaat: ${e.toString()}");
    }
  }
}
