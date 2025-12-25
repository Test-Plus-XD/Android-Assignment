import 'package:flutter/material.dart';

/// Contact Actions Widget
///
/// Displays contact methods as action buttons in a grid.
/// Features:
/// - Phone, email, website buttons
/// - Icon-based design for quick recognition
/// - Only shows available contact methods
class ContactActions extends StatelessWidget {
  final Map<String, dynamic>? contacts;
  final bool isTraditionalChinese;
  final Function(String) onPhonePressed;
  final Function(String) onEmailPressed;
  final Function(String) onWebsitePressed;

  const ContactActions({
    required this.contacts,
    required this.isTraditionalChinese,
    required this.onPhonePressed,
    required this.onEmailPressed,
    required this.onWebsitePressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (contacts == null || contacts!.isEmpty) {
      return const SizedBox.shrink();
    }

    final phone = contacts!['phone']?.toString();
    final email = contacts!['email']?.toString();
    final website = contacts!['website']?.toString();

    final List<Widget> contactButtons = [];

    if (phone != null && phone.trim().isNotEmpty) {
      contactButtons.add(
        _buildContactButton(
          context: context,
          icon: Icons.phone,
          label: isTraditionalChinese ? '電話' : 'Call',
          color: Colors.green,
          onPressed: () => onPhonePressed(phone),
        ),
      );
    }

    if (email != null && email.trim().isNotEmpty) {
      contactButtons.add(
        _buildContactButton(
          context: context,
          icon: Icons.email,
          label: isTraditionalChinese ? '電郵' : 'Email',
          color: Colors.blue,
          onPressed: () => onEmailPressed(email),
        ),
      );
    }

    if (website != null && website.trim().isNotEmpty) {
      contactButtons.add(
        _buildContactButton(
          context: context,
          icon: Icons.language,
          label: isTraditionalChinese ? '網站' : 'Website',
          color: Colors.orange,
          onPressed: () => onWebsitePressed(website),
        ),
      );
    }

    if (contactButtons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            isTraditionalChinese ? '聯絡方式' : 'Contact',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: contactButtons
                .map((btn) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: btn,
              ),
            ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
