import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:its_scan/api.dart';
import 'package:its_scan/web_socket.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Ensure this import is correct

class ScanningPage extends StatefulWidget {

  final int eventId;
  final int memberId;
  final int gateId;

  const ScanningPage({
    Key? key,
    required this.eventId,
    required this.memberId,
    required this.gateId,
  }) : super(key: key);

  @override
  _ScanningPageState createState() => _ScanningPageState();
}

class _ScanningPageState extends State<ScanningPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _results = [];
  String connectionStatus = 'Checking...';
  List<ConnectivityResult> previousResults = [];
  final Connectivity _connectivity = Connectivity();
  List<String> offlineResults = [];
  static const String baseUrl = 'ws://192.168.18.108:8080'; // Adjusted base URL
  late int eventId;
  late int memberId;
  late int gateId;
  WebSocketManager? _webSocketManager;

  @override
  void initState() {
    super.initState();
    eventId = widget.eventId;
    memberId = widget.memberId;
    gateId = widget.gateId;
    _results = [];
    loadOfflineIds();
    ApiService.sendOfflineData(memberId,eventId,gateId,DateTime.now().toIso8601String());
    offlineResults = [];
    initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    if (_webSocketManager == null) {
      _webSocketManager = WebSocketManager(baseUrl, (data) {
        parseAndSetData(data);
      });
      _webSocketManager!.connect();
    }
    _controller.addListener(_handleTextInput);
  }

  void _handleTextInput() async {
    final text = _controller.text;
    if (text.length == 8 && isNumeric(text)) {
      List<ConnectivityResult> connectivityResult =
          await _connectivity.checkConnectivity();
      bool isConnected = !connectivityResult.contains(ConnectivityResult.none);
      if (isConnected) {
        bool isDuplicate = _results.any(
            (result) => result['id'] == text); // Check if ID exists in _results
        if (isDuplicate) {
          _controller.clear(); // Clear the text field after the ID is sent
          _showScannedMessage(); // Show that ITS ID is already scanned
          return; // Exit early to avoid sending or saving duplicate data
        }
        _controller.clear(); // Clear the text field after the ID is sent
        try {
          Map<String, dynamic> statistics =
              await ApiService.sendITSIDToBackend(text,memberId,eventId,gateId,DateTime.now().toIso8601String());
          // Display the statistics
          _showStatistics(statistics);
        } catch (e) {
          _showErrorMessage(e.toString());
        }
      } else {
        _controller.clear(); // Clear the text field after the ID is sent
        // Save to local storage if offline
        saveOffline(text);
      }
    }
  }

  void _showStatistics(Map<String, dynamic> statistics) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();  // Remove current SnackBar if displayed
    print(statistics);
    String statsMessage;
    if (statistics['failedCount']>0 && statistics['failedCount']<2){
      statsMessage = 'ITS ID NOT FOUND';
    }else{
      statsMessage = 'Success: ${statistics['successCount']}, Failed: ${statistics['failedCount']}';
    }
    final snackBar = SnackBar(
      content: Text(statsMessage),
      duration: const Duration(seconds: 1), // Shorter duration might still be preferable
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showScannedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ITS ID already scanned'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange, // Different color for subtle indication
      ),
    );
  }

  // Initialize connectivity check
  Future<void> initConnectivity() async {
    List<ConnectivityResult> results;
    try {
      results = await Connectivity().checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      setState(() {
        connectionStatus = "Failed to get connectivity.";
      });
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) async {
    if (!mounted) return;

    bool wasNotConnected = previousResults.contains(ConnectivityResult.none);
    bool isConnectedNow = !results.contains(ConnectivityResult.none);

    if (isConnectedNow) {
      // Check actual internet connectivity by making an HTTP request
      try {
        print("hello");
        final response = await http.get(Uri.parse('${ApiService.baseUrl}health-check'));
        print("HIII");
        print(response.statusCode);
        if (response.statusCode == 200) {
          setState(() {
            connectionStatus = 'Connected';
          });
          if (wasNotConnected && previousResults.isNotEmpty) {
            // Only trigger when there's a real transition from no connection
            print("HERE");
            performActionOnConnected();
          }
        } else {
          // Connected to a network, but no internet access
          setState(() {
            connectionStatus = 'Connected to Wi-Fi but no Internet';
          });
        }
      } catch (e) {
        print(e);
        // Handle no internet access
        setState(() {
          connectionStatus = 'Connected to Wi-Fi but no Internet';
        });
      }
    } else {
      setState(() {
        connectionStatus = 'Not Connected';
      });
    }
    previousResults = List.from(results); // Update previous results
  }


  // Define what to do when the device connects to the internet
  Future<void> performActionOnConnected() async {
    try {
      //_connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
      _webSocketManager = WebSocketManager(baseUrl, (data) {
        parseAndSetData(data);
      });
      _webSocketManager!.connect();
      // Perform other actions when reconnecting
      Map<String, dynamic> statistics = await ApiService.sendOfflineData(memberId,eventId,gateId,DateTime.now().toIso8601String());
      //ApiService.sendOfflineData();  // Send offline data to backend
      offlineResults = [];
      setState(() {});
      // Display the statistics
      _showStatistics(statistics);
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  // Load offline IDs from SharedPreferences when the app starts
  Future<void> loadOfflineIds() async {
    final prefs = await SharedPreferences.getInstance();
    offlineResults = prefs.getStringList('offlineIds') ?? [];
    //setState(() {});
  }

  // void saveOffline(String id) async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     List<String> offlineIds = (prefs.getStringList('offlineIds') ?? []);
  //     offlineIds.add(id);
  //     await prefs.setStringList('offlineIds', offlineIds);
  //     _controller.clear();
  //   } catch (e) {
  //     // Handle the error by showing an alert dialog
  //     _showErrorDialog(e.toString());
  //   }
  // }

  void saveOffline(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      offlineResults.add(id); // Add to in-memory list
      await prefs.setStringList('offlineIds', offlineResults);
      _controller.clear();
      setState(() {}); // Refresh UI to reflect the changes in the list
    } catch (e) {
      // Handle the error by showing an alert dialog
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('An Error Occurred'),
        content: Text(errorMessage),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }

  Future<void> parseAndSetData(String data) async {
    List<Map<String, String>> parsedResults = [];
    var entries = data.split(';');
    Set<String> existingIds = _results
        .map((result) => result['id']!)
        .toSet(); // Get set of existing IDs

    for (var entry in entries) {
      var details = entry.split(',');
      if (details.length >= 2) {
        String id = details[0];
        if (!existingIds.contains(id)) {
          // Only add if the ID is unique
          parsedResults.add({'id': id, 'name': details[1]});
          existingIds.add(id); // Update the set of existing IDs
        }
      }
    }

    setState(() {
      _results.addAll(parsedResults); // Add only unique results
    });
  }

  @override
  void dispose() {
    _webSocketManager!.close();
    _controller.dispose();
    super.dispose();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    IconData connectionIcon;
    Color iconColor;

    // Determine the icon and color based on the connection status
    if (connectionStatus == 'Connected') {
      connectionIcon = Icons.wifi; // Wi-Fi icon for connected
      iconColor = Colors.green; // Green for connected
    } else if (connectionStatus == 'Connected to Wi-Fi but no Internet') {
      connectionIcon = Icons.signal_wifi_off; // Wi-Fi icon with a cross for no internet
      iconColor = Colors.orange; // Orange to indicate Wi-Fi but no internet
    } else {
      connectionIcon = Icons.signal_wifi_off; // No Wi-Fi icon for disconnected
      iconColor = Colors.red; // Red for disconnected
    }

    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SCAN ITS ID'),
          backgroundColor: Colors.deepPurple, // Enhanced color scheme
          actions: [
            // Add the connectivity icon to the AppBar
            Tooltip(
              // Provide a tooltip for additional information
              message: connectionStatus == 'Connected' ? 'Connected to the internet' :
              connectionStatus == 'Connected to Wi-Fi but no Internet' ? 'Connected to Wi-Fi but no internet access' :
              'Not connected to the internet',
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Icon(
                  connectionIcon, // Display the appropriate icon
                  color: iconColor, // Use the determined color
                  size: 24, // Smaller size for subtlety
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter ITS ID',
                  hintText: '12345678',
                  border: OutlineInputBorder(), // Enhanced input decoration
                  prefixIcon: Icon(Icons.key), // Icon for visual hint
                ),
                maxLength: 8,
              ),
            ),
            const SizedBox(height: 10), // Spacing between elements
            const TabBar(
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepPurple,
              tabs: [
                Tab(text: 'Online Scanned'),
                Tab(text: 'Offline Scanned'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  buildOnlineScannedList(),
                  buildOfflineScannedList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOnlineScannedList() {
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        var result = _results[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          child: ListTile(
            title: Text(result['name'] ?? 'No name',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(result['id'] ?? 'No ID'),
            leading: const Icon(Icons.person),
          ),
        );
      },
    );
  }

  Widget buildOfflineScannedList() {
    return ListView.builder(
      itemCount: offlineResults.length,
      itemBuilder: (context, index) {
        var id = offlineResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          child: ListTile(
            title: Text(id),
            subtitle: const Text('Offline Scanned ID'),
            leading: const Icon(Icons.person_outline),
          ),
        );
      },
    );
  }
}
