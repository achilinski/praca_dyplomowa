import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:praca/api_handler.dart';
import 'package:praca/main.dart';
import 'package:praca/screens/qr_code_scanner_stop.dart';

class StopWorkScreen extends StatefulWidget {
  final String? code; // Make code parameter optional

  StopWorkScreen({this.code});

  @override
  _StopWorkScreenState createState() => _StopWorkScreenState();
}

class _StopWorkScreenState extends State<StopWorkScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _milageController = TextEditingController();
  final ApiService _apiService = ApiService();
  String? _responseMessage;

  @override
  void initState() {
    super.initState();
    if (widget.code != null) {
      _codeController.text = widget.code!; // Prefill with QR code if available
    }
  }

  Future<void> callApi(String code, String milage) async {
    User? user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

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

  Future<void> _scanQRCode() async {
    final scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerStopScreen()),
    );

    if (scannedCode != null) {
      setState(() {
        _codeController.text = scannedCode; // Update the code field with scanned data
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stop Work')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Truck QR Code or Manual Entry',
                suffixIcon: IconButton(
                  icon: Icon(Icons.qr_code_scanner),
                  onPressed: _scanQRCode, // Open QR scanner if needed
                ),
              ),
            ),
            TextField(
              controller: _milageController,
              decoration: InputDecoration(labelText: 'Enter mileage'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final code = _codeController.text;
                final milage = _milageController.text;
                if (code.isNotEmpty && milage.isNotEmpty) {
                  await callApi(code, milage);
                }

                if (_responseMessage == 'Work stopped') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                    ModalRoute.withName('/'),
                  );
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
