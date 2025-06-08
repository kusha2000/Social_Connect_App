import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:social_connect/models/post_model.dart';
import 'package:social_connect/models/user_model.dart';
import 'package:social_connect/views/auth_views/forgot_password_screen.dart';
import 'package:social_connect/views/auth_views/login_screen.dart';
import 'package:social_connect/views/auth_views/register_screen.dart';
import 'package:social_connect/views/main_screen.dart';
import 'package:social_connect/views/main_views/edit_post_screen.dart';
import 'package:social_connect/views/main_views/single_user_screen.dart';
import 'package:social_connect/views/responsive/mobile_screen_layout.dart';
import 'package:social_connect/views/responsive/responsive_layout.dart';
import 'package:social_connect/views/responsive/web_screen_layout.dart';
import 'package:social_connect/views/splash_screen.dart';

class RouterClass {
  final router = GoRouter(
    initialLocation: "/splash",
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
      GoRoute(
        name: "splash",
        path: "/splash",
        builder: (context, state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        name: "login",
        path: "/login",
        builder: (context, state) {
          return LoginScreen();
        },
      ),
      GoRoute(
        name: "forgot-password",
        path: "/forgot-password",
        builder: (context, state) {
          return ForgotPasswordScreen();
        },
      ),

      //register Page
      GoRoute(
        name: "register",
        path: "/register",
        builder: (context, state) {
          return RegisterScreen();
        },
      ),
      GoRoute(
        name: "main-screen",
        path: "/main-screen",
        builder: (context, state) {
          return const MainScreen();
        },
      ),
      GoRoute(
        path: '/edit-post',
        builder: (context, state) {
          final post = state.extra as Post;
          return EditPostScreen(post: post);
        },
      ),

      //profile screen
      GoRoute(
        name: "profile-screen",
        path: "/profile-screen",
        builder: (context, state) {
          final UserModel user = state.extra as UserModel;
          return SingleUserScreen(
            user: user,
          );
        },
      ),
    ],
  );
}
