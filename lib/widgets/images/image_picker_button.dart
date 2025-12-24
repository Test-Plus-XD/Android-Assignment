import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/image_service.dart';

/// Button widget for picking images from camera or gallery
/// Shows a dialog to choose between camera and gallery
class ImagePickerButton extends StatelessWidget {
  final Function(File) onImageSelected;
  final String? label;
  final IconData? icon;
  final bool showCropOption;
  final bool isTraditionalChinese;

  const ImagePickerButton({
    super.key,
    required this.onImageSelected,
    this.label,
    this.icon,
    this.showCropOption = false,
    this.isTraditionalChinese = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageService = context.read<ImageService>();

    return ElevatedButton.icon(
      onPressed: () => _showImageSourceDialog(context, imageService),
      icon: Icon(icon ?? Icons.add_photo_alternate),
      label: Text(label ?? (isTraditionalChinese ? '選擇圖片' : 'Select Image')),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog(
    BuildContext context,
    ImageService imageService,
  ) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isTraditionalChinese ? '選擇圖片來源' : 'Select Image Source',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt, size: 32),
                  title: Text(
                    isTraditionalChinese ? '相機' : 'Camera',
                    style: const TextStyle(fontSize: 18),
                  ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await _pickImage(context, imageService, ImageSource.camera);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.photo_library, size: 32),
                  title: Text(
                    isTraditionalChinese ? '相簿' : 'Gallery',
                    style: const TextStyle(fontSize: 18),
                  ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await _pickImage(context, imageService, ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(bottomSheetContext),
                  child: Text(isTraditionalChinese ? '取消' : 'Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    ImageService imageService,
    ImageSource source,
  ) async {
    try {
      // Pick image
      final file = await imageService.pickImage(source: source);
      if (file == null) return;

      // Optionally crop image
      File? finalFile = file;
      if (showCropOption && context.mounted) {
        final shouldCrop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isTraditionalChinese ? '裁剪圖片？' : 'Crop Image?'),
            content: Text(
              isTraditionalChinese
                  ? '您想裁剪圖片嗎？'
                  : 'Would you like to crop the image?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isTraditionalChinese ? '跳過' : 'Skip'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(isTraditionalChinese ? '裁剪' : 'Crop'),
              ),
            ],
          ),
        );

        if (shouldCrop == true) {
          final croppedFile = await imageService.cropImage(imageFile: file);
          if (croppedFile != null) {
            finalFile = croppedFile;
          }
        }
      }

      // Call callback with selected/cropped image
      if (context.mounted && finalFile != null) {
        onImageSelected(finalFile);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTraditionalChinese
                  ? '選擇圖片失敗: $e'
                  : 'Failed to select image: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Compact icon button version of image picker
class ImagePickerIconButton extends StatelessWidget {
  final Function(File) onImageSelected;
  final bool showCropOption;
  final bool isTraditionalChinese;
  final IconData? icon;
  final Color? iconColor;

  const ImagePickerIconButton({
    super.key,
    required this.onImageSelected,
    this.showCropOption = false,
    this.isTraditionalChinese = false,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final imageService = context.read<ImageService>();

    return IconButton(
      icon: Icon(
        icon ?? Icons.add_photo_alternate,
        color: iconColor,
      ),
      onPressed: () => _showImageSourceDialog(context, imageService),
      tooltip: isTraditionalChinese ? '選擇圖片' : 'Select Image',
    );
  }

  Future<void> _showImageSourceDialog(
    BuildContext context,
    ImageService imageService,
  ) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isTraditionalChinese ? '選擇圖片來源' : 'Select Image Source',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt, size: 32),
                  title: Text(
                    isTraditionalChinese ? '相機' : 'Camera',
                    style: const TextStyle(fontSize: 18),
                  ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await _pickImage(context, imageService, ImageSource.camera);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.photo_library, size: 32),
                  title: Text(
                    isTraditionalChinese ? '相簿' : 'Gallery',
                    style: const TextStyle(fontSize: 18),
                  ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await _pickImage(context, imageService, ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(bottomSheetContext),
                  child: Text(isTraditionalChinese ? '取消' : 'Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    ImageService imageService,
    ImageSource source,
  ) async {
    try {
      final file = await imageService.pickImage(source: source);
      if (file == null) return;

      File? finalFile = file;
      if (showCropOption && context.mounted) {
        final shouldCrop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isTraditionalChinese ? '裁剪圖片？' : 'Crop Image?'),
            content: Text(
              isTraditionalChinese
                  ? '您想裁剪圖片嗎？'
                  : 'Would you like to crop the image?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isTraditionalChinese ? '跳過' : 'Skip'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(isTraditionalChinese ? '裁剪' : 'Crop'),
              ),
            ],
          ),
        );

        if (shouldCrop == true) {
          final croppedFile = await imageService.cropImage(imageFile: file);
          if (croppedFile != null) {
            finalFile = croppedFile;
          }
        }
      }

      if (context.mounted && finalFile != null) {
        onImageSelected(finalFile);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTraditionalChinese
                  ? '選擇圖片失敗: $e'
                  : 'Failed to select image: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
