import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:praca/api_handler.dart';
import 'package:praca/main.dart';


class StopWorkScreen extends StatefulWidget {
  @override
  _StopWorkScreenState createState() => _StopWorkScreenState();
}

class _StopWorkScreenState extends State<StopWorkScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _milageController = TextEditingController();
  final ApiService _apiService = ApiService(); // Initialize the API service
  String? _responseMessage;

  Future<void> callApi(String code, String milage) async {
    User? user = FirebaseAuth.instance.currentUser;
    final email = user?.email; // Get the email of the currently logged in user

    if (email == null) {
      setState(() {
        _responseMessage = 'User not logged in';
      });
      return;
    }

    try {
      final response = await _apiService.stopWorkShift(email, code);
      if (response.statusCode == 200) {
        setState(() {
          _responseMessage = 'Work stopped';
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
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Enter a number (code)',
              ),
            ),
            TextField(
              controller: _milageController,
              decoration: InputDecoration(
                labelText: 'Enter milage'),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final code = _codeController.text;
                final milage = _milageController.text;
                if (code.isNotEmpty) {
                  await callApi(code, milage);
                }
                // Navigate if work started successfully
                if (_responseMessage == 'Work stopped') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                    ModalRoute.withName('/'),
                  ).then((value) => setState(() {
                  }));;
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