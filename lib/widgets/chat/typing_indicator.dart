import 'package:flutter/material.dart';

/// Typing Indicator Widget
///
/// Shows animated dots when users are typing
class TypingIndicatorWidget extends StatefulWidget {
  final String displayName;
  final bool isTraditionalChinese;

  const TypingIndicatorWidget({
    super.key,
    required this.displayName,
    this.isTraditionalChinese = false,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
            child: Text(
              widget.displayName.isNotEmpty ? widget.displayName[0].toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Typing bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated dots
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        final delay = index * 0.2;
                        final value = (_controller.value - delay) % 1.0;
                        final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.3 + opacity * 0.7),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),

                const SizedBox(width: 8),

                // Text
                Text(
                  widget.isTraditionalChinese ? '正在輸入...' : 'typing...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
