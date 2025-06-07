import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_connect/models/comments_model.dart';
import 'package:social_connect/models/post_model.dart';
import 'package:social_connect/services/storage/storage.dart';
import 'package:social_connect/utils/util_functions/mood.dart';

class FeedService {
  // Create a collection reference
  final CollectionReference _feedCollection =
      FirebaseFirestore.instance.collection('feed');
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Initialize storage service
  final StorageService _storageService = StorageService();

  // Save the post in the Firestore database
  Future<bool> savePost(Map<String, dynamic> postDetails) async {
    try {
      String? postUrl;

      // Check if the post has an image (handle both File and Uint8List)
      final postImage = postDetails['postImage'];

      if (postImage != null) {
        if (postImage is File) {
          // Mobile: File object
          postUrl = await _storageService.uploadImage(
            profileImage: postImage,
            userEmail:
                postDetails['userEmail'] as String? ?? 'unknown@email.com',
            imageType: 'post',
          );
        } else if (postImage is Uint8List) {
          // Web: Uint8List bytes
          postUrl = await _storageService.uploadImageFromBytes(
            imageBytes: postImage,
            userEmail:
                postDetails['userEmail'] as String? ?? 'unknown@email.com',
            imageType: 'post',
          );
        }
      }

      // Create a new Post object
      final Post post = Post(
        postCaption: postDetails['postCaption'] as String? ?? '',
        mood: MoodExtension.fromString(postDetails['mood'] ?? 'happy'),
        userId: postDetails['userId'] as String? ?? '',
        username: postDetails['username'] as String? ?? '',
        likes: 0,
        comments: 0,
        postId: '',
        datePublished: DateTime.now(),
        postUrl: postUrl ?? '',
        profImage: postDetails['profImage'] as String? ?? '',
      );

      // Add the post to the collection
      final docRef = await _feedCollection.add(post.toJson());
      await docRef.update({'postId': docRef.id});

      return true;
    } catch (error) {
      print('Error saving post: $error');
      return false;
    }
  }

  Future<bool> updatePost(Map<String, dynamic> postDetails) async {
    try {
      String? postUrl = postDetails['existingImageUrl'];
      final postImage = postDetails['postImage'];

      print("OldUL:$postUrl");
      print("postURL:$postImage");

      if (postImage != null) {
        if (postDetails['existingImageUrl'] != null &&
            postDetails['existingImageUrl'].isNotEmpty) {
          print("Testing-Come to delete part");
          bool isSucess = await _storageService.deleteImage(
            imageUrl: postDetails['existingImageUrl'],
            userEmail:
                postDetails['userEmail'] as String? ?? 'unknown@email.com',
            imageType: 'post',
          );
          if (isSucess) {
            print("Sucessfully deleted");
          } else {
            print("Not Deleted");
          }
        } else {
          print("No Image");
        }

        if (postImage is File) {
          postUrl = await _storageService.uploadImage(
            profileImage: postImage,
            userEmail:
                postDetails['userEmail'] as String? ?? 'unknown@email.com',
            imageType: 'post',
          );
        } else if (postImage is Uint8List) {
          postUrl = await _storageService.uploadImageFromBytes(
            imageBytes: postImage,
            userEmail:
                postDetails['userEmail'] as String? ?? 'unknown@email.com',
            imageType: 'post',
          );
        }
      }

      Map<String, dynamic> updateData = {
        'postCaption': postDetails['postCaption'] as String? ?? '',
        'mood': postDetails['mood'] ?? 'happy',
        'postUrl': postUrl ?? '',
      };

      await _feedCollection.doc(postDetails['postId']).update(updateData);
      return true;
    } catch (error) {
      print('Error updating post: $error');
      return false;
    }
  }

