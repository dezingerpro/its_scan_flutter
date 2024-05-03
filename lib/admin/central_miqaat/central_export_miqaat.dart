import 'package:flutter/material.dart';
import 'package:its_scan/api.dart';
import '../../models/miqaat_model.dart';

class ExportMiqaatPage extends StatefulWidget {
  @override
  _ExportMiqaatPageState createState() => _ExportMiqaatPageState();
}

class _ExportMiqaatPageState extends State<ExportMiqaatPage> {
  List<Miqaat> miqaats = [];
  Miqaat? selectedMiqaat;

  @override
  void initState() {
    super.initState();
    ApiService.getAllMiqaats().then((data) {
      setState(() {
        miqaats = data;
      });
    });
  }

  bool _isLoading = false;

  void handleExport() {
    if (selectedMiqaat == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('No Selection'),
          content: Text('Please select a Miqaat first.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
      return; // Exit if no Miqaat is selected
    }
    ApiService.moveMiqaatData(selectedMiqaat!.miqaatName, selectedMiqaat!.miqaatId.toString());
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(ctx). pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Export Miqaat'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (miqaats.isNotEmpty) ...[
              DropdownButton<Miqaat>(
                value: selectedMiqaat,
                onChanged: (Miqaat? newValue) {
                  setState(() {
                    selectedMiqaat = newValue;
                  });
                },
                items: miqaats.map<DropdownMenuItem<Miqaat>>((Miqaat miqaat) {
                  return DropdownMenuItem<Miqaat>(
                    value: miqaat,
                    child: Text(miqaat.miqaatName),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : handleExport,
                child: _isLoading ? CircularProgressIndicator() : Text('Export and Download Data'),
              )
            ]
          ],
        ),
      ),
    );
  }
}
