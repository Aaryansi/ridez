import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpLoginScreen extends StatefulWidget {
  @override
  _OtpLoginScreenState createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? verificationId;
  bool isOtpSent = false;
  bool isLoading = false;

  Future<void> sendOtp() async {
    setState(() => isLoading = true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _onLoginSuccess();
        },
        verificationFailed: (FirebaseAuthException e) {
          _showError("Verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            isOtpSent = true;
            isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
        },
      );
    } catch (e) {
      _showError("Error: $e");
    }
  }

  Future<void> verifyOtp() async {
    setState(() => isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otpController.text,
      );
      await _auth.signInWithCredential(credential);
      _onLoginSuccess();
    } catch (e) {
      _showError("Invalid OTP: $e");
    }
  }

  void _onLoginSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Logged in successfully!")),
    );
    Navigator.pushReplacementNamed(context, '/roleSelection'); // Navigate to the next screen
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("OTP Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isOtpSent) ...[
              TextField(
                controller: phoneController, // Ensure this is correctly passed
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  hintText: "+1234567890",
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: sendOtp,
                child: Text("Send OTP"),
              ),
            ] else ...[
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Enter OTP"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: verifyOtp,
                child: Text("Verify OTP"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
