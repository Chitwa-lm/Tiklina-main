import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  static CloudinaryService? _instance;
  static CloudinaryService get instance {
    _instance ??= CloudinaryService._();
    return _instance!;
  }

  CloudinaryService._();

  late final CloudinaryPublic _cloudinary;

  void initialize() {
    _cloudinary = CloudinaryPublic(
      CloudinaryConfig.cloudName,
      CloudinaryConfig.uploadPreset,
      cache: false,
    );
  }

  /// Upload an image file to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage({
    required File imageFile,
    String? folder,
    String? publicId,
  }) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: folder,
          publicId: publicId,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    String? folder,
  }) async {
    final List<String> urls = [];
    
    for (final file in imageFiles) {
      final url = await uploadImage(
        imageFile: file,
        folder: folder,
      );
      urls.add(url);
    }
    
    return urls;
  }

  /// Delete an image from Cloudinary using its public ID
  Future<void> deleteImage(String publicId) async {
    try {
      await _cloudinary.deleteFile(
        publicId: publicId,
        resourceType: CloudinaryResourceType.Image,
        invalidate: true,
      );
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}
