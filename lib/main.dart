import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:praca/api_handler.dart';
import 'package:praca/screens/chat_page.dart';
import 'package:praca/screens/work_page.dart';
import 'package:praca/screens/settings_page.dart';
import 'package:praca/screens/stop_work_screen.dart';
import 'package:web_socket_channel/io.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dark Theme App',
      themeMode: ThemeMode.dark, // Set to dark mode by default
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.grey, // Primary color is grey
        hintColor: Colors.red, // Accent color is red
        scaffoldBackgroundColor: Colors.black, // Background color for a dark look
        appBarTheme: AppBarTheme(
          color: Colors.grey[900], // Darker grey for the AppBar
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[900], // Background color for the bottom navigation bar
          selectedItemColor: Colors.red, // Color for the selected item
          unselectedItemColor: Colors.grey[400], // Color for unselected items
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.red, // Buttons with red color
          textTheme: ButtonTextTheme.primary,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white), // Default text color for readability
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // Elevated button color
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  final LatLng? firstPoint;
  HomePage({this.firstPoint});
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user;
  bool _isWorking = false;
  String? _username;
  double _totalHours = 0;
  double _todayHours = 0;
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _pageController = PageController();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });
    });
    _fetchworkingStatus();
    _fetchUserStats();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> _fetchworkingStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    _username = user?.email;

    if (_username != null) {
      bool workingStatus = await ApiService().isWorking(_username!);
      setState(() {
        _isWorking = workingStatus;
      });
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _fetchUserStats() async {
    User? user = FirebaseAuth.instance.currentUser;
    _username = user?.email;

    if (_username != null) {
      _totalHours = await ApiService().getUserMonthStats(_username!);
      _todayHours = 0;

      setState(() {
        _totalHours = _totalHours;
        _todayHours = _todayHours;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _fetchworkingStatus();
    });
    _pageController.jumpToPage(index);
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Work Page';
      case 1:
        return 'work';
      default:
        return 'chat';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return LoginScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
        WorkPage(firstPoint:widget.firstPoint),
        ChatPage(channel: IOWebSocketChannel.connect('ws://192.168.191.195:8000/ws/chat/room1/')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
