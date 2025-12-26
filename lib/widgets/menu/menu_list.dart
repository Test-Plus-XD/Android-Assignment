import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models.dart';
import '../../services/menu_service.dart';
import '../../config/app_state.dart';
import 'menu_item_card.dart';

/// Widget displaying a list of menu items grouped by category
///
/// Features:
/// - Groups menu items by category
/// - Pull-to-refresh support
/// - Empty state with helpful message
/// - Loading and error states
/// - Optional edit/delete actions for restaurant owners
class MenuList extends StatefulWidget {
  final String restaurantId;
  final bool showActions;
  final Function(MenuItem)? onEdit;
  final Function(MenuItem)? onDelete;

  const MenuList({
    super.key,
    required this.restaurantId,
    this.showActions = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<MenuList> createState() => _MenuListState();
}

class _MenuListState extends State<MenuList> {
  @override
  void initState() {
    super.initState();
    // Load menu items on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMenuItems();
    });
  }

  Future<void> _loadMenuItems() async {
    final menuService = context.read<MenuService>();
    await menuService.getMenuItems(widget.restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    final menuService = context.watch<MenuService>();
    final appState = context.watch<AppState>();
    final isTC = appState.isTraditionalChinese;
    final theme = Theme.of(context);

    // Get menu items for this specific restaurant using restaurant-specific getters
    // This prevents state clashes when multiple pages load different restaurant menus
    // (e.g., RestaurantDetailPage showing one restaurant while StoreDashboardPage shows another)
    final menuItems = menuService.getMenuItemsForRestaurant(widget.restaurantId);
    final isLoading = menuService.isLoadingForRestaurant(widget.restaurantId);
    final error = menuService.getErrorForRestaurant(widget.restaurantId);

    // Loading state
    if (isLoading && menuItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (error != null && menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              isTC ? '載入菜單時發生錯誤' : 'Error loading menu',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMenuItems,
              icon: const Icon(Icons.refresh),
              label: Text(isTC ? '重試' : 'Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              isTC ? '暫無菜單項目' : 'No menu items',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isTC ? '此餐廳尚未添加菜單' : 'This restaurant has not added a menu yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group menu items by category
    final groupedItems = menuService.getMenuItemsByCategory(widget.restaurantId);
    final categories = groupedItems.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadMenuItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final items = groupedItems[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Padding(
                padding: EdgeInsets.only(bottom: 12, top: index > 0 ? 16 : 0),
                child: Text(
                  category,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              // Menu items in this category
              ...items.map((item) => MenuItemCard(
                    item: item,
                    showActions: widget.showActions,
                    onEdit: widget.onEdit != null ? () => widget.onEdit!(item) : null,
                    onDelete: widget.onDelete != null ? () => widget.onDelete!(item) : null,
                  )),
            ],
          );
        },
      ),
    );
  }
}
