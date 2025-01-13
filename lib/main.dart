import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/OtpLoginScreen.dart'; // Your OTP Login Screen
//import 'screens/RoleSelectionScreen.dart'; // Role Selection Screen
import 'screens/OfferRideScreen.dart'; // Offer Ride Screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ridez',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // Default screen
      routes: {
        '/login': (context) => OtpLoginScreen(), // OTP Login Screen
        //'/roleSelection': (context) => RoleSelectionScreen(), // Role Selection Screen
        '/offerRide': (context) => OfferRideScreen(), // Offer Ride Screen
        // Add '/takeRide': (context) => TakeRideScreen() if needed
      },
    );
  }
}
