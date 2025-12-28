import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/menu_service.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../models.dart';
import '../config.dart';
import '../widgets/menu/menu_item_dialog.dart';
import '../widgets/menu/bulk_import_review_dialog.dart';

/// Store Menu Management Page
///
/// Allows restaurant owners to manage their menu items:
/// - View all menu items
/// - Add new menu items
/// - Edit existing menu items
/// - Delete menu items
class StoreMenuManagePage extends StatefulWidget {
  final String restaurantId;
  final bool isTraditionalChinese;

  const StoreMenuManagePage({
    required this.restaurantId,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<StoreMenuManagePage> createState() => _StoreMenuManagePageState();
}

class _StoreMenuManagePageState extends State<StoreMenuManagePage> {
  Future<List<MenuItem>>? _menuItemsFuture;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  void _loadMenuItems() {
    setState(() {
      // Always fetch fresh menu items (forceRefresh: true)
      _menuItemsFuture = context.read<MenuService>().getMenuItems(widget.restaurantId, forceRefresh: true);
    });
  }

  Future<void> _refreshMenuItems() async {
    _loadMenuItems();
  }

  Future<void> _bulkImportMenu() async {
    // Show dialog to choose file source
    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '選擇文件來源' : 'Select File Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(widget.isTraditionalChinese ? '從相冊選擇圖片' : 'Select Image from Gallery'),
              onTap: () => Navigator.of(context).pop('image'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(widget.isTraditionalChinese ? '拍攝照片' : 'Take Photo'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.file_present),
              title: Text(widget.isTraditionalChinese ? '選擇文件(PDF/JSON/文本)' : 'Select File (PDF/JSON/Text)'),
              onTap: () => Navigator.of(context).pop('file'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      List<int>? fileBytes;
      String? fileName;

      if (source == 'image' || source == 'camera') {
        // Use ImagePicker for images
        final imageService = context.read<ImageService>();
        final imageFile = await imageService.pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );

        if (imageFile == null) return;

        fileBytes = await imageFile.readAsBytes();
        fileName = imageFile.path.split('/').last;
      } else {
        // Use FilePicker for documents
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'txt', 'json'],
        );

        if (result == null || result.files.isEmpty) return;

        final file = result.files.first;
        if (file.bytes == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isTraditionalChinese ? '無法讀取文件' : 'Could not read file'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        fileBytes = file.bytes;
        fileName = file.name;
      }

      setState(() => _isImporting = true);

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                widget.isTraditionalChinese ? '正在處理菜單文件...' : 'Processing menu file...',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Get auth token
      final authService = context.read<AuthService>();
      final token = await authService.getIdToken(forceRefresh: true);

      if (token == null) {
        throw Exception(widget.isTraditionalChinese ? '未經授權' : 'Unauthorized');
      }

      // Upload to DocuPipe extract-menu endpoint
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/API/DocuPipe/extract-menu'),
      );

      request.headers.addAll({
        'x-api-passcode': AppConfig.apiPasscode,
        'Authorization': 'Bearer $token',
      });

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes!,
        filename: fileName!,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final menuItems = data['menu_items'] as List?;

        if (menuItems == null || menuItems.isEmpty) {
          throw Exception(widget.isTraditionalChinese ? '未找到菜單項目' : 'No menu items found');
        }

        // Show confirmation dialog with extracted items
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => BulkImportReviewDialog(
            menuItems: menuItems,
            isTraditionalChinese: widget.isTraditionalChinese,
          ),
        );

        if (confirmed == true) {
          // Save all menu items
          await _saveBulkMenuItems(menuItems);
        }
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      if (!mounted) return;

      // Try to close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTraditionalChinese ? '導入失敗：$e' : 'Import failed: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _saveBulkMenuItems(List<dynamic> menuItems) async {
    try {
      final menuService = context.read<MenuService>();
      int successCount = 0;
      int failCount = 0;

      // Show progress dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                widget.isTraditionalChinese
                    ? '正在儲存 ${menuItems.length} 個菜單項目...'
                    : 'Saving ${menuItems.length} menu items...',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      for (final item in menuItems) {
        try {
          final request = CreateMenuItemRequest(
            nameEn: item['Name_EN'] ?? item['nameEn'],
            nameTc: item['Name_TC'] ?? item['nameTc'],
            descriptionEn: item['Description_EN'] ?? item['descriptionEn'],
            descriptionTc: item['Description_TC'] ?? item['descriptionTc'],
            price: item['price'] != null ? (item['price'] as num).toDouble() : null,
            category: item['category'],
            image: item['image'],
          );

          await menuService.createMenuItem(widget.restaurantId, request);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      if (!mounted) return;

      // Close progress dialog
      Navigator.of(context).pop();

      // Show result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTraditionalChinese
                ? '成功導入 $successCount 個項目${failCount > 0 ? '，$failCount 個失敗' : ''}'
                : 'Successfully imported $successCount items${failCount > 0 ? ', $failCount failed' : ''}',
          ),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );

      // Reload menu
      _loadMenuItems();
    } catch (e) {
      if (!mounted) return;

      // Try to close progress dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isTraditionalChinese ? '儲存失敗：$e' : 'Save failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addMenuItem() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MenuItemDialog(
        restaurantId: widget.restaurantId,
        isTraditionalChinese: widget.isTraditionalChinese,
      ),
    );

