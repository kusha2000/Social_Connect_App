import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:social_connect/views/responsive/mobile_screen_layout.dart';
import 'package:social_connect/views/responsive/responsive_layout.dart';
import 'package:social_connect/views/responsive/web_screen_layout.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: ResponsiveLayout(
          mobileScreenLayout: MobileScreenLayout(),
          webScreenLayout: WebScreenLayout(),
        ),
      ),
    );
  }
}
