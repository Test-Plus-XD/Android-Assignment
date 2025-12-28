import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

/// Account Type Selector Dialog
///
/// Full-screen dialog shown to new users to select their account type.
/// This is mandatory - users cannot proceed without selecting a type.
class AccountTypeSelectorDialog extends StatefulWidget {
  final bool isTraditionalChinese;
  final VoidCallback onComplete;

  const AccountTypeSelectorDialog({
    super.key,
    required this.isTraditionalChinese,
    required this.onComplete,
  });

  @override
  State<AccountTypeSelectorDialog> createState() => _AccountTypeSelectorDialogState();
}

class _AccountTypeSelectorDialogState extends State<AccountTypeSelectorDialog> {
  String? _selectedType;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTC = widget.isTraditionalChinese;

    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // Welcome icon
                Icon(
                  Icons.waving_hand,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  isTC ? '歡迎加入 PourRice!' : 'Welcome to PourRice!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  isTC
                      ? '請選擇您的帳戶類型以完成設定'
                      : 'Please select your account type to complete setup',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Diner option
                _buildTypeOption(
                  context: context,
                  type: 'Diner',
                  icon: Icons.person,
                  title: isTC ? '食客' : 'Diner',
                  description: isTC
                      ? '瀏覽餐廳、預訂座位、撰寫評論'
                      : 'Browse restaurants, make bookings, write reviews',
                ),
                const SizedBox(height: 16),

                // Restaurant option
                _buildTypeOption(
                  context: context,
                  type: 'Restaurant',
                  icon: Icons.store,
                  title: isTC ? '餐廳老闆' : 'Restaurant Owner',
                  description: isTC
                      ? '管理您的餐廳、菜單和預訂'
                      : 'Manage your restaurant, menu, and bookings',
                ),

                const Spacer(),

                // Continue button
                FilledButton(
                  onPressed: _selectedType == null || _isSaving
                      ? null
                      : _saveAccountType,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isTC ? '繼續' : 'Continue',
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required BuildContext context,
    required String type,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: type,
              groupValue: _selectedType,
              onChanged: (value) => setState(() => _selectedType = value),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAccountType() async {
    if (_selectedType == null) return;

    setState(() => _isSaving = true);

    try {
      final authService = context.read<AuthService>();
      final userService = context.read<UserService>();
      final uid = authService.uid;

      if (uid == null) {
        setState(() => _isSaving = false);
        return;
      }

      final success = await userService.updateUserProfile(uid, {
        'type': _selectedType,
      });

      if (success && mounted) {
        widget.onComplete();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese
                  ? '儲存失敗，請重試'
                  : 'Failed to save. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
