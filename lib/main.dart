import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:praca/api_handler.dart';
import 'package:praca/screens/work_page.dart';
import 'package:praca/screens/settings_page.dart';
import 'package:praca/screens/stop_work_screen.dart';
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
      title: 'Flutter Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
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
      _todayHours = await ApiService().getUserTodayStats(_username!);

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
        return 'Home';
      case 1:
        return 'Work Page';
      case 2:
        return 'Settings';
      default:
        return 'Flutter Auth Demo';
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '$_totalHours hours',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Today: $_todayHours hours',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _user != null
                          ? 'You are logged in as ${_user!.email}'
                          : 'Please sign in or register.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        WorkPage(),
        SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow),
            label: 'Work',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
