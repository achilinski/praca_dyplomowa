import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:praca/api_handler.dart';
import 'package:praca/main.dart';
 // Import the API service

class EnterCodePage extends StatefulWidget {
  @override
  _EnterCodePageState createState() => _EnterCodePageState();
}

class _EnterCodePageState extends State<EnterCodePage> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService(); // Initialize the API service
  String? _responseMessage;

  // Function to call the API using the service
  Future<void> callApi(String code) async {
    User? user = FirebaseAuth.instance.currentUser;
    final email = user?.email; // Get the email of the currently logged in user

    if (email == null) {
      setState(() {
        _responseMessage = 'User not logged in';
      });
      return;
    }

    try {
      final response = await _apiService.startWorkShift(email, code);
      if (response.statusCode == 201) {
        setState(() {
          _responseMessage = 'Work started';
        });
      } else if (response.statusCode == 200) {
        setState(() {
          _responseMessage = jsonDecode(response.body)['message']; // Customize as per API response
        });
      } else {
        setState(() {
          _responseMessage = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'Failed to connect to API';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Code')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter a number (code)',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final code = _controller.text;
                if (code.isNotEmpty) {
                  await callApi(code);
                }

                // Navigate if work started successfully
                if (_responseMessage == 'Work started') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                    ModalRoute.withName('/'),
                  ).then((value) => setState(() {
                  }));
                }
              },
              child: Text('Submit'),
            ),
            SizedBox(height: 20),
            if (_responseMessage != null)
              Text('Response: $_responseMessage'),
          ],
        ),
      ),
    );
  }
}
