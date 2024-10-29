import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:praca/api_handler.dart';
import 'package:praca/main.dart';
import 'package:praca/screens/qr_code_scanner.dart';


class EnterCodePage extends StatefulWidget {
  final String? code; // Make code parameter optional
  EnterCodePage({this.code});
  @override
  _EnterCodePageState createState() => _EnterCodePageState();
}

class _EnterCodePageState extends State<EnterCodePage> {
  final TextEditingController _codeController = TextEditingController();
  final ApiService _apiService = ApiService();
  String? _responseMessage;

  @override
  void initState() {
    super.initState();
    if (widget.code != null) {
      _codeController.text = widget.code!; // Prefill with QR code if available
    }
  }

  Future<void> callApi(String code) async {
    User? user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (email == null) {
      setState(() {
        _responseMessage = 'User not logged in';
      });
      return;
    }

    try {
      final response = await _apiService.startWorkShift(email, code);
      setState(() {
        _responseMessage = response.statusCode == 201 ? 'Work started' : 'Error: ${response.statusCode}';
      });
    } catch (e) {
      setState(() {
        _responseMessage = 'Failed to connect to API';
      });
    }
  }

  Future<void> _scanQRCode() async {
    final scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerScreen()),
    );

    if (scannedCode != null) {
      _codeController.text = scannedCode;
      await callApi(scannedCode);
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
                  labelText: 'Truck QR Code or Manual Entry',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.qr_code_scanner),
                    onPressed: _scanQRCode, // Open QR scanner if needed
                  ),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final code = _codeController.text;
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
