import 'package:cloud_firestore/cloud_firestore.dart';

class Reel {
  final String caption;
  final String videoUrl;
  final String userId;
  final String username;
  final String userProfilePic;
  final String reelId;
  final int likes;
  final int comments;
  final DateTime datePublished;

  Reel({
    required this.caption,
    required this.videoUrl,
    required this.userId,
    required this.username,
    required this.userProfilePic,
    required this.reelId,
    required this.likes,
    required this.comments,
    required this.datePublished,
  });

  // Convert a Reel instance to a map (for saving to Firestore)
  Map<String, dynamic> toJson() {
    return {
      'caption': caption,
      'videoUrl': videoUrl,
      'userId': userId,
      'username': username,
      'userProfilePic': userProfilePic,
      'reelId': reelId,
      'likes': likes,
      'comments': comments,
      'datePublished': Timestamp.fromDate(datePublished),
    };
  }

  // Create a Reel instance from a map (for retrieving from Firestore)
  factory Reel.fromJson(Map<String, dynamic> json) {
    return Reel(
      caption: json['caption'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userProfilePic: json['userProfilePic'] ?? '',
      reelId: json['reelId'] ?? '',
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      datePublished: (json['datePublished'] as Timestamp).toDate(),
    );
  }
}
