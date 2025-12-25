import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models.dart';
import '../../pages/restaurant_detail_page.dart';

/// Restaurant Search Card Widget
///
/// A beautiful, full-width card component for displaying restaurant search results.
/// Features a hero image background with gradient overlay and information overlay.
///
/// Design elements:
/// - Hero image fills entire card (220px height)
/// - Gradient overlay from transparent to dark for text readability
/// - Restaurant name, keywords, district, and address displayed at bottom
/// - Keyword chips (max 3) in primary color
/// - Decorative menu icon in top-right corner
/// - Rounded corners (20px) with elevation shadow
/// - Smooth tap animation with InkWell ripple
///
/// This card follows Material Design 3 principles with proper elevation,
/// shadows, and interactive feedback.
class RestaurantSearchCard extends StatelessWidget {
  /// The restaurant to display
  final Restaurant restaurant;

  /// Language preference for bilingual content
  final bool isTraditionalChinese;

  /// Card height (default: 220px)
  final double height;

  const RestaurantSearchCard({
    required this.restaurant,
    required this.isTraditionalChinese,
    this.height = 220.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Get bilingual content
    final displayName = restaurant.getDisplayName(isTraditionalChinese);
    final displayDistrict = restaurant.getDisplayDistrict(isTraditionalChinese);
    final displayAddress = restaurant.getDisplayAddress(isTraditionalChinese);
    final displayKeywords = restaurant.getDisplayKeywords(isTraditionalChinese);

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to restaurant detail page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RestaurantDetailPage(
                  restaurant: restaurant,
                  isTraditionalChinese: isTraditionalChinese,
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image - fills the entire card
              _buildHeroImage(),

              // Gradient overlay for text readability
              // Gradient goes from transparent at top to dark at bottom
              _buildGradientOverlay(),

              // Content overlay positioned at bottom
              _buildContentOverlay(displayName, displayKeywords, displayDistrict, displayAddress),

              // Top-right decorative element
              _buildDecorativeIcon(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build Hero Image Background
  ///
  /// Uses CachedNetworkImage for performance with proper placeholder
  /// and error handling.
  Widget _buildHeroImage() {
    return CachedNetworkImage(
      imageUrl: restaurant.imageUrl ?? '',
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade300,
        child: const Icon(
          Icons.restaurant,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// Build Gradient Overlay
  ///
  /// Creates a gradient from transparent at top to dark at bottom
  /// for better text readability on the image.
  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
    );
  }

  /// Build Content Overlay
  ///
  /// Displays restaurant information at the bottom of the card:
  /// - Restaurant name (large, bold, white)
  /// - Keyword chips (max 3, primary color)
  /// - District with location icon
  /// - Address (truncated)
  Widget _buildContentOverlay(
    String displayName,
    List<String> displayKeywords,
    String displayDistrict,
    String displayAddress,
  ) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Restaurant name - large and prominent
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 4,
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // Keywords as small chips (max 3)
          if (displayKeywords.isNotEmpty)
            Builder(
              builder: (context) => Wrap(
                spacing: 6,
                runSpacing: 4,
                children: displayKeywords.take(3).map((keyword) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      keyword,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 8),

          // District with location icon
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 14,
                color: Colors.white70,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  displayDistrict,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // Address
          Text(
            displayAddress,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build Decorative Icon
  ///
  /// A circular white badge with restaurant menu icon in the top-right corner.
  /// Could be extended to show ratings or favorites in the future.
  Widget _buildDecorativeIcon(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(
          Icons.restaurant_menu,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
