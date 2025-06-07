import 'dart:io';
import 'dart:typed_data';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageService {
  late Cloudinary _cloudinary;

  StorageService() {
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

  /// Upload image from File (mobile) - existing method
  Future<String> uploadImage({
    required File profileImage,
    required String userEmail,
    String imageType = 'profile',
  }) async {
    try {
      final folderPath = '$userEmail/$imageType';
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

  /// Upload image from Uint8List (web) - new method
  Future<String> uploadImageFromBytes({
    required Uint8List imageBytes,
    required String userEmail,
    String imageType = 'profile',
  }) async {
    try {
      final folderPath = '$userEmail/$imageType';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${imageType}_$timestamp';

      final response = await _cloudinary.upload(
        fileBytes: imageBytes,
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

  /// Universal upload method that handles both File and Uint8List
  Future<String> uploadImageUniversal({
    File? imageFile,
    Uint8List? imageBytes,
    required String userEmail,
    String imageType = 'profile',
  }) async {
    if (imageFile != null) {
      return uploadImage(
        profileImage: imageFile,
        userEmail: userEmail,
        imageType: imageType,
      );
    } else if (imageBytes != null) {
      return uploadImageFromBytes(
        imageBytes: imageBytes,
        userEmail: userEmail,
        imageType: imageType,
      );
    } else {
      throw Exception('Either imageFile or imageBytes must be provided');
    }
  }

  Future<bool> deleteImage({
    required String imageUrl,
    required String userEmail,
    String imageType = 'profile',
  }) async {
    try {
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