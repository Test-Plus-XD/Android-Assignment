import 'package:flutter/material.dart';

/// Bulk Import Review Dialog
///
/// Shows extracted menu items from DocuPipe for review before saving.
/// Displays each item with bilingual names, descriptions, and prices
/// in a scrollable list for user confirmation.
class BulkImportReviewDialog extends StatelessWidget {
  final List<dynamic> menuItems;
  final bool isTraditionalChinese;

  const BulkImportReviewDialog({
    required this.menuItems,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isTraditionalChinese
            ? '¢åÐÖ„Ü®î (${menuItems.length})'
            : 'Review Extracted Menu Items (${menuItems.length})',
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            final nameEn = item['Name_EN'] ?? '';
            final nameTc = item['Name_TC'] ?? '';
            final price = item['price'];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  isTraditionalChinese
                      ? (nameTc.isNotEmpty ? nameTc : nameEn)
                      : (nameEn.isNotEmpty ? nameEn : nameTc),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (nameEn.isNotEmpty && nameTc.isNotEmpty)
                      Text(
                        isTraditionalChinese ? nameEn : nameTc,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (item['Description_EN'] != null ||
                        item['Description_TC'] != null)
                      Text(
                        isTraditionalChinese
                            ? (item['Description_TC'] ?? item['Description_EN'] ?? '')
                            : (item['Description_EN'] ?? item['Description_TC'] ?? ''),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: price != null
                    ? Text(
                        '\$${price.toString()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(isTraditionalChinese ? 'Öˆ' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            isTraditionalChinese ? 'ehè (${menuItems.length})' : 'Import All (${menuItems.length})',
          ),
        ),
      ],
    );
  }
}
