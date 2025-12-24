import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'dart:convert';
import '../config.dart';
import '../models.dart';
import 'auth_service.dart';

/// Service for handling image upload, deletion, and selection
/// Integrates with Firebase Storage via Vercel Express API
class ImageService extends ChangeNotifier {
  final AuthService _authService;
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;

  ImageService(this._authService);

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request photos permission
  Future<bool> requestPhotosPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ uses different permissions
      if (await Permission.photos.isGranted) return true;
      if (await Permission.storage.isGranted) return true;

      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted) return true;

      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true; // iOS/Web handle permissions differently
  }

  /// Pick an image from gallery or camera
  /// Returns the picked image file or null if cancelled/failed
  Future<File?> pickImage({
    required ImageSource source,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      _error = null;
      notifyListeners();

      // Request appropriate permission
      if (source == ImageSource.camera) {
        final hasPermission = await requestCameraPermission();
        if (!hasPermission) {
          _error = 'Camera permission denied';
          notifyListeners();
          return null;
        }
      } else {
        final hasPermission = await requestPhotosPermission();
        if (!hasPermission) {
          _error = 'Photos permission denied';
          notifyListeners();
          return null;
        }
      }

      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      _error = 'Failed to pick image: $e';
      notifyListeners();
      if (kDebugMode) print('Error picking image: $e');
      return null;
    }
  }

  /// Crop an image
  /// Returns the cropped image file or null if cancelled/failed
  Future<File?> cropImage({
    required File imageFile,
    CropAspectRatio? aspectRatio,
    List<CropAspectRatioPreset> aspectRatioPresets = const [
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9,
    ],
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: aspectRatio,
        aspectRatioPresets: aspectRatioPresets,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.green,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
        ],
      );

      if (croppedFile == null) return null;

      return File(croppedFile.path);
    } catch (e) {
      _error = 'Failed to crop image: $e';
      notifyListeners();
      if (kDebugMode) print('Error cropping image: $e');
      return null;
    }
  }

  /// Compress an image to reduce file size
  /// Returns the compressed image file or null if failed
  Future<File?> compressImage({
    required File imageFile,
    int quality = 85,
    int maxSizeKB = 1024, // 1MB default
  }) async {
    try {
      final fileSize = await imageFile.length();

      // Skip compression if already small enough
      if (fileSize <= maxSizeKB * 1024) {
        return imageFile;
      }

      final dir = path.dirname(imageFile.path);
      final fileName = path.basenameWithoutExtension(imageFile.path);
      final ext = path.extension(imageFile.path);
      final targetPath = path.join(dir, '${fileName}_compressed$ext');

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
      );

      if (compressedFile == null) return imageFile;

      return File(compressedFile.path);
    } catch (e) {
      _error = 'Failed to compress image: $e';
      notifyListeners();
      if (kDebugMode) print('Error compressing image: $e');
      return imageFile; // Return original if compression fails
    }
  }

  /// Upload an image to Firebase Storage via API
  /// Returns the download URL of the uploaded image
  ///
  /// Folders:
  /// - Menu/{restaurantId} - Menu item images
  /// - Restaurants/{restaurantId} - Restaurant images
  /// - Profiles - User profile pictures
  /// - Chat - Chat attachments
  /// - Banners - Promotional content
  /// - General - Default folder
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    bool compress = true,
    int compressQuality = 85,
  }) async {
    try {
      _isUploading = true;
      _uploadProgress = 0.0;
      _error = null;
      notifyListeners();

      // Get auth token
      final token = await _authService.getIdToken(forceRefresh: false);
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Compress image if requested
      File fileToUpload = imageFile;
      if (compress) {
        _uploadProgress = 0.1;
        notifyListeners();

        final compressed = await compressImage(
          imageFile: imageFile,
          quality: compressQuality,
        );
        if (compressed != null) {
          fileToUpload = compressed;
        }
      }

      _uploadProgress = 0.2;
      notifyListeners();

      // Detect MIME type
      final mimeType = lookupMimeType(fileToUpload.path) ?? 'image/jpeg';
      final fileName = path.basename(fileToUpload.path);

      // Create multipart request
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/API/Images/upload?folder=$folder');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['x-api-passcode'] = AppConfig.apiPasscode;

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          fileToUpload.path,
          filename: fileName,
        ),
      );

      _uploadProgress = 0.3;
      notifyListeners();

      // Send request
      final streamedResponse = await request.send();
      _uploadProgress = 0.8;
      notifyListeners();

      // Get response
      final response = await http.Response.fromStream(streamedResponse);
      _uploadProgress = 1.0;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final downloadURL = data['downloadURL'] as String?;

        if (downloadURL == null) {
          throw Exception('No download URL in response');
        }

        if (kDebugMode) print('Image uploaded successfully: $downloadURL');

        _isUploading = false;
        notifyListeners();
        return downloadURL;
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _error = 'Failed to upload image: $e';
      _isUploading = false;
      notifyListeners();
      if (kDebugMode) print('Error uploading image: $e');
      return null;
    }
  }

  /// Delete an image from Firebase Storage via API
  Future<bool> deleteImage(String filePath) async {
    try {
      _error = null;
      notifyListeners();

      // Get auth token
      final token = await _authService.getIdToken(forceRefresh: false);
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/API/Images/delete');
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
        },
        body: json.encode({'filePath': filePath}),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) print('Image deleted successfully');
        return true;
      } else {
        throw Exception('Delete failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _error = 'Failed to delete image: $e';
      notifyListeners();
      if (kDebugMode) print('Error deleting image: $e');
      return false;
    }
  }

  /// Get metadata for an uploaded image
  Future<ImageMetadata?> getImageMetadata(String filePath) async {
    try {
      _error = null;
      notifyListeners();

      // Get auth token
      final token = await _authService.getIdToken(forceRefresh: false);
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/API/Images/metadata?filePath=$filePath');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-passcode': AppConfig.apiPasscode,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ImageMetadata.fromJson(data);
      } else {
        throw Exception('Get metadata failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _error = 'Failed to get image metadata: $e';
      notifyListeners();
      if (kDebugMode) print('Error getting image metadata: $e');
      return null;
    }
  }

  /// Show image source selection dialog (Camera or Gallery)
  /// Returns the selected image file or null if cancelled
  Future<File?> showImageSourceDialog(BuildContext context) async {
    return showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await pickImage(source: ImageSource.camera);
                  if (context.mounted && file != null) {
                    Navigator.pop(context, file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await pickImage(source: ImageSource.gallery);
                  if (context.mounted && file != null) {
                    Navigator.pop(context, file);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
