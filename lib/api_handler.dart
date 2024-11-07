import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://192.168.0.151:8000/'; // Replace with your Django API base URL

  // Function to start a work shift
  Future<http.Response> startWorkShift(String username, String qrCode) async {
    final url = Uri.parse('$baseUrl/api/shift/start/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'qr_code': qrCode}),
    );
    return response;
  }

  // Function to end a work shift
  Future<http.Response> stopWorkShift(String username, String qrCode) async {
    final url = Uri.parse('$baseUrl/api/shift/end/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'qr_code': qrCode}),
    );
    return response;
  }

  // Function to check if a user is still working
  Future<bool> isWorking(String username) async {
    final url = Uri.parse('$baseUrl/api/shift/working/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['is_working'];
    }
    return false;
  }
  

  // Function to get all shifts for a user
  Future<http.Response> getShifts(String username) async {
    final url = Uri.parse('$baseUrl/api/shift/shifts/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
    return response;
  }

  // Function to get all shifts for all users
  Future<http.Response> getAllShifts() async {
    final url = Uri.parse('$baseUrl/api/shift/all/');
    final response = await http.get(url);
    return response;
  }

  // Function to create a new truck
  Future<http.Response> createTruck(String name, double milage, String qrCode) async {
    final url = Uri.parse('$baseUrl/api/create/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'milage': milage, 'qr_code': qrCode}),
    );
    return response;
  }

  // Function to get truck details by QR code
  Future<http.Response> getTruckByQr(String qrCode) async {
    final url = Uri.parse('$baseUrl/api/truck/$qrCode/');
    final response = await http.get(url);
    return response;
  }

  // Function to get all trucks
  Future<http.Response> getAllTrucks() async {
    final url = Uri.parse('$baseUrl/api/all/');
    final response = await http.get(url);
    return response;
  }

  Future<double> getUserMonthStats(String username) async {
    final url = Uri.parse('$baseUrl/api/shift/month/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );

    // Decode the JSON response and extract the double value
    List<dynamic> responseData = jsonDecode(response.body);
    //double responseTime = responseData[0] as double;
    double responseTime = responseData[0];
    double hoursResponseTime = responseTime / 60;
    return hoursResponseTime;
  }

  Future<double> getUserTodayStats(String username) async {
    final url = Uri.parse('$baseUrl/api/shift/today/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );

    // Decode the JSON response and extract the double value
    List<dynamic> responseData = jsonDecode(response.body);
    double responseTime = responseData[0];
    double hoursResponseTime = responseTime / 60;
    return hoursResponseTime;
  }

  Future<http.Response> startBreak(String username) async {
    final url = Uri.parse('$baseUrl/api/shift/startbr/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}));
      return response;
  }

  Future<http.Response> stopBreak(String username) async {
    final url = Uri.parse('$baseUrl/api/shift/stopbr/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}));
      return response;
  }

  Future<bool> isBreak(String username) async {
    final url = Uri.parse('$baseUrl/api/shift/break/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['is_break'];
    }
    return false;
  }

  Future<List<double>> getGpsByName(String name) async {
    final url = Uri.parse('$baseUrl/api/gps/get-name/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      print(responseBody);
      double lat = responseBody[0];
      double long = responseBody[1];
      return [lat, long];
    }
    return [1.0,2.0];
  }
    

}
