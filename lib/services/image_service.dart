import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import '../config.dart';
import '../models.dart';

/// [ImageService] is a [ChangeNotifier] that manages image-related operations.
/// 
/// It provides functionality for:
/// * Requesting necessary permissions (camera, gallery).
/// * Picking images from different sources using [ImagePicker].
/// * Cropping images with a customizable UI via [ImageCropper].
/// * Compressing images to save bandwidth and storage using [FlutterImageCompress].
/// * Uploading, deleting, and retrieving metadata for images via a remote API.
/// 
/// It maintains state for upload progress and error messages to be consumed by the UI.
class ImageService extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  // Internal state for managing upload status and errors
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;

  /// Returns true if an image upload is currently in progress.
  bool get isUploading => _isUploading;

  /// Returns the current upload progress as a value between 0.0 and 1.0.
  double get uploadProgress => _uploadProgress;

  /// Returns the last error message encountered, if any.
  String? get error => _error;

  ImageService();

  /// Clears the current error state and notifies listeners.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Requests permission to access the device camera.
  /// 
  /// Returns [true] if permission is granted, [false] otherwise.
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Requests permission to access the device's photo gallery or storage.
  /// 
  /// On Android, it checks for both 'photos' and 'storage' permissions to ensure compatibility
  /// across different OS versions.
  /// Returns [true] if permission is granted, [false] otherwise.
  Future<bool> requestPhotosPermission() async {
    if (Platform.isAndroid) {
      // Check if already granted
      if (await Permission.photos.isGranted) return true;
      if (await Permission.storage.isGranted) return true;
      
      // Request photos permission (Android 13+)
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted) return true;
      
      // Fallback to storage permission (Android 12 and below)
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    // iOS handles permissions via Info.plist and system dialogs triggered by ImagePicker
    return true;
  }

  /// Picks an image from the specified [source] (camera or gallery).
  /// 
  /// [imageQuality] (0-100) controls the initial compression applied by the picker.
  /// [maxWidth] and [maxHeight] can be used to resize the image during picking.
  /// 
  /// Returns a [File] object if successful, or [null] if the user cancelled or an error occurred.
  Future<File?> pickImage({
    required ImageSource source,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      _error = null;
      notifyListeners();

      // Ensure permissions are granted before opening the picker
      if (source == ImageSource.camera) {
        if (!await requestCameraPermission()) {
          _error = 'Camera permission denied';
          notifyListeners();
          return null;
        }
      } else {
        if (!await requestPhotosPermission()) {
          _error = 'Photos permission denied';
          notifyListeners();
          return null;
        }
      }

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
      return null;
    }
  }

  /// Opens the image cropper UI for the provided [imageFile].
  /// 
  /// [aspectRatio] defines the target ratio (e.g., square).
  /// [aspectRatioPresets] lists the available ratios for the user to choose from.
  /// 
  /// Returns a cropped [File] or [null] if the user cancelled.
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
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.green,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: aspectRatioPresets,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: aspectRatioPresets,
          ),
        ],
      );

      if (croppedFile == null) return null;
      return File(croppedFile.path);
    } catch (e) {
      _error = 'Failed to crop image: $e';
      notifyListeners();
      return null;
    }
  }

  /// Compresses the [imageFile] if it exceeds [maxSizeKB].
  /// 
  /// [quality] (1-100) determines the compression level.
  /// Creates a new temporary file with a '_compressed' suffix.
  /// 
  /// Returns the compressed [File], or the original file if compression failed or wasn't needed.
  Future<File?> compressImage({
    required File imageFile,
    int quality = 85,
    int maxSizeKB = 1024,
  }) async {
    try {
      final fileSize = await imageFile.length();
      // Skip compression if file is already small enough
      if (fileSize <= maxSizeKB * 1024) return imageFile;

      final dir = path.dirname(imageFile.path);
      final fileName = path.basenameWithoutExtension(imageFile.path);
      final ext = path.extension(imageFile.path);
      final targetPath = path.join(dir, '${fileName}_compressed$ext');

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
      );

      return compressedFile != null ? File(compressedFile.path) : imageFile;
    } catch (e) {
      _error = 'Failed to compress image: $e';
      notifyListeners();
      return imageFile;
    }
  }

  /// Uploads the [imageFile] to the remote API.
  /// 
  /// [folder] specifies the destination directory on the server.
  /// [compress] if true, will run [compressImage] before uploading.
  /// 
  /// This method updates [_uploadProgress] and [_isUploading] throughout the process.
  /// Returns the download URL string on success, or [null] on failure.
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

      File fileToUpload = imageFile;
      if (compress) {
        _uploadProgress = 0.1;
        notifyListeners();
        final compressed = await compressImage(imageFile: imageFile, quality: compressQuality);
        if (compressed != null) fileToUpload = compressed;
      }

      _uploadProgress = 0.2;
      notifyListeners();

      // Construct the upload URI with the target folder as a query parameter
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/API/Images/upload?folder=$folder');
      
      // Use MultipartRequest for file uploads
      final request = http.MultipartRequest('POST', uri);
      request.headers['x-api-passcode'] = AppConfig.apiPasscode;

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        fileToUpload.path,
        filename: path.basename(fileToUpload.path),
      ));

      _uploadProgress = 0.3;
      notifyListeners();

      // Send the request and wait for the streamed response
      final streamedResponse = await request.send();
      _uploadProgress = 0.8;
      notifyListeners();

      // Convert streamed response to a standard response to access body
      final response = await http.Response.fromStream(streamedResponse);
      _uploadProgress = 1.0;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _isUploading = false;
        notifyListeners();
        // Expecting a JSON object with a 'downloadURL' key
        return data['downloadURL'] as String?;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Failed to upload image: $e';
      _isUploading = false;
      notifyListeners();
      return null;
    }
  }

  /// Deletes a remote image file identified by [filePath].
  /// 
  /// Returns [true] if the deletion was successful (HTTP 200).
  Future<bool> deleteImage(String filePath) async {
    try {
      _error = null;
      notifyListeners();

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/API/Images/delete');
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-passcode': AppConfig.apiPasscode,
        },
        body: json.encode({'filePath': filePath}),
      );

      return response.statusCode == 200;
    } catch (e) {
      _error = 'Failed to delete image: $e';
      notifyListeners();
      return false;
    }
  }

  /// Retrieves metadata for a remote image file.
  /// 
  /// Returns an [ImageMetadata] object if successful, or [null] otherwise.
  Future<ImageMetadata?> getImageMetadata(String filePath) async {
    try {
      _error = null;
      notifyListeners();

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/API/Images/metadata?filePath=$filePath');
      final response = await http.get(
        uri,
        headers: {'x-api-passcode': AppConfig.apiPasscode},
      );

      if (response.statusCode == 200) {
        return ImageMetadata.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      _error = 'Failed to get image metadata: $e';
      notifyListeners();
      return null;
    }
  }

  /// Displays an [AlertDialog] allowing the user to choose between Camera and Gallery.
  /// 
  /// Automatically calls [pickImage] based on the user's selection.
  /// Returns the picked [File] or [null] if the dialog was dismissed.
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
                  final file = await pickImage(source: ImageSource.camera);
                  if (context.mounted) Navigator.pop(context, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  final file = await pickImage(source: ImageSource.gallery);
                  if (context.mounted) Navigator.pop(context, file);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
