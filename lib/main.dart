import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:product_mughees/login.dart';
import 'package:product_mughees/test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyBkwUSCrF3m9faiqCNIXA76lEHHSwyAAcg',
      appId: '1:886691467656:android:0b820c0089d3f6b38eea3d',
      messagingSenderId: '886691467656',
      projectId: 'flawn-5201c',
      storageBucket: 'lawn-5201c.appspot.com',
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<String?>(
        future: _getUserId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data != null) {
            return TestScreen(); // Replace with the screen you want to navigate to
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }

  Future<String?> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(prefs.getString('userId'));
    return prefs.getString('userId');
  }
}