  // Alternative method using the universal upload function
  Future<bool> savePostUniversal(Map<String, dynamic> postDetails) async {
    try {
      String? postUrl;

      // Check if the post has an image
      final postImage = postDetails['postImage'];

      if (postImage != null) {
        postUrl = await _storageService.uploadImageUniversal(
          imageFile: postImage is File ? postImage : null,
          imageBytes: postImage is Uint8List ? postImage : null,
          userEmail: postDetails['userEmail'] as String? ?? 'unknown@email.com',
          imageType: 'post',
        );
      }

      // Create a new Post object
      final Post post = Post(
        postCaption: postDetails['postCaption'] as String? ?? '',
        mood: MoodExtension.fromString(postDetails['mood'] ?? 'happy'),
        userId: postDetails['userId'] as String? ?? '',
        username: postDetails['username'] as String? ?? '',
        likes: 0,
        comments: 0,
        postId: '',
        datePublished: DateTime.now(),
        postUrl: postUrl ?? '',
        profImage: postDetails['profImage'] as String? ?? '',
      );

      // Add the post to the collection
      final docRef = await _feedCollection.add(post.toJson());
      await docRef.update({'postId': docRef.id});

      return true;
    } catch (error) {
      print('Error saving post: $error');
      return false;
    }
  }

  // Fetch the posts as a stream - Fixed to order by date
  Stream<List<Post>> getPostsStream() {
    return _feedCollection
        .orderBy('datePublished', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Post.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Delete a post from the Firestore database
  Future<void> deletePost({
    required String postId,
    required String postUrl,
  }) async {
    try {
      // First, get the post document to retrieve the userId
      final postDoc = await _feedCollection.doc(postId).get();

      if (!postDoc.exists) {
        print('Post not found');
        return;
      }

      final postData = postDoc.data() as Map<String, dynamic>;
      final String userId = postData['userId'] ?? '';

      String userEmail = '';

      // Get user email from userId if userId exists
      if (userId.isNotEmpty) {
        final userDoc = await _usersCollection.doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          userEmail = userData['email'] ?? userData['userEmail'] ?? '';
        }
      }

      // Delete from Firestore first
      await _feedCollection.doc(postId).delete();

      // Delete from Cloudinary if there's an image and we have userEmail
      if (postUrl.isNotEmpty && userEmail.isNotEmpty) {
        await _storageService.deleteImage(
          imageUrl: postUrl,
          userEmail: userEmail,
          imageType: 'post',
        );
      } else if (postUrl.isNotEmpty) {
        print(
            'Warning: Could not delete image from storage - user email not found');
      }

      print("Post deleted successfully");
    } catch (error) {
      print('Error deleting post: $error');
      rethrow;
    }
  }

  //get all posts images from the user
  Future<List<String>> getUserPosts(String userId) async {
    try {
      final userPosts = await _feedCollection
          .where('userId', isEqualTo: userId)
          .get()
          .then((snapshot) {
        return snapshot.docs.map((doc) {
          return Post.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();
      });

      return userPosts.map((post) => post.postUrl).toList();
    } catch (error) {
      print('Error fetching user posts: $error');
      return [];
    }
  }

  // FIXED: Like post method with proper transaction order (reads before writes)
  Future<void> likePost(
      {required String postId, required String userId}) async {
    try {
      // Use a transaction to ensure data consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postLikesRef =
            _feedCollection.doc(postId).collection('likes').doc(userId);
        final postRef = _feedCollection.doc(postId);

        // CRITICAL: All reads must be executed FIRST
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post does not exist');
        }

        // Now perform all writes AFTER reads
        // Add like document
        transaction.set(postLikesRef, {
          'likedAt': Timestamp.now(),
          'userId': userId,
        });

        // Update likes count
        final currentLikes = postDoc.data() as Map<String, dynamic>;
        final newLikesCount = (currentLikes['likes'] ?? 0) + 1;
        transaction.update(postRef, {'likes': newLikesCount});
      });

      print('Post liked successfully');
    } catch (error) {
      print('Error liking post: $error');
      rethrow;
    }
  }

