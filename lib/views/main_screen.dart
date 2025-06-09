import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_connect/views/main_views/feed_screen.dart';
import 'package:social_connect/views/main_views/reels_screen.dart';
import 'package:social_connect/views/main_views/search_screen.dart';
import 'package:social_connect/views/main_views/single_user_screen.dart';
import 'package:social_connect/models/user_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<UserModel?> _getCurrentUserModel(String userId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              FeedScreen(),
              SearchScreen(),
              ReelsScreen(),
              currentUser != null
                  ? FutureBuilder<UserModel?>(
                      future: _getCurrentUserModel(currentUser.uid),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (userSnapshot.hasError) {
                          return Center(child: Text('Error loading profile'));
                        }

                        final userModel = userSnapshot.data;
                        if (userModel != null) {
                          return SingleUserScreen(user: userModel);
                        } else {
                          return Center(child: Text('User not found'));
                        }
                      },
                    )
                  : Center(child: Text('Please log in')),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.video_library),
                label: 'Reels',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}
