import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'firebase_service.dart';
import '../config/app_config.dart';

/// Storage Service - Handles file uploads to Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseService.instance.storage;
  final Uuid _uuid = const Uuid();

  // Upload single image
  Future<String> uploadImage({
    required File imageFile,
    required String storagePath,
    bool compress = true,
  }) async {
    try {
      File fileToUpload = imageFile;

      // Compress image if enabled
      if (compress) {
        fileToUpload = await _compressImage(imageFile);
      }

      // Generate unique filename
      final String fileName = '${_uuid.v4()}${path.extension(fileToUpload.path)}';
      final String fullPath = '$storagePath/$fileName';

      // Upload to Firebase Storage
      final Reference ref = _storage.ref(fullPath);
      final UploadTask uploadTask = ref.putFile(fileToUpload);

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String storagePath,
    bool compress = true,
  }) async {
    if (imageFiles.isEmpty) return [];
    if (imageFiles.length > AppConfig.maxImagesPerUpload) {
      throw Exception(
        'Maximum ${AppConfig.maxImagesPerUpload} images allowed',
      );
    }

    try {
      final List<Future<String>> uploadFutures = imageFiles.map((file) {
        return uploadImage(
          imageFile: file,
          storagePath: storagePath,
          compress: compress,
        );
      }).toList();

      return await Future.wait(uploadFutures);
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Delete image by URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Delete multiple images
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    if (imageUrls.isEmpty) return;

    try {
      final List<Future<void>> deleteFutures = imageUrls.map((url) {
        return deleteImage(url);
      }).toList();

      await Future.wait(deleteFutures);
    } catch (e) {
      throw Exception('Failed to delete images: $e');
    }
  }

  // Compress image
  Future<File> _compressImage(File imageFile) async {
    try {
      // Get file size
      final int fileSize = await imageFile.length();
      final int fileSizeInMB = fileSize ~/ (1024 * 1024);

      // Skip compression if file is already small
      if (fileSizeInMB < 1) return imageFile;

      // Compress the image
      final String targetPath = path.join(
        path.dirname(imageFile.path),
        'compressed_${path.basename(imageFile.path)}',
      );

      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: AppConfig.imageQuality,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (compressedFile == null) return imageFile;

      return File(compressedFile.path);
    } catch (e) {
      // If compression fails, return original file
      return imageFile;
    }
  }

  // Get storage reference
  Reference getReference(String path) {
    return _storage.ref(path);
  }

  // Check if file exists
  Future<bool> fileExists(String path) async {
    try {
      final Reference ref = _storage.ref(path);
      await ref.getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get file metadata
  Future<FullMetadata?> getMetadata(String path) async {
    try {
      final Reference ref = _storage.ref(path);
      return await ref.getMetadata();
    } catch (e) {
      return null;
    }
  }

  // List files in a directory
  Future<List<Reference>> listFiles(String path) async {
    try {
      final Reference ref = _storage.ref(path);
      final ListResult result = await ref.listAll();
      return result.items;
    } catch (e) {
      return [];
    }
  }
}
