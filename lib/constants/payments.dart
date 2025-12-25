/// Payment Method Constants
///
/// This file contains all accepted payment methods with bilingual names.

class PaymentOption {
  final String en;
  final String tc;
  final String icon; // Material icon name or emoji

  const PaymentOption({
    required this.en,
    required this.tc,
    required this.icon,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentOption &&
          runtimeType == other.runtimeType &&
          en == other.en &&
          tc == other.tc;

  @override
  int get hashCode => en.hashCode ^ tc.hashCode;

  @override
  String toString() => en;

  String getName(bool isTraditionalChinese) =>
      isTraditionalChinese ? tc : en;
}

class PaymentMethods {
  /// All payment methods matching Angular project
  static const List<PaymentOption> all = [
    PaymentOption(
      en: 'Cash',
      tc: '現金',
      icon: '💵',
    ),
    PaymentOption(
      en: 'Credit Card',
      tc: '信用卡',
      icon: '💳',
    ),
    PaymentOption(
      en: 'Debit Card',
      tc: '扣賬卡',
      icon: '💳',
    ),
    PaymentOption(
      en: 'Octopus',
      tc: '八達通',
      icon: '🐙',
    ),
    PaymentOption(
      en: 'AliPay HK',
      tc: '支付寶香港',
      icon: '📱',
    ),
    PaymentOption(
      en: 'WeChat Pay HK',
      tc: '微信支付香港',
      icon: '💬',
    ),
    PaymentOption(
      en: 'PayMe',
      tc: 'PayMe',
      icon: '📱',
    ),
    PaymentOption(
      en: 'FPS',
      tc: '轉數快',
      icon: '⚡',
    ),
    PaymentOption(
      en: 'Apple Pay',
      tc: 'Apple Pay',
      icon: '',
    ),
    PaymentOption(
      en: 'Google Pay',
      tc: 'Google Pay',
      icon: '',
    ),
  ];

  /// Find payment method by English name (case-insensitive)
  static PaymentOption? findByEn(String en) {
    try {
      return all.firstWhere(
        (p) => p.en.toLowerCase() == en.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Find payment method by Traditional Chinese name
  static PaymentOption? findByTc(String tc) {
    try {
      return all.firstWhere((p) => p.tc == tc);
    } catch (_) {
      return null;
    }
  }

  /// Get all payment method names in English
  static List<String> getAllEnglish() => all.map((p) => p.en).toList();

  /// Get all payment method names in Traditional Chinese
  static List<String> getAllChinese() => all.map((p) => p.tc).toList();

  /// Get payment method names based on language preference
  static List<String> getAllNames(bool isTraditionalChinese) =>
      isTraditionalChinese ? getAllChinese() : getAllEnglish();
}
