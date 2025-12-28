import 'package:flutter/material.dart';

/// Action Buttons Row Widget
///
/// Displays a row of action buttons for restaurant interactions:
/// - Call (phone)
/// - Chat (Socket.IO)
/// - AI Assistant (Gemini)
/// - Directions (Google Maps)
/// - Website
class ActionButtonsRow extends StatelessWidget {
  final bool isTraditionalChinese;
  final bool isLoggedIn;
  final String? phoneNumber;
  final String? website;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback onAI;
  final VoidCallback onDirections;
  final VoidCallback? onWebsite;

  const ActionButtonsRow({
    required this.isTraditionalChinese,
    required this.isLoggedIn,
    this.phoneNumber,
    this.website,
    this.onCall,
    this.onChat,
    required this.onAI,
    required this.onDirections,
    this.onWebsite,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.phone,
          label: isTraditionalChinese ? '電話' : 'Call',
          onTap: phoneNumber != null ? onCall : null,
        ),
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: isTraditionalChinese ? '對話' : 'Chat',
          onTap: onChat, // Always enabled, parent handles auth check with toast
        ),
        _ActionButton(
          icon: Icons.auto_awesome,
          label: 'AI',
          onTap: onAI,
        ),
        _ActionButton(
          icon: Icons.directions,
          label: isTraditionalChinese ? '導航' : 'Directions',
          onTap: onDirections,
        ),
        _ActionButton(
          icon: Icons.public,
          label: isTraditionalChinese ? '網頁' : 'Website',
          onTap: website != null ? onWebsite : null,
        ),
      ],
    );
  }
}

/// Helper Widget for Action Buttons
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              color: onTap != null ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: onTap != null ? Theme.of(context).colorScheme.primary : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
