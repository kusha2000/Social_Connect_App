import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:social_connect/views/responsive/mobile_screen_layout.dart';
import 'package:social_connect/views/responsive/responsive_layout.dart';
import 'package:social_connect/views/responsive/web_screen_layout.dart';

class RouterClass {
  final router = GoRouter(
    initialLocation: "/",
    errorPageBuilder: (context, state) {
      return const MaterialPage<dynamic>(
        child: Scaffold(
          body: Center(
            child: Text("this page is not found!!"),
          ),
        ),
      );
    },
    routes: [
      //wrapper

      GoRoute(
        path: "/",
        name: "wrapper",
        builder: (context, state) {
          return const ResponsiveLayout(
            mobileScreenLayout: MobileScreenLayout(),
            webScreenLayout: WebScreenLayout(),
          );
        },
      ),
    ],
  );
}
