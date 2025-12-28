import 'package:flutter/material.dart';

/// Quick question suggestion chips for AI chat
///
/// Displays a horizontal scrollable list of suggested questions
/// that users can tap to quickly send to the AI.
class SuggestionChips extends StatelessWidget {
  final bool isTraditionalChinese;
  final Function(String) onSuggestionTapped;
  final String? restaurantName;

  const SuggestionChips({
    required this.isTraditionalChinese,
    required this.onSuggestionTapped,
    this.restaurantName,
    super.key,
  });

  List<String> _getSuggestions() {
    if (restaurantName != null) {
      // Restaurant-specific suggestions
      return isTraditionalChinese
          ? [
        '呢間餐廳有咩招牌菜？',
        '營業時間係幾點至幾點？',
        '有咩素食選擇？',
        '價錢範圍係點？',
        '適合咩場合？',
      ]
          : [
        'What are the signature dishes?',
        'What are the opening hours?',
        'What vegan options are available?',
        'What is the price range?',
        'What occasions is this suitable for?',
      ];
    } else {
      // General dining suggestions
      return isTraditionalChinese
          ? [
        '推薦觀塘附近嘅素食餐廳',
        '有機素食餐廳有咩推薦',
        '適合一家大細聚餐嘅餐廳',
        '平價純素餐廳推薦',
        '灣仔區有咩素食選擇',
        '適合商務午餐嘅餐廳',
      ]
          : [
        'Recommend vegan restaurants in Central',
        'Suggest organic vegetarian places',
        'Family-friendly restaurants',
        'Budget-friendly vegan options',
        'Vegetarian choices in Wan Chai',
        'Good for business lunch',
      ];
    }
  }


  @override
  Widget build(BuildContext context) {
    final suggestions = _getSuggestions();
    final title = isTraditionalChinese ? '建議問題' : 'Suggested Questions';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return ActionChip(
                label: Text(
                  suggestions[index],
                  style: const TextStyle(fontSize: 13),
                ),
                avatar: Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => onSuggestionTapped(suggestions[index]),
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact version for smaller spaces
class CompactSuggestionChips extends StatelessWidget {
  final bool isTraditionalChinese;
  final Function(String) onSuggestionTapped;

  const CompactSuggestionChips({
    required this.isTraditionalChinese,
    required this.onSuggestionTapped,
    super.key,
  });

  List<String> _getCompactSuggestions() {
    return isTraditionalChinese
        ? ['推薦餐廳', '素食選擇', '營業時間', '價格範圍']
        : ['Recommendations', 'Vegan options', 'Hours', 'Price'];
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _getCompactSuggestions();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: suggestions.map((suggestion) {
        return Chip(
          label: Text(
            suggestion,
            style: const TextStyle(fontSize: 12),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onDeleted: () => onSuggestionTapped(suggestion),
          deleteIcon: const Icon(Icons.send, size: 14),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        );
      }).toList(),
    );
  }
}