import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:its_scan/api.dart';
import 'package:its_scan/scan/scan_page.dart';
import 'package:its_scan/scan/scanner_dashboard.dart';
import 'package:its_scan/secretary/secretary_dashboard.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin/admin_page.dart';
import 'package:jwt_decode/jwt_decode.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itsIdController =
      TextEditingController(); // Rename email controller
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300], // subtle grey background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400, // for desktop responsiveness
            ),
            child: Card(
              color: Colors.grey[900], // darker background color
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white, // high contrast text
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _itsIdController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'ITS ID', // Change label text to ITS ID
                          labelStyle: const TextStyle(
                            color: Colors.white,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.perm_identity,
                              color: Colors.grey[
                                  400]), // Change icon to identity-related
                          filled: true,
                          fillColor:
                              Colors.grey[800], // Consistency with other fields
                        ),
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText:
                                  'ITS ID is required'), // Change error text
                          PatternValidator(r'^\d{8}$',
                              errorText:
                                  'Must be an 8-digit number'), // Validate 8-digit number
                        ]),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.lock, color: Colors.grey[400]),
                          filled: true,
                          fillColor:
                              Colors.grey[800], // same as above for consistency
                        ),
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'Password is required'),
                          MinLengthValidator(6,
                              errorText: 'Minimum 6 characters'),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final itsId = _itsIdController.text.trim();
                            final password = _passwordController.text.trim();
                            try {
                              final userData = await ApiService.login(itsId, password); // Call LoginService
                              print(userData);
                              if (userData.role == 'scan') {
                                final prefs = await SharedPreferences.getInstance();
                                prefs.setString('userLocation',userData.mohalla_id.toString());
                                prefs.setString('userMohallaName',"AJS");
                                //print(userData.mohalla_id);
                                //print(userData.mohallaName);
                                prefs.setString('user_its',userData.itsId.toString());
                                prefs.setString('userEvent','AJS');
                                prefs.setString('user_name',userData.username);
                                prefs.setInt('user_id',userData.memberId);
                                prefs.setString('user_designation',userData.designation);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SelectMiqaatPage(), // Navigate to HomeScreen for scanners
                                  ),
                                );
                              } else if (userData.role == 'admin') {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AdminPage(), // Navigate to AdminPage for admins
                                  ),
                                );
                              } else if (userData.role == 'secretary'){
                                final prefs = await SharedPreferences.getInstance();
                                prefs.setInt('userLocation',userData.mohalla_id);
                                print(userData.mohalla_id);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SecretaryPage(), // Navigate to AdminPage for admins
                                  ),
                                );
                              }else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Unauthorized access')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Login failed: ${e.toString()}')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // Navigate to password reset or signup
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Colors.lightBlue, // more muted blue
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
