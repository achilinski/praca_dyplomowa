import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:praca/api_handler.dart';
import 'package:praca/main.dart';
import 'package:praca/screens/qr_code_scanner.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EnterCodePage extends StatefulWidget {
  final String? code; // Make code parameter optional
  EnterCodePage({this.code});
  @override
  _EnterCodePageState createState() => _EnterCodePageState();
}

class _EnterCodePageState extends State<EnterCodePage> {
  final TextEditingController _codeController = TextEditingController();
  final ApiService _apiService = ApiService();
  User? _user = FirebaseAuth.instance.currentUser;
  String? _responseMessage;
  String? _username;
  Map<String, LatLng>? _gpsPoints;

  @override
  void initState() {
    super.initState();
    if (widget.code != null) {
      _codeController.text = widget.code!; // Prefill with QR code if available
    }
    _username = _user?.email;
    _fetchGpsPoints(); // Fetch GPS points on initialization
  }

  Future<void> _fetchGpsPoints() async {
    try {
      final points = await _apiService.getAllGpsPoints();
      setState(() {
        _gpsPoints = points;
      });
    } catch (e) {
      print('Error fetching GPS points: $e');
      setState(() {
        _gpsPoints = {};
      });
    }
  }

  Future<void> callApi(String code) async {
    final email = _user?.email;

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
      appBar: AppBar(
        title: Text('Enter Code'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigates back to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 30),
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
                  ).then((value) => setState(() {}));
                }
              },
              child: Text('Submit'),
            ),
            SizedBox(height: 20),
            if (_responseMessage != null) Text('Response: $_responseMessage'),
            Expanded(
              child: _gpsPoints == null
                  ? Center(child: CircularProgressIndicator())
                  : _gpsPoints!.isEmpty
                      ? Center(child: Text('No GPS points available'))
                      : ListView.builder(
                          itemCount: _gpsPoints!.length,
                          itemBuilder: (context, index) {
                            String name = _gpsPoints!.keys.elementAt(index);
                            LatLng location = _gpsPoints![name]!;
                            return ListTile(
                              title: Text(name),
                              subtitle: Text('Lat: ${location.latitude}, Long: ${location.longitude}'),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
