import 'package:flutter/material.dart';
import 'package:social_connect/models/user_model.dart';

class SingleUserScreen extends StatefulWidget {
  final UserModel user;
  const SingleUserScreen({super.key, required this.user});

  @override
  State<SingleUserScreen> createState() => _SingleUserScreenState();
}

class _SingleUserScreenState extends State<SingleUserScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text("Single User"),
    );
  }
}
