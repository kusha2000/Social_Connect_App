import 'dart:io';
import 'dart:typed_data';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReelStorageService {
  late Cloudinary _cloudinary;

  ReelStorageService() {
    _initializeCloudinary();
  }

  void _initializeCloudinary() {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final apiKey = dotenv.env['CLOUDINARY_API_KEY'];
    final apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];

    if (cloudName == null || apiKey == null || apiSecret == null) {
      throw Exception('Cloudinary credentials not found in environment variables');
    }

    _cloudinary = Cloudinary.signedConfig(
      cloudName: cloudName,
      apiKey: apiKey,
      apiSecret: apiSecret,
    );
  }

  /// Upload video from File (mobile)
  Future<String> uploadVideo({
    required File videoFile,
    required String userEmail,
  }) async {
    try {
      final folderPath = '$userEmail/reels/videos';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'video_$timestamp';

      final response = await _cloudinary.upload(
        file: videoFile.path,
        fileBytes: videoFile.readAsBytesSync(),
        resourceType: CloudinaryResourceType.video,
        folder: folderPath,
        publicId: fileName,
      );

      if (response.isSuccessful) {
        return response.secureUrl ?? response.url ?? '';
      } else {
        throw Exception('Failed to upload video: ${response.error}');
      }
    } catch (e) {
      throw Exception('Error uploading video: $e');
    }
  }

  /// Upload video from Uint8List (web)
  Future<String> uploadVideoFromBytes({
    required Uint8List videoBytes,
    required String userEmail,
  }) async {
    try {
      final folderPath = '$userEmail/reels/videos';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'video_$timestamp';

      final response = await _cloudinary.upload(
        fileBytes: videoBytes,
        resourceType: CloudinaryResourceType.video,
        folder: folderPath,
        publicId: fileName,
      );

      if (response.isSuccessful) {
        return response.secureUrl ?? response.url ?? '';
      } else {
        throw Exception('Failed to upload video: ${response.error}');
      }
    } catch (e) {
      throw Exception('Error uploading video: $e');
    }
  }

  /// Universal upload method that handles both File and Uint8List
  Future<String> uploadVideoUniversal({
    File? videoFile,
    Uint8List? videoBytes,
    required String userEmail,
  }) async {
    if (videoFile != null) {
      return uploadVideo(
        videoFile: videoFile,
        userEmail: userEmail,
      );
    } else if (videoBytes != null) {
      return uploadVideoFromBytes(
        videoBytes: videoBytes,
        userEmail: userEmail,
      );
    } else {
      throw Exception('Either videoFile or videoBytes must be provided');
    }
  }

  /// Delete video from Cloudinary
  Future<bool> deleteVideo({
    required String videoUrl,
    required String userEmail,
  }) async {
    try {
      final publicId = _extractPublicIdFromUrl(videoUrl, userEmail);

      if (publicId == null) {
        throw Exception('Could not extract public ID from URL');
      }

      final response = await _cloudinary.destroy(
        publicId,
        resourceType: CloudinaryResourceType.video,
      );

      return response.isSuccessful;
    } catch (e) {
      print('Error deleting video: $e');
      return false;
    }
  }

  String? _extractPublicIdFromUrl(String url, String userEmail) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      int uploadIndex = -1;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'upload') {
          uploadIndex = i;
          break;
        }
      }

      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
        return null;
      }

      int startIndex = uploadIndex + 1;
      if (pathSegments[startIndex].startsWith('v') &&
          pathSegments[startIndex].length > 1 &&
          int.tryParse(pathSegments[startIndex].substring(1)) != null) {
        startIndex++;
      }

      final remainingSegments = pathSegments.sublist(startIndex);
      String publicId = remainingSegments.join('/');

      final lastDotIndex = publicId.lastIndexOf('.');
      if (lastDotIndex != -1) {
        publicId = publicId.substring(0, lastDotIndex);
      }

      return publicId;
    } catch (e) {
      print('Error extracting public ID: $e');
      return null;
    }
  }
}