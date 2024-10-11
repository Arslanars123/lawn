import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:product_mughees/test.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
Future<void> _signInWithGoogle() async {
  try {
    // Sign out the previous user to allow account selection
    await _googleSignIn.signOut();

    // Now prompt the user to choose an account
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      return; // The user canceled the sign-in.
    }

    final String? email = googleUser.email;
    final String? name = googleUser.displayName;

    // Now, make a POST request to your API
    await _loginToBackend(email!, name!);
    
    // On successful login, navigate to the home screen
    if (mounted) {
      print("success mughees");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      print(prefs.getString('userId'));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => TestScreen()), // Navigate to TestScreen
      );
    }
  } catch (e) {
    print("Google sign-in error: $e");
  }
}

  Future<void> _loginToBackend(String email, String name) async {
    //try {
      final response = await http.post(
        Uri.parse('https://sonny-backend.vercel.app/login'), // Replace with your API endpoint
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'email': email,
          'name': name,
        }),
      );
      print(response.statusCode);
      if (response.statusCode == 201||response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
      String userId = responseData['user']['_id']; // Adjust according to your API response structure

      // Store the user ID in local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);

        
        // You can handle the response as needed, e.g., save a token or user data
      } else {
        throw Exception('Failed to login with backend');
      }
    /*} catch (e) {
      print('Backend login error: $e');
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login with Google'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text("Login with Google"),
          onPressed: _signInWithGoogle,
        ),
      ),
    );
  }
}
