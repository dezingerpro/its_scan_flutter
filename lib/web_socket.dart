import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketManager {
  WebSocketChannel? channel;
  final String uri;
  final Function(String) onMessage;
  List<String> initialData = [];
  bool _isConnected = false;

  WebSocketManager(this.uri, this.onMessage);

  Future<void> connect() async {
    if (channel != null && channel!.closeCode == null) {
      print("WebSocket is already connected.");
      return;
    }

    // Retrieve the userLocation from shared preferences
    final prefs = await SharedPreferences.getInstance();
    String userLocation = prefs.getString('userLocation') ?? 'default';
    String userEvent = prefs.getString('userEvent') ?? 'default'; // Retrieve event from shared preferences
    print("$userLocation$userEvent");
    userLocation = "AJS";
    userEvent = "AJS";

    // Create WebSocket URI with location and event as query parameters
    final locationBasedUri = '$uri?location=$userLocation&event=$userEvent';

    _isConnected = true;
    channel = WebSocketChannel.connect(Uri.parse(locationBasedUri)); // Use location-based URI
    channel!.stream.listen(
            (data) {
          // Handle received data
          if (data is String) {
            onMessage(data);
          } else if (data is List<int>) {
            // Handle binary data received as List<int>
            String decodedData = utf8.decode(data);
            onMessage(decodedData);
          }
        },
        onDone: () {
          print("WebSocket connection closed.");
          onDisconnected();  // Handle disconnection
        },
        onError: (error) {
          print("WebSocket error: $error");
          onError(error);  // Improved error handling
        }
    );
  }

  bool isConnected() {
    return _isConnected;
  }

  void send(String message) {
    if (channel != null && channel!.closeCode == null) {
      channel!.sink.add(message);
      print("Message sent: $message");
    } else {
      print("Connection is closed or not established. Reconnecting...");
      connect();  // Reconnect if the connection is not active
      initialData.add(message);  // Queue the message to be sent after reconnection
    }
  }

  void onDisconnected() {
    _isConnected = false;
    print("Handling disconnection, attempting to reconnect...");
    connect();  // Automatically try to reconnect
  }

  void onError(dynamic error) {
    _isConnected = false;
    print("Error encountered, trying to reconnect...");
    connect();  // Automatically reconnect on error
  }

  void close() {
    _isConnected = false;
    if (channel != null) {
      channel!.sink.close();
      print("WebSocket manually closed.");
    }
  }
}