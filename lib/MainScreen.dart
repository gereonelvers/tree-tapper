import 'package:flutter/material.dart';

import 'Splash.dart';
import 'GameScreen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: (context, AsyncSnapshot snapshot) {
        // Show splash screen while waiting for app resources to load:
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(home: Splash());
        } else {
          // Loading is done, return the app:
          return MaterialApp(
            title: 'Tree Tapper',
            theme: ThemeData(
              primarySwatch: Colors.green,
            ),
            home: GameScreen(title: 'Tree Tapper'),
          );
        }
      },
    );
  }
}