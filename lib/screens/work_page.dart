import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:praca/api_handler.dart';
import 'package:praca/main.dart';
import 'package:praca/screens/enter_code_page.dart';
import 'package:praca/screens/qr_code_scanner.dart';
import 'package:praca/screens/stop_work_screen.dart';


class WorkPage extends StatefulWidget {
  //final String? code; // Make code parameter optional
  //WorkPage({Key? key, this.code}) : super(key: key);
  @override
  _WorkPageState createState() => _WorkPageState();
}



class _WorkPageState extends State<WorkPage> {
  final TextEditingController _codeController = TextEditingController();
  final ApiService _apiService = ApiService();
  User? _user = FirebaseAuth.instance.currentUser;
  String? _responseMessage;
  bool _isWorking = false;
  bool _isBreak = false;
  String? _username;
  double _todayHours = 0;

  Future<void> _fetchworkingStatus() async {
    String? _username = _user?.email;

    if (_username != null) {
      bool workingStatus = await ApiService().isWorking(_username!);
      if(mounted){
        setState(() {
          _isWorking = workingStatus;
        });
      }
    }
    if (_isWorking){
      bool breakStatus = await ApiService().isBreak(_username!);
      if (mounted) {
        setState(() {
          _isBreak = breakStatus;
        });
      }
    }
  }

  Future<void> _fetchUserStats() async {
    User? user = FirebaseAuth.instance.currentUser;
    _username = user?.email;

    if (_username != null) {
      _todayHours = await ApiService().getUserTodayStats(_username!);

      if(mounted){
        setState(() {
          _todayHours = _todayHours;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchworkingStatus();
    _username = _user?.email;
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.lightBlueAccent,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 8),
                        Text(
                          '$_todayHours hours',
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),
                ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_isWorking) {
                      // Navigate to StopWorkScreen if working
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => StopWorkScreen()),
                      );
                    } else {
                      // Navigate to StartWorkScreen (or another screen) if not working
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => EnterCodePage()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(140, 50),
                    backgroundColor: _isWorking ? Colors.redAccent : Colors.green,
                  ),
                  child: Text(_isWorking ? 'Stop Work' : 'Start Work'),),
                ElevatedButton(
                  onPressed: (){
                    if(_isBreak){
                      ApiService().stopBreak(_username!);
                      setState(() {
                        _isBreak = false;
                      });
                    } else {
                      ApiService().startBreak(_username!);
                      setState(() {
                        _isBreak = true;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(140, 50),
                    backgroundColor: Colors.orangeAccent
                  ), 
                  child: Text(_isBreak ? 'Stop Break' : 'Take Break'),),
              ],
              ),
          ],
        ),
      ),
    );
  }
}
