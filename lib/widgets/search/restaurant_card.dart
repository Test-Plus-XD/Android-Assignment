import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models.dart';
import '../../pages/restaurant_detail_page.dart';

/// Restaurant Card Widget for Search Results
///
/// Displays a restaurant in a visually appealing card format with:
/// - Full-width background image
/// - Gradient overlay for text readability
/// - Restaurant name, keywords, district, and address
/// - Fixed height for consistent scrolling
/// - Tap to navigate to restaurant detail page
///
/// Design approach:
/// - Restaurant image fills the entire card as background
/// - Gradient overlay from bottom ensures text readability
/// - Restaurant info positioned at bottom with white text
/// - Rounded corners and subtle shadow for depth
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool isTraditionalChinese;
  static const double cardHeight = 220.0;

  const RestaurantCard({
    required this.restaurant,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = restaurant.getDisplayName(isTraditionalChinese);
    final displayDistrict = restaurant.getDisplayDistrict(isTraditionalChinese);
    final displayAddress = restaurant.getDisplayAddress(isTraditionalChinese);
    final displayKeywords = restaurant.getDisplayKeywords(isTraditionalChinese);

    return Container(
      height: cardHeight,
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
              CachedNetworkImage(
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
              ),

              // Gradient overlay for text readability
              // Gradient goes from transparent at top to dark at bottom
              Container(
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
              ),

              // Content overlay positioned at bottom
              Positioned(
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

                    // Keywords as small chips
                    if (displayKeywords.isNotEmpty)
                      Wrap(
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
              ),

              // Top-right decorative element (optional: could show rating/favourite)
              Positioned(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
