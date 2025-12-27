import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
  print("access token");
  print(accessToken);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        print(FirebaseAuth.instance.currentUser?.uid);
        return snapshot.hasData ? const Home() : const Login();
      },
    );
  }
}