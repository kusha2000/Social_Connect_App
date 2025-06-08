import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_connect/models/reel_model.dart';
import 'package:social_connect/services/auth/auth_service.dart';
import 'package:social_connect/services/reels/reel_storage.dart';
import 'package:social_connect/services/users/user_service.dart';

class ReelService {
  final CollectionReference _reelsCollection =
      FirebaseFirestore.instance.collection('reels');

  // Fetch current user details
  Future<Map<String, String>?> _getCurrentUserDetails() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user != null) {
        final userModel = await UserService().getUserById(user.uid);
        if (userModel != null) {
          return {
            'userId': user.uid,
            'email': userModel.email,
            'name': userModel.name,
            'imageUrl': userModel.imageUrl,
          };
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
    return null;
  }

  // Get current user ID
  Future<String?> getCurrentUserId() async {
    try {
      final user = await AuthService().getCurrentUser();
      return user?.uid;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  // Fetch reels from Firestore
  Stream<QuerySnapshot> getReels() {
    return _reelsCollection
        .orderBy('datePublished', descending: true)
        .snapshots();
  }

  // Save a reel in Firestore
  Future<void> saveReel(Map<String, dynamic> reelDetails) async {
    try {
      final userDetails = await _getCurrentUserDetails();
      if (userDetails == null) {
        throw Exception('Failed to fetch user details');
      }

      if (userDetails['userId'] == null ||
          userDetails['name'] == null ||
          userDetails['imageUrl'] == null) {
        throw Exception('Missing required user details');
      }

      final reel = Reel(
        caption: reelDetails['caption'],
        videoUrl: reelDetails['videoUrl'],
        userId: userDetails['userId']!,
        username: userDetails['name']!,
        userProfilePic: userDetails['imageUrl']!,
        reelId: '',
        likes: 0,
        comments: 0,
        datePublished: DateTime.now(),
      );

      final docRef = await _reelsCollection.add(reel.toJson());
      await docRef.update({'reelId': docRef.id});
    } catch (e) {
      print('Error saving reel: $e');
      throw e;
    }
  }

  // Delete a reel from Firestore and Cloudinary
  Future<void> deleteReel(Reel reel) async {
    try {
      final userDetails = await _getCurrentUserDetails();
      if (userDetails == null) {
        throw Exception('Failed to fetch user details');
      }

      await _reelsCollection.doc(reel.reelId).delete();
      await ReelStorageService().deleteVideo(
        videoUrl: reel.videoUrl,
        userEmail: userDetails['email']!,
      );
    } catch (e) {
      print('Error deleting reel: $e');
      throw e;
    }
  }

  // Check if current user has liked a reel
  Future<bool> hasUserLikedReel(String reelId) async {
    try {
      final currentUserId = await getCurrentUserId();
      if (currentUserId == null) {
        return false;
      }

      final doc = await _reelsCollection
          .doc(reelId)
          .collection('likes')
          .doc(currentUserId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking if user liked reel: $e');
      return false;
    }
  }

  // Get likes count for a reel
  Future<int> getLikesCount(String reelId) async {
    try {
      final doc = await _reelsCollection.doc(reelId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['likes'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting likes count: $e');
      return 0;
    }
  }

  // Get users who liked a reel
  Stream<QuerySnapshot> getReelLikes(String reelId) {
    return _reelsCollection
        .doc(reelId)
        .collection('likes')
        .orderBy('likedAt', descending: true)
        .snapshots();
  }

  // Get reel likes as list for bottom sheet
  Future<List<Map<String, dynamic>>> getReelLikesList(String reelId) async {
    try {
      final snapshot = await _reelsCollection
          .doc(reelId)
          .collection('likes')
          .orderBy('likedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'],
          'username': data['username'],
          'profileImage': data['profileImage'] ?? '',
          'likedAt': data['likedAt'],
        };
      }).toList();
    } catch (e) {
      print('Error getting reel likes list: $e');
      return [];
    }
  }

  // Get comments count for a reel
  Future<int> getCommentsCount(String reelId) async {
    try {
      final doc = await _reelsCollection.doc(reelId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['comments'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting comments count: $e');
      return 0;
    }
  }

  // Get comments for a reel
  Stream<QuerySnapshot> getReelComments(String reelId) {
    return _reelsCollection
        .doc(reelId)
        .collection('comments')
        .orderBy('commentedAt', descending: true)
        .snapshots();
  }

  // Delete a comment
  Future<void> deleteComment(String reelId, String commentId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Delete comment from nested collection
      final commentRef =
          _reelsCollection.doc(reelId).collection('comments').doc(commentId);
      batch.delete(commentRef);

      // Decrement comments count in main document
      final reelRef = _reelsCollection.doc(reelId);
      batch.update(reelRef, {
        'comments': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      print('Error deleting comment: $e');
      throw e;
    }
  }

  // Like a comment
  Future<void> likeComment({
    required String reelId,
    required String commentId,
    required String userId,
  }) async {
    try {
      final userDetails = await _getCurrentUserDetails();
      if (userDetails == null) {
        throw Exception('User not authenticated');
      }

      final batch = FirebaseFirestore.instance.batch();

      // Add like to comment's likes subcollection
      final commentLikeRef = _reelsCollection
          .doc(reelId)
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(userId);

      batch.set(commentLikeRef, {
        'userId': userId,
        'username': userDetails['name'],
        'likedAt': FieldValue.serverTimestamp(),
      });

      // Increment comment's like count
      final commentRef =
          _reelsCollection.doc(reelId).collection('comments').doc(commentId);
      batch.update(commentRef, {
        'likes': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print('Error liking comment: $e');
      throw e;
    }
  }

  // Unlike a comment
  Future<void> unlikeComment({
    required String reelId,
    required String commentId,
    required String userId,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Remove like from comment's likes subcollection
      final commentLikeRef = _reelsCollection
          .doc(reelId)
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(userId);

      batch.delete(commentLikeRef);

      // Decrement comment's like count
      final commentRef =
          _reelsCollection.doc(reelId).collection('comments').doc(commentId);
      batch.update(commentRef, {
        'likes': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      print('Error unliking comment: $e');
      throw e;
    }
  }

  // Check if user has liked a comment
  Future<bool> hasUserLikedComment({
    required String reelId,
    required String commentId,
    required String userId,
  }) async {
    try {
      final doc = await _reelsCollection
          .doc(reelId)
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking comment like: $e');
      return false;
    }
  }

  Future<void> likeReel(String reelId) async {
    try {
      final userDetails = await _getCurrentUserDetails();
      if (userDetails == null) {
        throw Exception('User not authenticated');
      }

      final userId = userDetails['userId']!;

      // Check if already liked to prevent duplicate likes
      final existingLike = await _reelsCollection
          .doc(reelId)
          .collection('likes')
          .doc(userId)
          .get();

      if (existingLike.exists) {
        // Already liked, don't do anything
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      // Add like to the nested likes collection
      final likeRef =
          _reelsCollection.doc(reelId).collection('likes').doc(userId);

      batch.set(likeRef, {
        'userId': userId,
        'username': userDetails['name'],
        'profileImage': userDetails['imageUrl'],
        'likedAt': FieldValue.serverTimestamp(),
      });

      // Increment likes count in main document
      final reelRef = _reelsCollection.doc(reelId);
      batch.update(reelRef, {
        'likes': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print('Error liking reel: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

// Improved unlike reel method with better error handling
  Future<void> unlikeReel(String reelId) async {
    try {
      final currentUserId = await getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if like exists before trying to remove
      final existingLike = await _reelsCollection
          .doc(reelId)
          .collection('likes')
          .doc(currentUserId)
          .get();

      if (!existingLike.exists) {
        // Not liked, don't do anything
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      // Remove like from the nested likes collection
      final likeRef =
          _reelsCollection.doc(reelId).collection('likes').doc(currentUserId);

      batch.delete(likeRef);

      // Decrement likes count in main document (but don't go below 0)
      final reelRef = _reelsCollection.doc(reelId);
      batch.update(reelRef, {
        'likes': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      print('Error unliking reel: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

// Improved add comment method
  Future<void> addComment(String reelId, String comment) async {
    try {
      final userDetails = await _getCurrentUserDetails();
      if (userDetails == null) {
        throw Exception('Failed to fetch user details');
      }

      if (comment.trim().isEmpty) {
        throw Exception('Comment cannot be empty');
      }

      final batch = FirebaseFirestore.instance.batch();

      // Add comment to the nested comments collection
      final commentRef =
          _reelsCollection.doc(reelId).collection('comments').doc();
      batch.set(commentRef, {
        'commentId': commentRef.id,
        'userId': userDetails['userId'],
        'username': userDetails['name'],
        'userProfileImage': userDetails['imageUrl'],
        'comment': comment.trim(),
        'likes': 0,
        'commentedAt': FieldValue.serverTimestamp(),
      });

      // Increment comments count in main document
      final reelRef = _reelsCollection.doc(reelId);
      batch.update(reelRef, {
        'comments': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

// Method to get real-time reel data
  Stream<Map<String, dynamic>?> getReelData(String reelId) {
    return _reelsCollection.doc(reelId).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    });
  }
}
