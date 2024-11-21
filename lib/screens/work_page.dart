import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:praca/api_handler.dart';
import 'package:praca/main.dart';
import 'package:praca/screens/enter_code_page.dart';
import 'package:praca/screens/qr_code_scanner.dart';
import 'package:praca/screens/stop_work_screen.dart';
import 'package:url_launcher/url_launcher.dart';


class WorkPage extends StatefulWidget {
  //final String? code; // Make code parameter optional
  //WorkPage({Key? key, this.code}) : super(key: key);
  final LatLng? firstPoint;
  WorkPage({this.firstPoint});
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
  //String _todayHours = '0:00';
  LatLng? _currentPosition;

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

  Future<void> _fetchBreakStatus() async{
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
      String formattedTime = await ApiService().getUserTodayStats(_username!);

      if (mounted) {
        setState(() {
          _responseMessage = formattedTime; // Store the formatted time
        });
      }
    }
  }

  void _openGoogleMaps(LatLng destination) async {
    final Uri googleMapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving');

    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open Google Maps.';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchworkingStatus();
    _fetchUserStats();
    _username = _user?.email;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled){
      print('Location service are disabled');
      return;
    }
    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied){
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.denied){
        print("denied");
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

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
                      color: Colors.grey[900],
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 8),
                        Text(
                          _responseMessage ?? '0:00',
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StopWorkScreen()),
                      );
                    } else {
                      // Navigate to StartWorkScreen (or another screen) if not working
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EnterCodePage()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(140, 50),
                    backgroundColor: _isWorking ? Colors.redAccent : Colors.green,
                    foregroundColor: Colors.white,
                    textStyle:TextStyle(color: Colors.white)
                  ),
                  child: Text(_isWorking ? 'Stop Work' : 'Start Work'),),
                ElevatedButton(
                  onPressed: () async {
                    if(_isBreak){
                      await ApiService().stopBreak(_username!);
                    } else {
                      await ApiService().startBreak(_username!);
                    }
                    _fetchBreakStatus();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(140, 50),
                    backgroundColor: Colors.grey[900],
                    foregroundColor: Colors.white,
                    textStyle:TextStyle(color: Colors.white)
                  ), 
                  child: Text(_isBreak ? 'Stop Break' : 'Take Break'),),
              ],
              ),
              SizedBox(height: 10,),
              Expanded(
                child: _currentPosition == null
                    ? Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition!,
                          zoom: 14, // Default zoom level
                        ),
                        myLocationEnabled: true,
                        markers: {
                          if (widget.firstPoint != null)
                            Marker(
                              markerId: MarkerId('firstPoint'),
                              position: widget.firstPoint!,
                              infoWindow: InfoWindow(
                                title: 'Destination',
                                snippet: 'Tap to navigate',
                                onTap: () {
                                  _openGoogleMaps(widget.firstPoint!);
                                },
                              ),
                            ),
                        },
                        onMapCreated: (GoogleMapController controller) {
                          if (_currentPosition != null && widget.firstPoint != null) {
                            // Adjust the camera to include both points
                            LatLngBounds bounds = LatLngBounds(
                              southwest: LatLng(
                                _currentPosition!.latitude < widget.firstPoint!.latitude
                                    ? _currentPosition!.latitude
                                    : widget.firstPoint!.latitude,
                                _currentPosition!.longitude < widget.firstPoint!.longitude
                                    ? _currentPosition!.longitude
                                    : widget.firstPoint!.longitude,
                              ),
                              northeast: LatLng(
                                _currentPosition!.latitude > widget.firstPoint!.latitude
                                    ? _currentPosition!.latitude
                                    : widget.firstPoint!.latitude,
                                _currentPosition!.longitude > widget.firstPoint!.longitude
                                    ? _currentPosition!.longitude
                                    : widget.firstPoint!.longitude,
                              ),
                            );

                            controller.animateCamera(
                              CameraUpdate.newLatLngBounds(bounds, 50),
                            );
                          } else if (_currentPosition != null) {
                            controller.animateCamera(
                              CameraUpdate.newLatLng(_currentPosition!),
                            );
                          }
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