  // FIXED: Unlike post method with proper transaction order (reads before writes)
  Future<void> unlikePost(
      {required String postId, required String userId}) async {
    try {
      // Use a transaction to ensure data consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postLikesRef =
            _feedCollection.doc(postId).collection('likes').doc(userId);
        final postRef = _feedCollection.doc(postId);

        // CRITICAL: All reads must be executed FIRST
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post does not exist');
        }

        // Now perform all writes AFTER reads
        // Remove like document
        transaction.delete(postLikesRef);

        // Update likes count
        final currentLikes = postDoc.data() as Map<String, dynamic>;
        final newLikesCount = ((currentLikes['likes'] ?? 1) - 1)
            .clamp(0, double.infinity)
            .toInt();
        transaction.update(postRef, {'likes': newLikesCount});
      });

      print('Post unliked successfully');
    } catch (error) {
      print('Error unliking post: $error');
      rethrow;
    }
  }

  // Check if a user has liked a post
  Future<bool> hasUserLikedPost(
      {required String postId, required String userId}) async {
    try {
      final postLikesRef =
          _feedCollection.doc(postId).collection('likes').doc(userId);
      final doc = await postLikesRef.get();
      return doc.exists;
    } catch (error) {
      print('Error checking if user liked post: $error');
      return false;
    }
  }
}

extension CommentService on FeedService {
  // Get comments collection reference for a specific post
  CollectionReference _getCommentsCollection(String postId) {
    return _feedCollection.doc(postId).collection('comments');
  }

  Future<bool> addComment({
    required String postId,
    required String userId,
    required String text,
  }) async {
    try {
      String userName = '';
      String userProfileImage = '';

      final userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        userName = userData['name'] ?? '';
        userProfileImage = userData['imageUrl'] ?? '';
      }

      print("Test Name:$userName");
      print("Test Profile Image:$userProfileImage");

      // Use a transaction to ensure data consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final commentsRef = _getCommentsCollection(postId);
        final postRef = _feedCollection.doc(postId);

        // CRITICAL: All reads must be executed FIRST
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post does not exist');
        }

        // Now perform all writes AFTER reads
        // Create comment document reference
        final commentDocRef = commentsRef.doc();

        final comment = Comment(
          commentId: commentDocRef.id,
          postId: postId,
          userId: userId,
          username: userName,
          userProfileImage: userProfileImage,
          text: text,
          datePublished: DateTime.now(),
          likes: 0,
        );

        // Add comment to subcollection
        transaction.set(commentDocRef, comment.toJson());

