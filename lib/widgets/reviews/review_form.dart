import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models.dart';
import '../../services/image_service.dart';
import '../images/image_picker_button.dart';
import '../images/image_preview.dart';
import '../images/upload_progress_indicator.dart';
import 'star_rating.dart';

/// Review Form Widget
///
/// Allows users to create or edit a review with rating, comment, and optional image.
/// Can be displayed in a dialog or bottom sheet.
class ReviewForm extends StatefulWidget {
  final Review? existingReview;
  final String restaurantId;
  final Function(double rating, String? comment, String? imageUrl) onSubmit;
  final VoidCallback? onCancel;
  final bool isTraditionalChinese;

  const ReviewForm({
    super.key,
    required this.restaurantId,
    required this.onSubmit,
    this.existingReview,
    this.onCancel,
    this.isTraditionalChinese = false,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  late double _rating;
  late TextEditingController _commentController;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 0.0;
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
    _uploadedImageUrl = widget.existingReview?.imageUrl;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _onImageSelected(File image) {
    setState(() {
      _selectedImage = image;
      _uploadedImageUrl = null; // Clear existing URL when new image selected
    });
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_rating == 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese ? '請選擇評分' : 'Please select a rating',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        String? imageUrl = _uploadedImageUrl;

        // Upload image if one was selected
        if (_selectedImage != null) {
          final imageService = context.read<ImageService>();
          imageUrl = await imageService.uploadImage(
            imageFile: _selectedImage!,
            folder: 'Reviews',
            compress: true,
          );

          if (imageUrl == null) {
            throw Exception(
              widget.isTraditionalChinese ? '圖片上傳失敗' : 'Image upload failed',
            );
          }
        }

        await widget.onSubmit(
          _rating,
          _commentController.text.trim(),
          imageUrl,
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingReview != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  isEditing ? 'Edit Review' : 'Write a Review',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Rating selector
                Center(
                  child: StarRatingSelector(
                    initialRating: _rating,
                    onRatingChanged: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                    size: 40,
                    showRatingValue: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Comment field
                TextFormField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: widget.isTraditionalChinese
                        ? '您的評論（選填）'
                        : 'Your Review (Optional)',
                    hintText: widget.isTraditionalChinese
                        ? '分享您的體驗...'
                        : 'Share your experience...',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Image upload section
                if (_selectedImage != null || _uploadedImageUrl != null) ...[
                  SquareImagePreview(
                    image: _selectedImage ?? _uploadedImageUrl!,
                    size: 120,
                    showRemoveButton: true,
                    onRemove: _removeImage,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  ImagePickerButton(
                    onImageSelected: _onImageSelected,
                    label: widget.isTraditionalChinese ? '添加圖片（選填）' : 'Add Photo (Optional)',
                    icon: Icons.add_photo_alternate,
                    showCropOption: true,
                    isTraditionalChinese: widget.isTraditionalChinese,
                  ),
                  const SizedBox(height: 16),
                ],

                // Upload progress indicator
                UploadProgressWithError(
                  isTraditionalChinese: widget.isTraditionalChinese,
                ),
                const SizedBox(height: 8),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : widget.onCancel ?? () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isEditing ? 'Update' : 'Submit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows review form in a bottom sheet
Future<void> showReviewForm({
  required BuildContext context,
  required String restaurantId,
  required Function(double rating, String? comment, String? imageUrl) onSubmit,
  Review? existingReview,
  bool isTraditionalChinese = false,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => ReviewForm(
      restaurantId: restaurantId,
      onSubmit: onSubmit,
      existingReview: existingReview,
      isTraditionalChinese: isTraditionalChinese,
    ),
  );
}
