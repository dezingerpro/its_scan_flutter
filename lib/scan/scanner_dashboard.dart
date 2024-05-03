import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_screen.dart';
import 'scan_page.dart';
import '../api.dart';

class SelectMiqaatPage extends StatefulWidget {
  const SelectMiqaatPage({Key? key}) : super(key: key);

  @override
  _SelectMiqaatPageState createState() => _SelectMiqaatPageState();
}

class _SelectMiqaatPageState extends State<SelectMiqaatPage> {
  final String _selectedMiqaat = '';
  String _itsId = '';
  String _name = '';
  String _designation = '';
  String _mohalla = '';
  List<dynamic> miqaats = [];
  List<dynamic> gates = [];
  int? selectedMiqaatId;
  int? selectedGateId;
  int? memberId;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    fetchMiqaats();
  }

  void fetchMiqaats() async {
    final prefs = await SharedPreferences.getInstance();
    memberId = prefs.getInt('user_id') as int; // Assuming this is fetched from a logged-in user's data
    miqaats = await ApiService.fetchMiqaatsForUser(memberId!);
    setState(() {});
  }

  void fetchGates() async {
    if (selectedMiqaatId != null) {
      gates = await ApiService.fetchGatesForUser(selectedMiqaatId!, memberId!); // Use actual member ID
      setState(() {});
    }
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _itsId = prefs.getString('user_its') ?? '';
      _name = prefs.getString('user_name') ?? '';
      _designation = prefs.getString('user_designation') ?? '';
      _mohalla = prefs.getString('userLocation') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Miqaat'),
        backgroundColor: theme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            UserInfoCard(itsId: _itsId, name: _name, designation: _designation, mohalla: _mohalla, onLogout: () {Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const LoginPage(), // Navigate to HomeScreen for scanners
              ),
            );  },),
            const SizedBox(height: 30),
            MiqaatSelection(
              miqaats: miqaats,
              selectedMiqaatId: selectedMiqaatId,
              onMiqaatChanged: (int? newValue) {
                setState(() {
                  selectedMiqaatId = newValue;
                  selectedGateId = null; // Reset gates when Miqaat changes
                  gates = []; // Clear previous gates
                  fetchGates();
                });
              },
            ),
            GateSelection(
              gates: gates,
              selectedGateId: selectedGateId,
              onGateChanged: (int? newValue) {
                setState(() {
                  selectedGateId = newValue;
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                prefs.setString('userEvent', _selectedMiqaat);
                if (selectedMiqaatId != null && memberId != null && selectedGateId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScanningPage(
                        eventId: selectedMiqaatId!,
                        memberId: memberId!,
                        gateId: selectedGateId!,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Start Scanning', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class UserInfoCard extends StatelessWidget {
  final String itsId, name, designation, mohalla;
  final VoidCallback onLogout;

  const UserInfoCard({
    Key? key,
    required this.itsId,
    required this.name,
    required this.designation,
    required this.mohalla,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Information',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.primaryColor),
              ),
              Icon(Icons.person_pin, color: theme.primaryColor, size: 30),
            ],
          ),
          const SizedBox(height: 20),
          UserInfoRow(icon: Icons.credit_card, label: 'ITS ID', value: itsId),
          UserInfoRow(icon: Icons.person, label: 'Name', value: name),
          UserInfoRow(icon: Icons.work, label: 'Designation', value: designation),
          UserInfoRow(icon: Icons.location_city, label: 'Mohalla', value: mohalla),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Logout'),
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // Logout button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const UserInfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class MiqaatSelection extends StatelessWidget {
  final List<dynamic> miqaats;
  final int? selectedMiqaatId;
  final ValueChanged<int?> onMiqaatChanged;

  const MiqaatSelection({
    Key? key,
    required this.miqaats,
    this.selectedMiqaatId,
    required this.onMiqaatChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Miqaat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.deepPurple),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              hint: const Text('Select Miqaat'),
              value: selectedMiqaatId,
              onChanged: onMiqaatChanged,
              items: miqaats.map<DropdownMenuItem<int>>((dynamic value) {
                return DropdownMenuItem<int>(
                  value: value['miqaat_id'],
                  child: Text(value['miqaat_name']),
                );
              }).toList(),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }
}

class GateSelection extends StatelessWidget {
  final List<dynamic> gates;
  final int? selectedGateId;
  final ValueChanged<int?> onGateChanged;

  const GateSelection({
    Key? key,
    required this.gates,
    this.selectedGateId,
    required this.onGateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Gate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.deepPurple),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              hint: const Text('Select Gate'),
              value: selectedGateId,
              onChanged: onGateChanged,
              items: gates.map<DropdownMenuItem<int>>((dynamic value) {
                return DropdownMenuItem<int>(
                  value: value['gate_id'],
                  child: Text(value['gate_name']),
                );
              }).toList(),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }
}
