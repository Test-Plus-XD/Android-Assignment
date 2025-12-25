import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/menu_service.dart';
import '../models.dart';
import '../widgets/menu/menu_list.dart';
import '../widgets/menu/menu_item_form.dart';

/// Menu Page
///
/// Full-screen page for viewing restaurant menu items.
/// Restaurant owners can add, edit, and delete menu items.
/// Regular users see a read-only view of the menu.
class RestaurantMenuPage extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final bool isTraditionalChinese;

  const RestaurantMenuPage({
    required this.restaurantId,
    required this.restaurantName,
    required this.isTraditionalChinese,
    super.key,
  });

  /// Handle menu item edit
  ///
  /// Opens a bottom sheet with the menu item form pre-filled with existing data.
  void _handleEdit(BuildContext context, MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuItemForm(
        restaurantId: restaurantId,
        menuItem: item,
      ),
    );
  }

  /// Handle menu item delete
  ///
  /// Shows a confirmation dialog before deleting the menu item.
  Future<void> _handleDelete(BuildContext context, MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isTraditionalChinese ? '確認刪除' : 'Confirm Delete',
        ),
        content: Text(
          isTraditionalChinese
              ? '確定要刪除 "${item.getDisplayName(isTraditionalChinese)}" 嗎？'
              : 'Are you sure you want to delete "${item.getDisplayName(isTraditionalChinese)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(isTraditionalChinese ? '刪除' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final menuService = context.read<MenuService>();
        await menuService.deleteMenuItem(restaurantId, item.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isTraditionalChinese ? '已刪除菜單項目' : 'Menu item deleted',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show add menu item form
  ///
  /// Opens a bottom sheet with an empty menu item form.
  void _showAddItemForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuItemForm(
        restaurantId: restaurantId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Implement owner check based on user type
    // For now, owners can be identified by checking user.type field
    // final authService = context.watch<AuthService>();
    // final isOwner = authService.currentUser?.type == 'owner';
    final isOwner = false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTraditionalChinese ? '菜單' : 'Menu',
        ),
      ),
      body: MenuList(
        restaurantId: restaurantId,
        showActions: isOwner,
        onEdit: isOwner ? (item) => _handleEdit(context, item) : null,
        onDelete: isOwner ? (item) => _handleDelete(context, item) : null,
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _showAddItemForm(context),
              icon: const Icon(Icons.add),
              label: Text(
                isTraditionalChinese ? '新增項目' : 'Add Item',
              ),
            )
          : null,
    );
  }
}
