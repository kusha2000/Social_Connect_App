import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserProfileStorageService {
  late Cloudinary _cloudinary;

  UserProfileStorageService() {
    _initializeCloudinary();
  }

  void _initializeCloudinary() {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final apiKey = dotenv.env['CLOUDINARY_API_KEY'];
    final apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];

    if (cloudName == null || apiKey == null || apiSecret == null) {
      throw Exception(
          'Cloudinary credentials not found in environment variables');
    }

    _cloudinary = Cloudinary.signedConfig(
      cloudName: cloudName,
      apiKey: apiKey,
      apiSecret: apiSecret,
    );
  }

  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage({
    required File profileImage,
    required String userEmail,
    String imageType = 'profile', // 'profile' or 'post'
  }) async {
    try {
      // Create folder path: email/profile or email/post
      final folderPath = '$userEmail/$imageType';

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${imageType}_$timestamp';

      final response = await _cloudinary.upload(
        file: profileImage.path,
        fileBytes: profileImage.readAsBytesSync(),
        resourceType: CloudinaryResourceType.image,
        folder: folderPath,
        publicId: fileName,
      );

      if (response.isSuccessful) {
        print("response:$response");
        return response.secureUrl ?? response.url ?? '';
      } else {
        throw Exception('Failed to upload image: ${response.error}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<bool> deleteImage({
    required String imageUrl,
    required String userEmail,
    String imageType = 'profile',
  }) async {
    try {
      // Extract public ID from URL
      final publicId = _extractPublicIdFromUrl(imageUrl, userEmail, imageType);

      if (publicId == null) {
        throw Exception('Could not extract public ID from URL');
      }

      final response = await _cloudinary.destroy(publicId);

      return response.isSuccessful;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  String? _extractPublicIdFromUrl(
      String url, String userEmail, String imageType) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Find the segment after 'upload' or 'image/upload'
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

      // Skip version if present (starts with 'v')
      int startIndex = uploadIndex + 1;
      if (pathSegments[startIndex].startsWith('v') &&
          pathSegments[startIndex].length > 1 &&
          int.tryParse(pathSegments[startIndex].substring(1)) != null) {
        startIndex++;
      }

      // Get remaining path segments and join them
      final remainingSegments = pathSegments.sublist(startIndex);
      String publicId = remainingSegments.join('/');

      // Remove file extension
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
