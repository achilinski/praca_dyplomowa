import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:praca/api_handler.dart';
import 'package:praca/screens/qr_scanner_screen.dart';
import 'package:praca/screens/stop_work_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
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

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });
    });
    _fetchworkingStatus();
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

    if(_username != null){
      bool workingStatus = await ApiService().isWorking(_username!);
      setState(() {
        _isWorking = workingStatus;
      });
    }
  }
  

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                _user != null ? 'Welcome, ${_user!.email}' : 'Welcome, Guest',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              title: Text(_user != null ? 'Sign out' : 'Sign In'),
              onTap: () {
                if (_user != null) {
                  _signOut();
                  Navigator.pop(context);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                }
              },
            ),
            if (_user != null)
            ListTile(
              title: Text(_isWorking ? 'Stop work' : 'Start work'),
              onTap: () async {
                if (_isWorking)  {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => StopWorkScreen()));
                } else {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EnterCodePage()),
                  );
                }
                await _fetchworkingStatus();
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          _user != null ? 'You are logged in as ${_user!.email}' : 'Please sign in or register.',
        ),
      ),
    );
  }
}
