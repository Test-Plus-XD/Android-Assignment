import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget for previewing images (local file or network URL)
/// Supports both File objects and URL strings
class ImagePreview extends StatelessWidget {
  final dynamic image; // Can be File or String (URL)
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool showRemoveButton;
  final VoidCallback? onRemove;
  final BorderRadius? borderRadius;
  final String? placeholder;

  const ImagePreview({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showRemoveButton = false,
    this.onRemove,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
            child: _buildImage(),
          ),
        ),
        if (showRemoveButton && onRemove != null)
          Positioned(
            top: -8,
            right: -8,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.red,
              child: IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.white),
                padding: EdgeInsets.zero,
                onPressed: onRemove,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    if (image is File) {
      return Image.file(
        image as File,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    } else if (image is String) {
      final url = image as String;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => _buildLoadingPlaceholder(),
          errorWidget: (context, url, error) => _buildErrorPlaceholder(),
        );
      }
    }

    return _buildErrorPlaceholder();
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 48,
            color: Colors.grey[400],
          ),
          if (placeholder != null) ...[
            const SizedBox(height: 8),
            Text(
              placeholder!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Square image preview (useful for profile pictures, thumbnails)
class SquareImagePreview extends StatelessWidget {
  final dynamic image;
  final double size;
  final bool showRemoveButton;
  final VoidCallback? onRemove;

  const SquareImagePreview({
    super.key,
    required this.image,
    this.size = 120,
    this.showRemoveButton = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ImagePreview(
      image: image,
      width: size,
      height: size,
      fit: BoxFit.cover,
      showRemoveButton: showRemoveButton,
      onRemove: onRemove,
      borderRadius: BorderRadius.circular(12),
    );
  }
}

/// Circular image preview (useful for avatars)
class CircularImagePreview extends StatelessWidget {
  final dynamic image;
  final double radius;
  final bool showRemoveButton;
  final VoidCallback? onRemove;

  const CircularImagePreview({
    super.key,
    required this.image,
    this.radius = 60,
    this.showRemoveButton = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          backgroundImage: _getImageProvider(),
        ),
        if (showRemoveButton && onRemove != null)
          Positioned(
            top: -4,
            right: -4,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.red,
              child: IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                padding: EdgeInsets.zero,
                onPressed: onRemove,
              ),
            ),
          ),
      ],
    );
  }

  ImageProvider? _getImageProvider() {
    if (image is File) {
      return FileImage(image as File);
    } else if (image is String) {
      final url = image as String;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return CachedNetworkImageProvider(url);
      }
    }
    return null;
  }
}

/// Wide image preview (useful for banners, headers)
class WideImagePreview extends StatelessWidget {
  final dynamic image;
  final double? width;
  final double aspectRatio;
  final bool showRemoveButton;
  final VoidCallback? onRemove;

  const WideImagePreview({
    super.key,
    required this.image,
    this.width,
    this.aspectRatio = 16 / 9,
    this.showRemoveButton = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidth = width ?? MediaQuery.of(context).size.width;
    final imageHeight = imageWidth / aspectRatio;

    return ImagePreview(
      image: image,
      width: imageWidth,
      height: imageHeight,
      fit: BoxFit.cover,
      showRemoveButton: showRemoveButton,
      onRemove: onRemove,
      borderRadius: BorderRadius.circular(12),
    );
  }
}

/// Image grid preview (useful for multiple images)
class ImageGridPreview extends StatelessWidget {
  final List<dynamic> images;
  final int crossAxisCount;
  final double spacing;
  final double childAspectRatio;
  final bool showRemoveButtons;
  final Function(int)? onRemove;

  const ImageGridPreview({
    super.key,
    required this.images,
    this.crossAxisCount = 3,
    this.spacing = 8,
    this.childAspectRatio = 1,
    this.showRemoveButtons = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return ImagePreview(
          image: images[index],
          fit: BoxFit.cover,
          showRemoveButton: showRemoveButtons,
          onRemove: onRemove != null ? () => onRemove!(index) : null,
        );
      },
    );
  }
}
