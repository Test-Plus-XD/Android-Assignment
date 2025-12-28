import 'package:flutter/material.dart';

/// Contact Info Card Widget
///
/// Displays restaurant contact information (phone, email, website) in a card format.
/// Each contact method is tappable and triggers the corresponding action callback.
class ContactInfoCard extends StatelessWidget {
  final Map<String, dynamic> contacts;
  final bool isTraditionalChinese;
  final Function(String) onPhoneCall;
  final Function(String) onSendEmail;
  final Function(String) onOpenWebsite;

  const ContactInfoCard({
    required this.contacts,
    required this.isTraditionalChinese,
    required this.onPhoneCall,
    required this.onSendEmail,
    required this.onOpenWebsite,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (contacts['Phone'] != null && contacts['Phone'].toString().isNotEmpty)
              _buildContactRow(context, Icons.phone_outlined, contacts['Phone'], () => onPhoneCall(contacts['Phone'])),
            if (contacts['Email'] != null && contacts['Email'].toString().isNotEmpty)
              _buildContactRow(context, Icons.email_outlined, contacts['Email'], () => onSendEmail(contacts['Email'])),
            if (contacts['Website'] != null && contacts['Website'].toString().isNotEmpty)
              _buildContactRow(context, Icons.language_outlined, isTraditionalChinese ? '網站' : 'Website', () => onOpenWebsite(contacts['Website'])),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.primary))),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
