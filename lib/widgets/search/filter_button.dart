import 'package:flutter/material.dart';

/// Custom Filter Button Widget
///
/// A reusable filter button component that displays:
/// - Filter label (e.g., "Districts", "Categories")
/// - Badge with count of selected items (if any)
/// - Visual feedback when filters are active (highlighted border, primary color)
///
/// This button follows Material Design 3 principles with rounded corners,
/// subtle elevation, and clear visual hierarchy.
///
/// Usage:
/// ```dart
/// FilterButton(
///   label: 'Districts',
///   count: selectedDistricts.length,
///   onTap: () => _showDistrictFilterDialog(),
///   isTraditionalChinese: isTC,
/// )
/// ```
class FilterButton extends StatelessWidget {
  /// The label text displayed on the button
  final String label;

  /// Number of selected filter items (shows badge if > 0)
  final int count;

  /// Callback when button is tapped
  final VoidCallback onTap;

  /// Language preference (affects UI styling)
  final bool isTraditionalChinese;

  const FilterButton({
    required this.label,
    required this.count,
    required this.onTap,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = count > 0;
    final theme = Theme.of(context);

    return Material(
      color: hasSelection
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasSelection
                  ? theme.colorScheme.primary
                  : Colors.grey.shade400,
              width: hasSelection ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Filter icon
              Icon(
                Icons.filter_list,
                size: 18,
                color: hasSelection
                    ? theme.colorScheme.primary
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),

              // Label text
              Text(
                label,
                style: TextStyle(
                  fontWeight: hasSelection ? FontWeight.bold : FontWeight.normal,
                  color: hasSelection
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyLarge?.color,
                ),
              ),

              // Count badge (only shown when items are selected)
              if (hasSelection) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              // Dropdown arrow
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: hasSelection
                    ? theme.colorScheme.primary
                    : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
