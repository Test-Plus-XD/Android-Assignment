import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models.dart';

/// Callout card shown when a map pin is tapped in the search map view.
///
/// Displays a compact horizontal card with thumbnail, restaurant name,
/// address, and open/closed badge. Tapping navigates to the detail page.
class SearchMapCalloutCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool isTraditionalChinese;
  final VoidCallback onTap;

  const SearchMapCalloutCard({
    required this.restaurant,
    required this.isTraditionalChinese,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = restaurant.getDisplayName(isTraditionalChinese);
    final address = restaurant.getDisplayAddress(isTraditionalChinese);
    final isOpen = restaurant.isOpenNow;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 88,
          child: Row(
            children: [
              // Thumbnail
              SizedBox(
                width: 88,
                height: 88,
                child: CachedNetworkImage(
                  imageUrl: restaurant.imageUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
                ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Name
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Address
                      Text(
                        address,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Open/Closed badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isOpen ? Colors.green : Colors.red).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOpen ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isOpen
                              ? (isTraditionalChinese ? '營業中' : 'Open')
                              : (isTraditionalChinese ? '休息中' : 'Closed'),
                          style: TextStyle(
                            color: isOpen ? Colors.green[700] : Colors.red[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Chevron
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
