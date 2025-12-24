import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/image_service.dart';

/// Widget that displays upload progress from ImageService
/// Shows a linear progress indicator with percentage
class UploadProgressIndicator extends StatelessWidget {
  final bool isTraditionalChinese;
  final bool showPercentage;

  const UploadProgressIndicator({
    super.key,
    this.isTraditionalChinese = false,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageService>(
      builder: (context, imageService, child) {
        if (!imageService.isUploading) {
          return const SizedBox.shrink();
        }

        final progress = imageService.uploadProgress;
        final percentage = (progress * 100).toInt();

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_upload, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isTraditionalChinese ? '上傳中...' : 'Uploading...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (showPercentage)
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Circular progress indicator for uploads
class CircularUploadProgress extends StatelessWidget {
  final bool isTraditionalChinese;
  final double size;

  const CircularUploadProgress({
    super.key,
    this.isTraditionalChinese = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageService>(
      builder: (context, imageService, child) {
        if (!imageService.isUploading) {
          return const SizedBox.shrink();
        }

        final progress = imageService.uploadProgress;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: size / 4,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact inline upload progress indicator
class InlineUploadProgress extends StatelessWidget {
  final bool isTraditionalChinese;

  const InlineUploadProgress({
    super.key,
    this.isTraditionalChinese = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageService>(
      builder: (context, imageService, child) {
        if (!imageService.isUploading) {
          return const SizedBox.shrink();
        }

        final progress = imageService.uploadProgress;
        final percentage = (progress * 100).toInt();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isTraditionalChinese
                    ? '上傳中 $percentage%'
                    : 'Uploading $percentage%',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full-screen upload overlay with progress
class UploadOverlay extends StatelessWidget {
  final bool isTraditionalChinese;

  const UploadOverlay({
    super.key,
    this.isTraditionalChinese = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageService>(
      builder: (context, imageService, child) {
        if (!imageService.isUploading) {
          return const SizedBox.shrink();
        }

        final progress = imageService.uploadProgress;
        final percentage = (progress * 100).toInt();

        return Container(
          color: Colors.black54,
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(32),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_upload,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isTraditionalChinese ? '上傳圖片中' : 'Uploading Image',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Upload progress with error display
class UploadProgressWithError extends StatelessWidget {
  final bool isTraditionalChinese;

  const UploadProgressWithError({
    super.key,
    this.isTraditionalChinese = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageService>(
      builder: (context, imageService, child) {
        // Show error if present
        if (imageService.error != null) {
          return Card(
            margin: const EdgeInsets.all(16),
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isTraditionalChinese ? '上傳失敗' : 'Upload Failed',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => imageService.clearError(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    imageService.error!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        // Show progress if uploading
        if (imageService.isUploading) {
          return UploadProgressIndicator(
            isTraditionalChinese: isTraditionalChinese,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
