import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_connect/models/post_model.dart';
import 'package:social_connect/services/storage/storage.dart';
import 'package:social_connect/utils/util_functions/mood.dart';

class FeedService {
  // Create a collection reference
  final CollectionReference _feedCollection =
      FirebaseFirestore.instance.collection('feed');

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

      return true; // Return true if successful
    } catch (error) {
      print('Error saving post: $error');
      return false; // Return false if failed
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

      return true; // Return true if successful
    } catch (error) {
      print('Error saving post: $error');
      return false; // Return false if failed
    }
  }
}
