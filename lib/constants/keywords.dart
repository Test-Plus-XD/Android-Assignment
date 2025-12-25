/// Restaurant Keyword Constants
///
/// This file contains all dietary and cuisine-related keywords with bilingual names.
/// Matches Angular project constants exactly.

class KeywordOption {
  final String en;
  final String tc;

  const KeywordOption({
    required this.en,
    required this.tc,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeywordOption &&
          runtimeType == other.runtimeType &&
          en == other.en &&
          tc == other.tc;

  @override
  int get hashCode => en.hashCode ^ tc.hashCode;

  @override
  String toString() => en;

  String getName(bool isTraditionalChinese) =>
      isTraditionalChinese ? tc : en;

  /// Alias for getName - for compatibility with existing code
  String getLabel(bool isTraditionalChinese) =>
      getName(isTraditionalChinese);
}

class RestaurantKeywords {
  /// All keywords matching Angular project (114 keywords)
  static const List<KeywordOption> all = [
    // Core vegan/plant-based categories
    KeywordOption(en: 'Vegan', tc: '純素'),
    KeywordOption(en: 'Vegetarian', tc: '素食'),
    KeywordOption(en: 'Plant-Based', tc: '植物性'),
    KeywordOption(en: 'Organic', tc: '有機'),
    KeywordOption(en: 'Farm-to-Table', tc: '農場直送'),
    KeywordOption(en: 'Sustainable', tc: '可持續'),
    KeywordOption(en: 'Eco-Friendly', tc: '環保'),
    KeywordOption(en: 'Whole Foods', tc: '全食物'),
    KeywordOption(en: 'Raw Vegan', tc: '生機素食'),
    KeywordOption(en: 'Macrobiotic', tc: '長壽飲食'),

    // Religious dietary preferences
    KeywordOption(en: 'Buddhism', tc: '佛教'),
    KeywordOption(en: 'Buddhist Vegetarian', tc: '齋'),
    KeywordOption(en: 'Muslim', tc: '穆斯林'),
    KeywordOption(en: 'Halal', tc: '清真'),
    KeywordOption(en: 'Kosher', tc: '猶太潔食'),
    KeywordOption(en: 'Jain', tc: '耆那教'),
    KeywordOption(en: 'Hindu', tc: '印度教'),
    KeywordOption(en: 'Taoist', tc: '道教'),

    // Cuisine types
    KeywordOption(en: 'Asian', tc: '亞洲菜'),
    KeywordOption(en: 'Chinese', tc: '中菜'),
    KeywordOption(en: 'Japanese', tc: '日本菜'),
    KeywordOption(en: 'Korean', tc: '韓國菜'),
    KeywordOption(en: 'Thai', tc: '泰國菜'),
    KeywordOption(en: 'Vietnamese', tc: '越南菜'),
    KeywordOption(en: 'Indian', tc: '印度菜'),
    KeywordOption(en: 'Italian', tc: '意大利菜'),
    KeywordOption(en: 'Mediterranean', tc: '地中海菜'),
    KeywordOption(en: 'Mexican', tc: '墨西哥菜'),
    KeywordOption(en: 'Middle Eastern', tc: '中東菜'),
    KeywordOption(en: 'Western', tc: '西式'),
    KeywordOption(en: 'Fusion', tc: '融合菜'),
    KeywordOption(en: 'International', tc: '國際菜'),

    // Restaurant types
    KeywordOption(en: 'Fine Dining', tc: '高級餐廳'),
    KeywordOption(en: 'Casual Dining', tc: '休閒餐廳'),
    KeywordOption(en: 'Fast Casual', tc: '快餐店'),
    KeywordOption(en: 'Cafe', tc: '咖啡廳'),
    KeywordOption(en: 'Bistro', tc: '小酒館'),
    KeywordOption(en: 'Buffet', tc: '自助餐'),
    KeywordOption(en: 'Food Court', tc: '美食廣場'),
    KeywordOption(en: 'Takeaway', tc: '外賣'),
    KeywordOption(en: 'Delivery', tc: '送餐'),

    // Meal types
    KeywordOption(en: 'Breakfast', tc: '早餐'),
    KeywordOption(en: 'Brunch', tc: '早午餐'),
    KeywordOption(en: 'Lunch', tc: '午餐'),
    KeywordOption(en: 'Dinner', tc: '晚餐'),
    KeywordOption(en: 'All-Day Dining', tc: '全日餐飲'),

    // Dietary features
    KeywordOption(en: 'Gluten-Free', tc: '無麩質'),
    KeywordOption(en: 'Soy-Free', tc: '無大豆'),
    KeywordOption(en: 'Nut-Free', tc: '無堅果'),
    KeywordOption(en: 'Sugar-Free', tc: '無糖'),
    KeywordOption(en: 'Oil-Free', tc: '無油'),
    KeywordOption(en: 'Low-Carb', tc: '低碳水'),
    KeywordOption(en: 'High-Protein', tc: '高蛋白'),
    KeywordOption(en: 'Keto-Friendly', tc: '生酮友善'),

    // Specialty items
    KeywordOption(en: 'Smoothie Bowls', tc: '冰沙碗'),
    KeywordOption(en: 'Juices', tc: '果汁'),
    KeywordOption(en: 'Coffee', tc: '咖啡'),
    KeywordOption(en: 'Tea', tc: '茶'),
    KeywordOption(en: 'Desserts', tc: '甜品'),
    KeywordOption(en: 'Bakery', tc: '麵包店'),
    KeywordOption(en: 'Noodles', tc: '麵食'),
    KeywordOption(en: 'Rice Bowls', tc: '飯類'),
    KeywordOption(en: 'Salads', tc: '沙律'),
    KeywordOption(en: 'Soups', tc: '湯類'),
    KeywordOption(en: 'Burgers', tc: '漢堡'),
    KeywordOption(en: 'Pizza', tc: '披薩'),
    KeywordOption(en: 'Pasta', tc: '意粉'),
    KeywordOption(en: 'Tacos', tc: '墨西哥捲餅'),
    KeywordOption(en: 'Sushi', tc: '壽司'),
    KeywordOption(en: 'Ramen', tc: '拉麵'),
    KeywordOption(en: 'Dumplings', tc: '餃子'),
    KeywordOption(en: 'Dim Sum', tc: '點心'),
    KeywordOption(en: 'Hot Pot', tc: '火鍋'),

    // Ambiance/features
    KeywordOption(en: 'Pet-Friendly', tc: '寵物友善'),
    KeywordOption(en: 'Kid-Friendly', tc: '兒童友善'),
    KeywordOption(en: 'Romantic', tc: '浪漫'),
    KeywordOption(en: 'Business', tc: '商務'),
    KeywordOption(en: 'Casual', tc: '休閒'),
    KeywordOption(en: 'Cozy', tc: '舒適'),
    KeywordOption(en: 'Modern', tc: '現代'),
    KeywordOption(en: 'Traditional', tc: '傳統'),
    KeywordOption(en: 'Rooftop', tc: '天台'),
    KeywordOption(en: 'Waterfront', tc: '海濱'),
    KeywordOption(en: 'Garden', tc: '花園'),
    KeywordOption(en: 'Outdoor Seating', tc: '戶外座位'),
    KeywordOption(en: 'Private Room', tc: '私人房間'),
    KeywordOption(en: 'Bar', tc: '酒吧'),
    KeywordOption(en: 'Live Music', tc: '現場音樂'),
    KeywordOption(en: 'Wi-Fi', tc: 'Wi-Fi'),
    KeywordOption(en: 'Air-Conditioned', tc: '室內冷氣'),
  ];

  /// Find keyword by English name (case-insensitive)
  static KeywordOption? findByEn(String en) {
    try {
      return all.firstWhere(
        (k) => k.en.toLowerCase() == en.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Find keyword by Traditional Chinese name
  static KeywordOption? findByTc(String tc) {
    try {
      return all.firstWhere((k) => k.tc == tc);
    } catch (_) {
      return null;
    }
  }

  /// Get all keyword names in English
  static List<String> getAllEnglish() => all.map((k) => k.en).toList();

  /// Get all keyword names in Traditional Chinese
  static List<String> getAllChinese() => all.map((k) => k.tc).toList();

  /// Get keyword names based on language preference
  static List<String> getAllNames(bool isTraditionalChinese) =>
      isTraditionalChinese ? getAllChinese() : getAllEnglish();
}
