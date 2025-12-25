/// Hong Kong District Constants
///
/// This file contains all 18 districts of Hong Kong with bilingual names.

class DistrictOption {
  final String en;
  final String tc;

  const DistrictOption({
    required this.en,
    required this.tc,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistrictOption &&
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

class HKDistricts {
  /// All 18 Hong Kong districts in the same order as Angular project
  static const List<DistrictOption> all = [
    DistrictOption(en: 'Islands', tc: '離島'),
    DistrictOption(en: 'Kwai Tsing', tc: '葵青'),
    DistrictOption(en: 'North', tc: '北區'),
    DistrictOption(en: 'Sai Kung', tc: '西貢'),
    DistrictOption(en: 'Sha Tin', tc: '沙田'),
    DistrictOption(en: 'Tai Po', tc: '大埔'),
    DistrictOption(en: 'Tsuen Wan', tc: '荃灣'),
    DistrictOption(en: 'Tuen Mun', tc: '屯門'),
    DistrictOption(en: 'Yuen Long', tc: '元朗'),
    DistrictOption(en: 'Kowloon City', tc: '九龍城'),
    DistrictOption(en: 'Kwun Tong', tc: '觀塘'),
    DistrictOption(en: 'Sham Shui Po', tc: '深水埗'),
    DistrictOption(en: 'Wong Tai Sin', tc: '黃大仙'),
    DistrictOption(en: 'Yau Tsim Mong', tc: '油尖旺區'),
    DistrictOption(en: 'Central/Western', tc: '中西區'),
    DistrictOption(en: 'Eastern', tc: '東區'),
    DistrictOption(en: 'Southern', tc: '南區'),
    DistrictOption(en: 'Wan Chai', tc: '灣仔'),
  ];

  /// Find district by English name (case-insensitive)
  static DistrictOption? findByEn(String en) {
    try {
      return all.firstWhere(
        (d) => d.en.toLowerCase() == en.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Find district by Traditional Chinese name
  static DistrictOption? findByTc(String tc) {
    try {
      return all.firstWhere((d) => d.tc == tc);
    } catch (_) {
      return null;
    }
  }

  /// Get all district names in English
  static List<String> getAllEnglish() => all.map((d) => d.en).toList();

  /// Get all district names in Traditional Chinese
  static List<String> getAllChinese() => all.map((d) => d.tc).toList();

  /// Get district names based on language preference
  static List<String> getAllNames(bool isTraditionalChinese) =>
      isTraditionalChinese ? getAllChinese() : getAllEnglish();
}
