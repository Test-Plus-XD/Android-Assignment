import 'package:flutter/material.dart';

/// Star Rating Widget
///
/// Displays a rating as stars (filled/half/empty) and allows users to select a rating.
/// Supports both display-only mode and interactive mode.
class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color color;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 24.0,
    this.color = Colors.amber,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        final starValue = index + 1.0;
        final difference = rating - index;

        IconData iconData;
        if (difference >= 1.0) {
          iconData = Icons.star;
        } else if (difference >= 0.5) {
          iconData = Icons.star_half;
        } else {
          iconData = Icons.star_border;
        }

        if (interactive) {
          return GestureDetector(
            onTap: onRatingChanged != null
                ? () => onRatingChanged!(starValue)
                : null,
            child: Icon(
              iconData,
              color: color,
              size: size,
            ),
          );
        } else {
          return Icon(
            iconData,
            color: color,
            size: size,
          );
        }
      }),
    );
  }
}

/// Interactive Star Rating Selector
///
/// Allows users to select a rating by tapping on stars.
/// Displays the selected rating value.
class StarRatingSelector extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final int starCount;
  final double size;
  final Color color;
  final bool showRatingValue;

  const StarRatingSelector({
    super.key,
    required this.onRatingChanged,
    this.initialRating = 0.0,
    this.starCount = 5,
    this.size = 32.0,
    this.color = Colors.amber,
    this.showRatingValue = true,
  });

  @override
  State<StarRatingSelector> createState() => _StarRatingSelectorState();
}

class _StarRatingSelectorState extends State<StarRatingSelector> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.starCount, (index) {
            final starValue = index + 1.0;
            final isFilled = starValue <= _currentRating;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentRating = starValue;
                });
                widget.onRatingChanged(starValue);
              },
              child: Icon(
                isFilled ? Icons.star : Icons.star_border,
                color: widget.color,
                size: widget.size,
              ),
            );
          }),
        ),
        if (widget.showRatingValue && _currentRating > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${_currentRating.toStringAsFixed(1)} / ${widget.starCount}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