        // Update comments count in the post document
        final currentComments = postDoc.data() as Map<String, dynamic>;
        final newCommentsCount = (currentComments['comments'] ?? 0) + 1;
        transaction.update(postRef, {'comments': newCommentsCount});
      });

      print('Comment added successfully');
      return true;
    } catch (error) {
      print('Error adding comment: $error');
      return false;
    }
  }

  // Get comments for a post as a stream
  Stream<List<Comment>> getCommentsStream(String postId) {
    return _getCommentsCollection(postId)
        .orderBy('datePublished', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Comment.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // FIXED: Delete comment method with proper transaction order (reads before writes)
  Future<bool> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      // Use a transaction to ensure data consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final commentRef = _getCommentsCollection(postId).doc(commentId);
        final postRef = _feedCollection.doc(postId);

        // CRITICAL: All reads must be executed FIRST
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post does not exist');
        }

        // Now perform all writes AFTER reads
        // Delete comment
        transaction.delete(commentRef);

        // Update comments count in the post document
        final currentComments = postDoc.data() as Map<String, dynamic>;
        final newCommentsCount = ((currentComments['comments'] ?? 1) - 1)
            .clamp(0, double.infinity)
            .toInt();
        transaction.update(postRef, {'comments': newCommentsCount});
      });

      print('Comment deleted successfully');
      return true;
    } catch (error) {
      print('Error deleting comment: $error');
      return false;
    }
  }

  Future<void> likeComment({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    try {
      // Use a transaction to ensure data consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final commentLikesRef = _getCommentsCollection(postId)
            .doc(commentId)
            .collection('likes')
            .doc(userId);
        final commentRef = _getCommentsCollection(postId).doc(commentId);

        // CRITICAL: All reads must be executed FIRST
        final commentDoc = await transaction.get(commentRef);

        if (!commentDoc.exists) {
          throw Exception('Comment does not exist');
        }

        // Add like document
        transaction.set(commentLikesRef, {
          'likedAt': Timestamp.now(),
          'userId': userId,
        });

        // Update the likes count in the comment document
        final currentLikes = commentDoc.data() as Map<String, dynamic>;
        final newLikesCount = (currentLikes['likes'] ?? 0) + 1;
        transaction.update(commentRef, {'likes': newLikesCount});
      });

      print('Comment liked successfully');
    } catch (error) {
      print('Error liking comment: $error');
      rethrow;
    }
  }

  // FIXED: Unlike a comment with proper transaction order (reads before writes)
  Future<void> unlikeComment({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    try {
      // Use a transaction to ensure data consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final commentLikesRef = _getCommentsCollection(postId)
            .doc(commentId)
            .collection('likes')
            .doc(userId);
        final commentRef = _getCommentsCollection(postId).doc(commentId);

        // CRITICAL: All reads must be executed FIRST
        final commentDoc = await transaction.get(commentRef);

        if (!commentDoc.exists) {
          throw Exception('Comment does not exist');
        }

        // Now perform all writes AFTER reads
        // Delete like document
        transaction.delete(commentLikesRef);

        // Update the likes count in the comment document
        final currentLikes = commentDoc.data() as Map<String, dynamic>;
        final newLikesCount = ((currentLikes['likes'] ?? 1) - 1)
            .clamp(0, double.infinity)
            .toInt();
        transaction.update(commentRef, {'likes': newLikesCount});
      });

      print('Comment unliked successfully');
    } catch (error) {
      print('Error unliking comment: $error');
      rethrow;
    }
  }

  // Check if a user has liked a comment
  Future<bool> hasUserLikedComment({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    try {
      final commentLikesRef = _getCommentsCollection(postId)
          .doc(commentId)
          .collection('likes')
          .doc(userId);

      final doc = await commentLikesRef.get();
      return doc.exists;
    } catch (error) {
      print('Error checking if user liked comment: $error');
      return false;
    }
  }

  // Fixed get users who liked a post
  Future<List<Map<String, dynamic>>> getPostLikes(String postId) async {
    try {
      final likesSnapshot = await _feedCollection
          .doc(postId)
          .collection('likes')
          .orderBy('likedAt', descending: true)
          .get();

      List<Map<String, dynamic>> likes = [];

      for (var doc in likesSnapshot.docs) {
        try {
          // Get user details from the users collection
          final userDoc = await _usersCollection.doc(doc.id).get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            likes.add({
              'userId': doc.id,
              'username': userData['name'] ?? 'Unknown User',
              'profileImage': userData['imageUrl'] ?? '',
              'likedAt': doc.data()['likedAt'],
            });
          } else {
            likes.add({
              'userId': doc.id,
              'username': 'Unknown User',
              'profileImage': '',
              'likedAt': doc.data()['likedAt'],
            });
          }
        } catch (e) {
          print('Error getting user data for like: $e');
          // Continue with next like even if one fails
          continue;
        }
      }

      return likes;
    } catch (error) {
      print('Error getting post likes: $error');
      return [];
    }
  }

  // New method: Get comment likes (similar to post likes)
  Future<List<Map<String, dynamic>>> getCommentLikes(
      String postId, String commentId) async {
    try {
      final likesSnapshot = await _getCommentsCollection(postId)
          .doc(commentId)
          .collection('likes')
          .orderBy('likedAt', descending: true)
          .get();

      List<Map<String, dynamic>> likes = [];

      for (var doc in likesSnapshot.docs) {
        try {
          // Get user details from the users collection
          final userDoc = await _usersCollection.doc(doc.id).get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            likes.add({
              'userId': doc.id,
              'username': userData['name'] ?? 'Unknown User',
              'profileImage': userData['imageUrl'] ?? '',
              'likedAt': doc.data()['likedAt'],
            });
          } else {
            likes.add({
              'userId': doc.id,
              'username': 'Unknown User',
              'profileImage': '',
              'likedAt': doc.data()['likedAt'],
            });
          }
        } catch (e) {
          print('Error getting user data for comment like: $e');
          continue;
        }
      }

      return likes;
    } catch (error) {
      print('Error getting comment likes: $error');
      return [];
    }
  }
}
