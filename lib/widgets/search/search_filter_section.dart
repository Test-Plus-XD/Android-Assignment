import 'package:flutter/material.dart';
import '../../constants/districts.dart';
import '../../constants/keywords.dart';
import 'filter_button.dart';

/// Search Filter Section Widget
///
/// Displays filter buttons and selected filter chips for restaurant search.
/// Provides:
/// - District filter button
/// - Category/keyword filter button
/// - Selected filters as removable chips
/// - Clear all button when multiple filters are selected
///
/// This widget manages the visual display of filters but delegates
/// state management and filter dialog display to the parent widget.
class SearchFilterSection extends StatelessWidget {
  final bool isTraditionalChinese;
  final Set<String> selectedDistrictsEn;
  final Set<String> selectedKeywordsEn;
  final VoidCallback onDistrictFilterTap;
  final VoidCallback onKeywordFilterTap;
  final Function(String) onDistrictRemoved;
  final Function(String) onKeywordRemoved;
  final VoidCallback onClearAll;

  const SearchFilterSection({
    required this.isTraditionalChinese,
    required this.selectedDistrictsEn,
    required this.selectedKeywordsEn,
    required this.onDistrictFilterTap,
    required this.onKeywordFilterTap,
    required this.onDistrictRemoved,
    required this.onKeywordRemoved,
    required this.onClearAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = selectedDistrictsEn.isNotEmpty ||
        selectedKeywordsEn.isNotEmpty;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // District filter button
                Expanded(
                  child: FilterButton(
                    label: isTraditionalChinese ? '地區' : 'Districts',
                    count: selectedDistrictsEn.length,
                    onTap: onDistrictFilterTap,
                    isTraditionalChinese: isTraditionalChinese,
                  ),
                ),

                const SizedBox(width: 12),

                // Category filter button
                Expanded(
                  child: FilterButton(
                    label: isTraditionalChinese ? '分類' : 'Categories',
                    count: selectedKeywordsEn.length,
                    onTap: onKeywordFilterTap,
                    isTraditionalChinese: isTraditionalChinese,
                  ),
                ),
              ],
            ),
          ),

          // Selected filters displayed as chips
          if (hasFilters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: Row(
                children: [
                  // District chips
                  ...selectedDistrictsEn.map((districtEn) {
                    final district = HKDistricts.findByEn(districtEn);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(
                          district?.getLabel(isTraditionalChinese) ??
                              districtEn,
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => onDistrictRemoved(districtEn),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                        deleteIconColor: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),

                  // Keyword chips
                  ...selectedKeywordsEn.map((keywordEn) {
                    final keyword = RestaurantKeywords.findByEn(keywordEn);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(
                          keyword?.getLabel(isTraditionalChinese) ??
                              keywordEn,
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => onKeywordRemoved(keywordEn),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondaryContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                        deleteIconColor: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),

                  // Clear all button (when multiple filters selected)
                  if (selectedDistrictsEn.length + selectedKeywordsEn.length > 1)
                    TextButton.icon(
                      onPressed: onClearAll,
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: Text(
                        isTraditionalChinese ? '清除全部' : 'Clear All',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
