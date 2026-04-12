import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/menu_service.dart';
import '../../models.dart';
import '../common/loading_indicator.dart';

/// Menu Item Dialog
///
/// Dialog for creating or editing a menu item.
/// Provides bilingual input fields for name and description,
/// plus a price field.
class MenuItemDialog extends StatefulWidget {
  final String restaurantId;
  final bool isTraditionalChinese;
  final MenuItem? menuItem;

  const MenuItemDialog({
    required this.restaurantId,
    required this.isTraditionalChinese,
    this.menuItem,
    super.key,
  });

  @override
  State<MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends State<MenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameEnController;
  late TextEditingController _nameTcController;
  late TextEditingController _descEnController;
  late TextEditingController _descTcController;
  late TextEditingController _priceController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: widget.menuItem?.nameEn ?? '');
    _nameTcController = TextEditingController(text: widget.menuItem?.nameTc ?? '');
    _descEnController = TextEditingController(text: widget.menuItem?.descriptionEn ?? '');
    _descTcController = TextEditingController(text: widget.menuItem?.descriptionTc ?? '');
    _priceController = TextEditingController(
      text: widget.menuItem?.price?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameTcController.dispose();
    _descEnController.dispose();
    _descTcController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final menuService = context.read<MenuService>();

      final nameEn = _nameEnController.text.trim().isEmpty ? null : _nameEnController.text.trim();
      final nameTc = _nameTcController.text.trim().isEmpty ? null : _nameTcController.text.trim();
      final descEn = _descEnController.text.trim().isEmpty ? null : _descEnController.text.trim();
      final descTc = _descTcController.text.trim().isEmpty ? null : _descTcController.text.trim();
      final price = _priceController.text.trim().isEmpty ? null : double.tryParse(_priceController.text.trim());

      if (widget.menuItem != null) {
        // Update existing item
        final request = UpdateMenuItemRequest(
          nameEn: nameEn,
          nameTc: nameTc,
          descriptionEn: descEn,
          descriptionTc: descTc,
          price: price,
        );
        await menuService.updateMenuItem(widget.restaurantId, widget.menuItem!.id, request);
      } else {
        // Create new item
        final request = CreateMenuItemRequest(
          nameEn: nameEn,
          nameTc: nameTc,
          descriptionEn: descEn,
          descriptionTc: descTc,
          price: price,
        );
        await menuService.createMenuItem(widget.restaurantId, request);
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isTraditionalChinese ? '儲存失敗：$e' : 'Save failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.menuItem != null;

    return AlertDialog(
      title: Text(
        isEdit
            ? (widget.isTraditionalChinese ? '編輯菜單項目' : 'Edit Menu Item')
            : (widget.isTraditionalChinese ? '新增菜單項目' : 'Add Menu Item'),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameEnController,
                decoration: InputDecoration(
                  labelText: widget.isTraditionalChinese ? '名稱（英文）' : 'Name (English)',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value?.trim().isEmpty ?? true) &&
                      _nameTcController.text.trim().isEmpty) {
                    return widget.isTraditionalChinese
                        ? '請至少輸入一個名稱'
                        : 'Please enter at least one name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameTcController,
                decoration: InputDecoration(
                  labelText: widget.isTraditionalChinese ? '名稱（中文）' : 'Name (Chinese)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descEnController,
                decoration: InputDecoration(
                  labelText: widget.isTraditionalChinese ? '描述（英文）' : 'Description (English)',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descTcController,
                decoration: InputDecoration(
                  labelText: widget.isTraditionalChinese ? '描述（中文）' : 'Description (Chinese)',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: widget.isTraditionalChinese ? '價格' : 'Price',
                  border: const OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: LoadingIndicator.small(),
                )
              : Text(widget.isTraditionalChinese ? '儲存' : 'Save'),
        ),
      ],
    );
  }
}
