import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/image_service.dart';

/// Restaurant Image Upload Widget
///
/// Allows restaurant owners to:
/// - Select an image from gallery or camera
/// - Preview the selected image
/// - Upload the image to Firebase Storage
/// - Display upload progress
/// - Update restaurant image URL
class RestaurantImageUpload extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String imageUrl) onImageUploaded;
  final bool isTraditionalChinese;

  const RestaurantImageUpload({
    super.key,
    this.currentImageUrl,
    required this.onImageUploaded,
    this.isTraditionalChinese = false,
  });

  @override
  State<RestaurantImageUpload> createState() => _RestaurantImageUploadState();
}

class _RestaurantImageUploadState extends State<RestaurantImageUpload> {
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _uploadedImageUrl = widget.currentImageUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    final imageService = context.read<ImageService>();
    final image = await imageService.pickImage(source: source);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });

      // Auto-upload immediately after selection
      await _uploadImage();
    }
  }

  Future<void> _showImageSourceDialog() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.isTraditionalChinese ? '選擇圖片來源' : 'Select Image Source',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(widget.isTraditionalChinese ? '拍攝照片' : 'Take Photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(widget.isTraditionalChinese ? '從相冊選擇' : 'Choose from Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final imageService = context.read<ImageService>();

      // Upload to Vercel API via ImageService (centralised)
      final result = await imageService.uploadImage(
        imageFile: _selectedImage!,
        folder: 'Restaurants',
        compress: true,
        compressQuality: 85,
      );

      if (result != null && result['url'] != null) {
        final imageUrl = result['url']!;

        setState(() {
          _uploadedImageUrl = imageUrl;
          _uploadProgress = 1.0;
        });

        // Notify parent widget
        widget.onImageUploaded(imageUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isTraditionalChinese ? '圖片上傳成功' : 'Image uploaded successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(imageService.error ?? 'No download URL returned');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese ? '圖片上傳失敗：$e' : 'Image upload failed: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Revert to previous state
      setState(() {
        _selectedImage = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayUrl = _uploadedImageUrl ?? widget.currentImageUrl;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.isTraditionalChinese ? '餐廳圖片' : 'Restaurant Image',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Image preview
            Center(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            )
                          : displayUrl != null && displayUrl.isNotEmpty
                              ? Image.network(
                                  displayUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildPlaceholder(theme),
                                )
                              : _buildPlaceholder(theme),
                    ),
                  ),

                  // Upload progress overlay
                  if (_isUploading)
                    Consumer<ImageService>(
                      builder: (context, imageService, child) => Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    value: imageService.uploadProgress,
                                    color: Colors.white,
                                    strokeWidth: 4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${(imageService.uploadProgress * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.isTraditionalChinese ? '上傳中...' : 'Uploading...',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _showImageSourceDialog,
                icon: const Icon(Icons.upload),
                label: Text(
                  widget.isTraditionalChinese ? '選擇圖片' : 'Select Image',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Helper text
            if (!_isUploading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.isTraditionalChinese
                      ? '建議尺寸：1200x800 像素，最大 10MB'
                      : 'Recommended size: 1200x800 pixels, max 10MB',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            widget.isTraditionalChinese ? '未選擇圖片' : 'No image selected',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
