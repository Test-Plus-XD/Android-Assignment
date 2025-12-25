import 'package:flutter/material.dart';

/// Filter Option
///
/// Represents a single filter option with English and Traditional Chinese labels.
class FilterOption {
  final String en;
  final String tc;

  const FilterOption({
    required this.en,
    required this.tc,
  });

  String getLabel(bool isTraditionalChinese) {
    return isTraditionalChinese ? tc : en;
  }
}

/// Generic Filter Dialog
///
/// A reusable modal bottom sheet for multi-select filtering.
/// Can be used for districts, keywords, categories, or any list of options.
///
/// Features:
/// - Modal bottom sheet with rounded top corners
/// - Drag handle for easy dismissal
/// - Header with title, clear button, and apply button
/// - Scrollable list of checkboxes
/// - Smooth animations and Material Design 3 styling
///
/// Usage:
/// ```dart
/// FilterDialog.show(
///   context: context,
///   title: 'Select Districts',
///   titleTC: '選擇地區',
///   options: HKDistricts.all.map((d) => FilterOption(en: d.en, tc: d.tc)).toList(),
///   selectedValues: _selectedDistrictsEn,
///   isTraditionalChinese: isTC,
///   onApply: (selected) {
///     setState(() {
///       _selectedDistrictsEn.clear();
///       _selectedDistrictsEn.addAll(selected);
///     });
///     _performSearch();
///   },
/// );
/// ```
class FilterDialog {
  /// Show Filter Dialog
  ///
  /// Displays a modal bottom sheet with multi-select checkboxes.
  ///
  /// @param context - Build context
  /// @param title - Dialog title in English
  /// @param titleTC - Dialog title in Traditional Chinese
  /// @param options - List of filter options to display
  /// @param selectedValues - Currently selected values (English keys)
  /// @param isTraditionalChinese - Language preference
  /// @param onApply - Callback when Apply button is tapped
  /// @param heightFactor - Height as fraction of screen height (default: 0.7)
  static void show({
    required BuildContext context,
    required String title,
    required String titleTC,
    required List<FilterOption> options,
    required Set<String> selectedValues,
    required bool isTraditionalChinese,
    required Function(Set<String>) onApply,
    double heightFactor = 0.7,
  }) {
    // Create a temporary copy to track changes during dialog
    final tempSelected = Set<String>.from(selectedValues);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * heightFactor,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle indicator
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header with title and action buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title
                        Text(
                          isTraditionalChinese ? titleTC : title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Action buttons
                        Row(
                          children: [
                            // Clear all button
                            TextButton(
                              onPressed: () {
                                setModalState(() => tempSelected.clear());
                              },
                              child: Text(
                                isTraditionalChinese ? '清除' : 'Clear',
                              ),
                            ),

                            // Apply button
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                onApply(tempSelected);
                              },
                              child: Text(
                                isTraditionalChinese ? '套用' : 'Apply',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Scrollable list of options with checkboxes
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: options.length,
                      itemBuilder: (dialogContext, index) {
                        final option = options[index];
                        final isSelected = tempSelected.contains(option.en);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (checked) {
                            setModalState(() {
                              if (checked == true) {
                                tempSelected.add(option.en);
                              } else {
                                tempSelected.remove(option.en);
                              }
                            });
                          },
                          title: Text(
                            option.getLabel(isTraditionalChinese),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Theme.of(context).colorScheme.primary,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
