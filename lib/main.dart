import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:social_connect/router/router.dart';
import 'package:social_connect/utils/app_constants/colors.dart';
import 'package:social_connect/utils/app_constants/theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // You can control theme mode here
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

      // Update AppColors theme state
      AppColors.setDarkMode(_themeMode == ThemeMode.dark);
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize theme
    AppColors.setDarkMode(_themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Social Connect',
      debugShowCheckedModeBanner: false,

      // Apply your custom themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,

      // Router configuration
      routerConfig: RouterClass().router,
    );
  }
}
