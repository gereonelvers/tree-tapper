import 'package:flutter/material.dart';

/// This class is the splash screen that is displayed while the app is loading
class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image(
          image: AssetImage("assets/img/logo.png")
        )
      ),
    );
  }
}