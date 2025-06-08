// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_connect/models/user_model.dart';
import 'package:social_connect/services/auth/auth_service.dart';

class UserService {
  // Create a collection reference
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Save the user in the Firestore database
  Future<void> saveUser(UserModel user) async {
    try {
      // Create a new user with email and password
      final userCredential = await AuthService().createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );

      // Retrieve the user ID from the created user
      final userId = userCredential.user?.uid;

      if (userId != null) {
        // Create a new user document in Firestore with the user ID as the document ID
        final userRef = _usersCollection.doc(userId);

        // Create a user map with the userId field
        final userMap = user.toMap();
        userMap['userId'] = userId;

        // Set the user data in Firestore
        await userRef.set(userMap);

        print('User saved successfully with ID: $userId');
      } else {
        print('Error: User ID is null');
      }
    } catch (error) {
      print('Error saving user: $error');
    }
  }

  //get user details by id
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (error) {
      print('Error getting user: $error');
    }
    return null;
  }

  //get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _usersCollection.get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (error) {
      print('Error getting users: $error');
      return [];
    }
  }

  Future<void> followUser(String currentUserId, String userToFollowId) async {
    try {
      // Add the user to the followers collection
      await _usersCollection
          .doc(userToFollowId)
          .collection('followers')
          .doc(currentUserId)
          .set({
        'followedAt': Timestamp.now(),
      });

      // Update follower count for the followed user
      final followedUserRef = _usersCollection.doc(userToFollowId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final followedUserDoc = await transaction.get(followedUserRef);
        if (followedUserDoc.exists) {
          final data = followedUserDoc.data() as Map<String, dynamic>;
          final currentCount = data['followersCount'] ?? 0;
          transaction
              .update(followedUserRef, {'followersCount': currentCount + 1});
        }
      });

      // Update following count for the current user
      final currentUserRef = _usersCollection.doc(currentUserId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final currentUserDoc = await transaction.get(currentUserRef);
        if (currentUserDoc.exists) {
          final data = currentUserDoc.data() as Map<String, dynamic>;
          final currentCount = data['followingCount'] ?? 0;
          transaction
              .update(currentUserRef, {'followingCount': currentCount + 1});
        }
      });

      print('User followed successfully');
    } catch (error) {
      print('Error following user: $error');
    }
  }

  Future<void> unfollowUser(
      String currentUserId, String userToUnfollowId) async {
    try {
      // Remove the user from the followers collection
      await _usersCollection
          .doc(userToUnfollowId)
          .collection('followers')
          .doc(currentUserId)
          .delete();

      // Update follower count for the unfollowed user
      final unfollowedUserRef = _usersCollection.doc(userToUnfollowId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final unfollowedUserDoc = await transaction.get(unfollowedUserRef);
        if (unfollowedUserDoc.exists) {
          final data = unfollowedUserDoc.data() as Map<String, dynamic>;
          final currentCount = data['followersCount'] ?? 0;
          transaction
              .update(unfollowedUserRef, {'followersCount': currentCount - 1});
        }
      });

      // Update following count for the current user
      final currentUserRef = _usersCollection.doc(currentUserId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final currentUserDoc = await transaction.get(currentUserRef);
        if (currentUserDoc.exists) {
          final data = currentUserDoc.data() as Map<String, dynamic>;
          final currentCount = data['followingCount'] ?? 0;
          transaction
              .update(currentUserRef, {'followingCount': currentCount - 1});
        }
      });

      print('User unfollowed successfully');
    } catch (error) {
      print('Error unfollowing user: $error');
    }
  }

  //Method to check if the current user is following another user
  Future<bool> isFollowing(String currentUserId, String userToCheckId) async {
    try {
      final docSnapshot = await _usersCollection
          .doc(userToCheckId)
          .collection('followers')
          .doc(currentUserId)
          .get();

      return docSnapshot.exists;
    } catch (error) {
      print('Error checking follow status: $error');
      return false;
    }
  }

  // Get the count of followers for a user
  Future<int> getUserFollowersCount(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['followersCount'] ?? 0;
      }
      return 0; // Return 0 if the document doesn't exist
    } catch (error) {
      print('Error getting user followers count: $error');
      return 0;
    }
  }

  // Get the count of users the current user is following
  Future<int> getUserFollowingCount(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['followingCount'] ?? 0;
      }
      return 0; // Return 0 if the document doesn't exist
    } catch (error) {
      print('Error getting user following count: $error');
      return 0;
    }
  }

  Future<List<UserModel>> getFollowersList(String userId) async {
    try {
      final followersSnapshot =
          await _usersCollection.doc(userId).collection('followers').get();

      List<UserModel> followers = [];

      for (var doc in followersSnapshot.docs) {
        final followerId = doc.id;
        final followerUser = await getUserById(followerId);
        if (followerUser != null) {
          followers.add(followerUser);
        }
      }

      return followers;
    } catch (error) {
      print('Error getting followers list: $error');
      return [];
    }
  }

// Get list of users that a user is following
  Future<List<UserModel>> getFollowingList(String userId) async {
    try {
      // Get all users
      final allUsers = await getAllUsers();
      List<UserModel> following = [];

      // Check which users the current user is following
      for (var user in allUsers) {
        if (user.userId != userId) {
          final isFollowing = await this.isFollowing(userId, user.userId);
          if (isFollowing) {
            following.add(user);
          }
        }
      }

      return following;
    } catch (error) {
      print('Error getting following list: $error');
      return [];
    }
  }

  Stream<int> getFollowersCountStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map<int>((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        return data['followersCount'] ?? 0;
      }
      return 0;
    }).handleError((error) {
      print('Error in followers count stream: $error');
    });
  }

  /// Stream for real-time following count updates
  Stream<int> getFollowingCountStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map<int>((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        return data['followingCount'] ?? 0;
      }
      return 0;
    }).handleError((error) {
      print('Error in following count stream: $error');
    });
  }
}
