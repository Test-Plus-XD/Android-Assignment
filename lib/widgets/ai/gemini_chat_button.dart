import 'package:flutter/material.dart';
import '../../pages/gemini_page.dart';

/// Floating action button for AI chat
///
/// A colorful, animated button that opens the Gemini AI chat interface.
/// Can be used standalone or integrated into other pages.
class GeminiChatButton extends StatefulWidget {
  final bool isTraditionalChinese;
  final String? restaurantName;
  final String? restaurantCuisine;
  final String? restaurantDistrict;

  const GeminiChatButton({
    required this.isTraditionalChinese,
    this.restaurantName,
    this.restaurantCuisine,
    this.restaurantDistrict,
    super.key,
  });

  @override
  State<GeminiChatButton> createState() => _GeminiChatButtonState();
}

class _GeminiChatButtonState extends State<GeminiChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GeminiChatRoomPage(
          isTraditionalChinese: widget.isTraditionalChinese,
          restaurantName: widget.restaurantName,
          restaurantCuisine: widget.restaurantCuisine,
          restaurantDistrict: widget.restaurantDistrict,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isTraditionalChinese ? 'AI 助手' : 'AI Assistant';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: _openChat,
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade400,
                Colors.blue.shade400,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 20,
          ),
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 4,
      ),
    );
  }
}

/// Compact icon button version for toolbars
class GeminiChatIconButton extends StatelessWidget {
  final bool isTraditionalChinese;
  final String? restaurantName;
  final String? restaurantCuisine;
  final String? restaurantDistrict;
  final String? restaurantId; // For menu context

  const GeminiChatIconButton({
    required this.isTraditionalChinese,
    this.restaurantName,
    this.restaurantCuisine,
    this.restaurantDistrict,
    this.restaurantId, // Optional restaurant ID
    super.key,
  });

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GeminiChatRoomPage(
          isTraditionalChinese: isTraditionalChinese,
          restaurantName: restaurantName,
          restaurantCuisine: restaurantCuisine,
          restaurantDistrict: restaurantDistrict,
          restaurantId: restaurantId, // Pass restaurant ID for menu
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _openChat(context),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade400,
              Colors.blue.shade400,
            ],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: 20,
        ),
      ),
      tooltip: isTraditionalChinese ? 'AI 助手' : 'AI Assistant',
    );
  }
}
