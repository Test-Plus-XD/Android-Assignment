import 'package:flutter/material.dart';
import '../../models.dart';

/// Menu Preview Section Widget
///
/// Displays a horizontal scrollable preview of menu items.
/// Shows up to 6 items with image, name, and price.
class MenuPreviewSection extends StatelessWidget {
  final Future<List<MenuItem>>? menuItemsFuture;
  final bool isTraditionalChinese;
  final VoidCallback onSeeAll;

  const MenuPreviewSection({
    required this.menuItemsFuture,
    required this.isTraditionalChinese,
    required this.onSeeAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MenuItem>>(
      future: menuItemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(isTraditionalChinese ? '暫無菜單' : 'No menu available', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          );
        }
        final items = snapshot.data!.take(6).toList();
        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _MenuPreviewCard(item: items[index], isTraditionalChinese: isTraditionalChinese),
          ),
        );
      },
    );
  }
}

/// Menu Preview Card for carousel display
class _MenuPreviewCard extends StatelessWidget {
  final MenuItem item;
  final bool isTraditionalChinese;

  const _MenuPreviewCard({required this.item, required this.isTraditionalChinese});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = item.getDisplayName(isTraditionalChinese);
    final price = item.getFormattedPrice();

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80,
            width: double.infinity,
            child: item.image != null && item.image!.isNotEmpty
                ? Image.network(item.image!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.restaurant, color: Colors.grey)))
                : Container(color: Colors.grey[200], child: const Icon(Icons.restaurant, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                if (price.isNotEmpty) Text(price, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
