import 'package:flutter/material.dart';
import '../../models.dart';
import 'star_rating.dart';

/// Review Form Widget
///
/// Allows users to create or edit a review with rating and comment.
/// Can be displayed in a dialog or bottom sheet.
class ReviewForm extends StatefulWidget {
  final Review? existingReview;
  final String restaurantId;
  final Function(double rating, String? comment) onSubmit;
  final VoidCallback? onCancel;

  const ReviewForm({
    super.key,
    required this.restaurantId,
    required this.onSubmit,
    this.existingReview,
    this.onCancel,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  late double _rating;
  late TextEditingController _commentController;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 0.0;
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_rating == 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a rating'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        await widget.onSubmit(_rating, _commentController.text.trim());
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
                  decoration: const InputDecoration(
                    labelText: 'Your Review (Optional)',
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),

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
  required Function(double rating, String? comment) onSubmit,
  Review? existingReview,
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
    ),
  );
}
