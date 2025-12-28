import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/store_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../common/loading_indicator.dart';

/// Claim Restaurant Button
///
/// Displays for Restaurant-type users who don't have a linked restaurant.
/// Allows them to claim ownership of an unclaimed restaurant.
class ClaimRestaurantButton extends StatefulWidget {
  final String restaurantId;
  final String? restaurantOwnerId;
  final bool isTraditionalChinese;
  final VoidCallback onClaimed;

  const ClaimRestaurantButton({
    required this.restaurantId,
    required this.restaurantOwnerId,
    required this.isTraditionalChinese,
    required this.onClaimed,
    super.key,
  });

  @override
  State<ClaimRestaurantButton> createState() => _ClaimRestaurantButtonState();
}

class _ClaimRestaurantButtonState extends State<ClaimRestaurantButton> {
  bool _isClaiming = false;

  Future<void> _claimRestaurant() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.isTraditionalChinese ? '認領餐廳' : 'Claim Restaurant',
        ),
        content: Text(
          widget.isTraditionalChinese
              ? '確定要認領這間餐廳嗎？認領後您將成為此餐廳的擁有者，可以管理菜單、預訂和資訊。'
              : 'Are you sure you want to claim this restaurant? Once claimed, you will become the owner and can manage the menu, bookings, and information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.isTraditionalChinese ? '認領' : 'Claim'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isClaiming = true);

    try {
      final storeService = context.read<StoreService>();
      final userService = context.read<UserService>();
      final success = await storeService.claimRestaurant(widget.restaurantId);

      if (!mounted) return;

      if (success) {
        // Refresh user profile to get the updated restaurantId
        final authService = context.read<AuthService>();
        if (authService.uid != null) {
          await userService.getUserProfile(authService.uid!);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese
                  ? '成功認領餐廳！'
                  : 'Restaurant claimed successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Callback to refresh parent
        widget.onClaimed();
      } else {
        throw Exception(storeService.error ?? 'Failed to claim restaurant');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTraditionalChinese
                ? '認領失敗：$e'
                : 'Claim failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userService = context.watch<UserService>();
    
    // User data
    final userProfile = userService.currentProfile;
    final userType = userProfile?.type;
    final userRestaurantId = userProfile?.restaurantId;

    // Check if user is eligible to claim (Must be 'Restaurant' type and have no restaurantId)
    final isUserEligible = userType == 'Restaurant' && (userRestaurantId == null || userRestaurantId.isEmpty);
    
    // Check if restaurant is unclaimed (Must have no ownerId)
    final isRestaurantUnclaimed = widget.restaurantOwnerId == null || widget.restaurantOwnerId!.isEmpty;

    // Only show button if:
    // 1. User is logged in
    // 2. User is eligible (Restaurant type + no restaurantId)
    // 3. This restaurant is unclaimed (no ownerId)
    if (!authService.isLoggedIn || !isUserEligible || !isRestaurantUnclaimed) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.store,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              widget.isTraditionalChinese ? '這是您的餐廳嗎？' : 'Is this your restaurant?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.isTraditionalChinese
                  ? '認領此餐廳以管理菜單、預訂和資訊'
                  : 'Claim this restaurant to manage menu, bookings, and info',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isClaiming ? null : _claimRestaurant,
                icon: _isClaiming
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: LoadingIndicator.extraSmall(),
                      )
                    : const Icon(Icons.verified),
                label: Text(
                  widget.isTraditionalChinese ? '認領餐廳' : 'Claim Restaurant',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
