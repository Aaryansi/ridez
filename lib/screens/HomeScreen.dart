import 'package:flutter/material.dart';
import 'RequestRideScreen.dart';
import 'OfferRideScreen.dart';
import 'OtpLoginScreen.dart'; // Import the OTP login screen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ridez'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RequestRideScreen()),
                );
              },
              child: Text('Request a Ride'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OfferRideScreen()),
                );
              },
              child: Text('Offer a Ride'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OtpLoginScreen()),
                );
              },
              child: Text('Login with OTP'), // Button for OTP Login
            ),
          ],
        ),
      ),
    );
  }
}
