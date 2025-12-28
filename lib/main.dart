import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:ride_together/login.dart';
import 'package:ride_together/firebase_options.dart';
import 'package:ride_together/home.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  const String accessToken = String.fromEnvironment('ACCESS_TOKEN');
  MapboxOptions.setAccessToken(accessToken);
  MapBoxSearch.init(accessToken);
  FirebaseAuth.instance.setLanguageCode('en');
  FlutterForegroundTask.initCommunicationPort();
  print("access token");
  print(accessToken);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          surfaceTintColor: Colors.white,
        ),
        tabBarTheme: TabBarThemeData(
          overlayColor: WidgetStateProperty.all(Colors.white),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: Colors.black, width: 2),
            insets: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            borderRadius: BorderRadius.circular(10),
          ),
          labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          indicatorColor: Colors.black,
          
        ),
        primaryColor: Colors.black,
      ),
      locale: const Locale('en'),
      supportedLocales: const [
        Locale('en'),
      ],
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  
  // This helps prevent setting up notifications multiple times
  bool _isNotificationSetup = false;

  Future<void> _setupNotifications(User user) async {
    if (_isNotificationSetup) return;
    _isNotificationSetup = true;

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // Request Permission
    await messaging.requestPermission();

    // Get and Save Token
    String? token = await messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
    
    // Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${message.notification!.title}: ${message.notification!.body}')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // userChanges() is more sensitive to backend account changes than authStateChanges()
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;

        if (user != null) {
          // Verify if the user still exists on the server
          _verifyUserStillExists(user);
          
          // Setup notifications only once
          _setupNotifications(user);
          
          return const Home();
        }

        // If no user or user was deleted
        return const Login();
      },
    );
  }

  // Forces a check against Firebase Auth backend
  Future<void> _verifyUserStillExists(User user) async {
    try {
      await user.reload();
    } catch (e) {
      // If user is deleted, reload() will throw an error (e.g., 'user-not-found')
      // and FirebaseAuth.instance.userChanges() will automatically emit null
      await FirebaseAuth.instance.signOut();
    }
  }
}