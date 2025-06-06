import 'package:flutter/material.dart';
import 'package:social_connect/services/auth/auth_service.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
            onPressed: () async {
              await AuthService().signOut();
            },
            child: Text("Sign Out")),
      ),
    );
  }
}