    if (result == true) {
      _loadMenuItems();
    }
  }

  Future<void> _editMenuItem(MenuItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MenuItemDialog(
        restaurantId: widget.restaurantId,
        isTraditionalChinese: widget.isTraditionalChinese,
        menuItem: item,
      ),
    );

    if (result == true) {
      _loadMenuItems();
    }
  }

  Future<void> _deleteMenuItem(MenuItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '確認刪除' : 'Confirm Delete'),
        content: Text(
          widget.isTraditionalChinese
              ? '確定要刪除「${item.nameTc ?? item.nameEn ?? ''}」嗎？'
              : 'Are you sure you want to delete "${item.nameEn ?? item.nameTc ?? ''}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(widget.isTraditionalChinese ? '刪除' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final menuService = context.read<MenuService>();
      await menuService.deleteMenuItem(widget.restaurantId, item.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isTraditionalChinese ? '刪除成功' : 'Deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadMenuItems();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isTraditionalChinese ? '刪除失敗：$e' : 'Delete failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTraditionalChinese ? '管理菜單' : 'Manage Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMenuItems,
            tooltip: widget.isTraditionalChinese ? '重新整理' : 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<MenuItem>>(
        future: _menuItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    widget.isTraditionalChinese ? '載入失敗' : 'Failed to load',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshMenuItems,
                    icon: const Icon(Icons.refresh),
                    label: Text(widget.isTraditionalChinese ? '重試' : 'Retry'),
                  ),
                ],
              ),
            );
          }

          final menuItems = snapshot.data ?? [];

          if (menuItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    widget.isTraditionalChinese ? '尚無菜單項目' : 'No menu items yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isTraditionalChinese ? '點擊下方按鈕新增' : 'Tap below to add one',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshMenuItems,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final name = widget.isTraditionalChinese
                    ? (item.nameTc ?? item.nameEn ?? '')
                    : (item.nameEn ?? item.nameTc ?? '');
                final description = widget.isTraditionalChinese
                    ? (item.descriptionTc ?? item.descriptionEn ?? '')
                    : (item.descriptionEn ?? item.descriptionTc ?? '');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12.0),
                    leading: item.image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.image!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.restaurant),
                              ),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.restaurant),
                          ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        if (item.price != null)
                          Text(
                            '\$${item.price!.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editMenuItem(item);
                        } else if (value == 'delete') {
                          _deleteMenuItem(item);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit),
                              const SizedBox(width: 8),
                              Text(widget.isTraditionalChinese ? '編輯' : 'Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                widget.isTraditionalChinese ? '刪除' : 'Delete',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bulk Import FAB
          FloatingActionButton.extended(
            heroTag: 'bulk_import',
            onPressed: _isImporting ? null : _bulkImportMenu,
            icon: const Icon(Icons.upload_file),
            label: Text(widget.isTraditionalChinese ? '批量導入' : 'Bulk Import'),
            backgroundColor: _isImporting
                ? Colors.grey
                : Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 12),
          // Add Item FAB
          FloatingActionButton.extended(
            heroTag: 'add_item',
            onPressed: _addMenuItem,
            icon: const Icon(Icons.add),
            label: Text(widget.isTraditionalChinese ? '新增項目' : 'Add Item'),
          ),
        ],
      ),
    );
  }
}