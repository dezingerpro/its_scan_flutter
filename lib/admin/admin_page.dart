import 'package:flutter/material.dart';
import 'package:its_scan/admin/central_miqaat/central_export_miqaat.dart';
import 'package:its_scan/admin/central_miqaat/central_assign_members-miqaat.dart';
import 'edit_members.dart';
import 'central_miqaat/central_miqaat_dashboard.dart';
import 'miqaat_page.dart';

class AdminPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Default to 2 columns for most mobile devices, use 3 columns for larger screens
    final crossAxisCount = screenWidth > 900 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Admin!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: [
                  _buildCard(
                    context,
                    'User Management',
                    Icons.person,
                    Colors.blueAccent,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => editMembers(),
                      ),
                    ),
                  ),
                  _buildCard(
                    context,
                    'Miqaat Management',
                    Icons.event,
                    Colors.orangeAccent,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MiqaatPage(),
                      ),
                    ),
                  ),
                  _buildCard(
                    context,
                    'Export Miqaat',
                    Icons.event,
                    Colors.orangeAccent,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExportMiqaatPage(),
                      ),
                    ),
                  ),
                  _buildCard(
                    context,
                    'Initialize International Miqaat',
                    Icons.event,
                    Colors.orangeAccent,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InitMiqaat(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48, // Constant size for simplicity
                color: color,
              ),
              SizedBox(height: 16.0),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18, // Simplified text size
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
