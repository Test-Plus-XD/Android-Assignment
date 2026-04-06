import 'package:flutter/material.dart';
import 'skeleton_box.dart';

/// Skeleton for a single chat-room list item (mirrors [ChatRoomListItem]).
/// Layout: circular avatar | two text lines | timestamp (right).
class ChatRoomItemSkeleton extends StatelessWidget {
  const ChatRoomItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Avatar circle
          const SkeletonBox(width: 48, height: 48, borderRadius: 24),
          const SizedBox(width: 12),
          // Room name + last message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 140, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                SkeletonBox(width: 200, height: 12, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Timestamp
          const SkeletonBox(width: 40, height: 10, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Shows [count] [ChatRoomItemSkeleton] items wrapped in a
/// [SkeletonWithLoader] (shimmer + Eclipse.gif).
class ChatRoomListSkeleton extends StatelessWidget {
  const ChatRoomListSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonWithLoader(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (_) => const ChatRoomItemSkeleton()),
      ),
    );
  }
}
