import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId;
  final String postId;
  final String userId;
  final String username;
  final String userProfileImage;
  final String text;
  final DateTime datePublished;
  final int likes;

  Comment({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.username,
    required this.userProfileImage,
    required this.text,
    required this.datePublished,
    this.likes = 0,
  });

  // Convert Comment to JSON
  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'postId': postId,
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'text': text,
      'datePublished': Timestamp.fromDate(datePublished),
      'likes': likes,
    };
  }

  // Create Comment from JSON
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['commentId'] ?? '',
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userProfileImage: json['userProfileImage'] ?? '',
      text: json['text'] ?? '',
      datePublished: (json['datePublished'] as Timestamp).toDate(),
      likes: json['likes'] ?? 0,
    );
  }

  // Create a copy with updated fields
  Comment copyWith({
    String? commentId,
    String? postId,
    String? userId,
    String? username,
    String? userProfileImage,
    String? text,
    DateTime? datePublished,
    int? likes,
  }) {
    return Comment(
      commentId: commentId ?? this.commentId,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      text: text ?? this.text,
      datePublished: datePublished ?? this.datePublished,
      likes: likes ?? this.likes,
    );
  }
}
