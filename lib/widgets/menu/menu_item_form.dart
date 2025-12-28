import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models.dart';
import '../../services/menu_service.dart';
import '../../services/image_service.dart';
import '../../config/app_state.dart';
import '../images/image_picker_button.dart';
import '../images/image_preview.dart';
import '../images/upload_progress_indicator.dart';

/// Bottom sheet form for creating or editing menu items
///
/// Features:
/// - Bilingual input fields (EN/TC)
/// - Price input with validation
/// - Category selection
/// - Availability toggle
/// - Form validation
/// - Loading state during submission
class MenuItemForm extends StatefulWidget {
  final String restaurantId;
  final MenuItem? menuItem; // Null for create, populated for edit

  const MenuItemForm({
    super.key,
    required this.restaurantId,
    this.menuItem,
  });

  @override
  State<MenuItemForm> createState() => _MenuItemFormState();
}

class _MenuItemFormState extends State<MenuItemForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form fields
  late TextEditingController _nameEnController;
  late TextEditingController _nameTcController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _descriptionTcController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  late bool _available;
  File? _selectedImage;
  String? _uploadedImageUrl;

  // Common categories
  final List<String> _commonCategories = [
    'Appetizers',
    'Soups',
    'Salads',
    'Main Courses',
    'Noodles & Rice',
    'Desserts',
    'Beverages',
    'Special',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.menuItem;
    _nameEnController = TextEditingController(text: item?.nameEn ?? '');
    _nameTcController = TextEditingController(text: item?.nameTc ?? '');
    _descriptionEnController = TextEditingController(text: item?.descriptionEn ?? '');
    _descriptionTcController = TextEditingController(text: item?.descriptionTc ?? '');
    _priceController = TextEditingController(
      text: item?.price != null ? item!.price.toString() : '',
    );
    _categoryController = TextEditingController(text: item?.category ?? '');
    _available = item?.available ?? true;
    _uploadedImageUrl = item?.image;
  }

  void _onImageSelected(File image) {
    setState(() {
      _selectedImage = image;
      _uploadedImageUrl = null; // Clear existing URL when new image selected
    });
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameTcController.dispose();
    _descriptionEnController.dispose();
    _descriptionTcController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final appState = context.read<AppState>();
    final isTC = appState.isTraditionalChinese;
    final menuService = context.read<MenuService>();
    final imageService = context.read<ImageService>();

    try {
      final price = double.tryParse(_priceController.text);
      String? imageUrl = _uploadedImageUrl;

      // Upload image if one was selected
      if (_selectedImage != null) {
        imageUrl = (await imageService.uploadImage(
          imageFile: _selectedImage!,
          folder: 'Menu/${widget.restaurantId}',
          compress: true,
        )) as String?;

        if (imageUrl == null) {
          throw Exception(isTC ? '圖片上傳失敗' : 'Image upload failed');
        }
      }

      if (widget.menuItem == null) {
        // Create new menu item
        final request = CreateMenuItemRequest(
          nameEn: _nameEnController.text.trim(),
          nameTc: _nameTcController.text.trim(),
          descriptionEn: _descriptionEnController.text.trim(),
          descriptionTc: _descriptionTcController.text.trim(),
          price: price,
          category: _categoryController.text.trim(),
          image: imageUrl,
          available: _available,
        );

        await menuService.createMenuItem(widget.restaurantId, request);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isTC ? '菜單項目已建立' : 'Menu item created'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing menu item
        final request = UpdateMenuItemRequest(
          nameEn: _nameEnController.text.trim(),
          nameTc: _nameTcController.text.trim(),
          descriptionEn: _descriptionEnController.text.trim(),
          descriptionTc: _descriptionTcController.text.trim(),
          price: price,
          category: _categoryController.text.trim(),
          image: imageUrl,
          available: _available,
        );

        await menuService.updateMenuItem(
          widget.restaurantId,
          widget.menuItem!.id,
          request,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isTC ? '菜單項目已更新' : 'Menu item updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isTC = appState.isTraditionalChinese;
    final theme = Theme.of(context);
    final isEdit = widget.menuItem != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit
                          ? (isTC ? '編輯菜單項目' : 'Edit Menu Item')
                          : (isTC ? '新增菜單項目' : 'Add Menu Item'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Name (English)
                      TextFormField(
                        controller: _nameEnController,
                        decoration: InputDecoration(
                          labelText: isTC ? '名稱 (英文)' : 'Name (English)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.restaurant_menu),
                        ),
                        validator: (value) {
                          if ((value == null || value.trim().isEmpty) &&
                              _nameTcController.text.trim().isEmpty) {
                            return isTC ? '請輸入英文或中文名稱' : 'Enter name in English or Chinese';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Name (Traditional Chinese)
                      TextFormField(
                        controller: _nameTcController,
                        decoration: InputDecoration(
                          labelText: isTC ? '名稱 (繁體中文)' : 'Name (Traditional Chinese)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.restaurant_menu),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description (English)
                      TextFormField(
                        controller: _descriptionEnController,
                        decoration: InputDecoration(
                          labelText: isTC ? '描述 (英文)' : 'Description (English)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 16),

                      // Description (Traditional Chinese)
                      TextFormField(
                        controller: _descriptionTcController,
                        decoration: InputDecoration(
                          labelText: isTC ? '描述 (繁體中文)' : 'Description (Traditional Chinese)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 16),

                      // Price
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: isTC ? '價格 (HK\$)' : 'Price (HK\$)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final price = double.tryParse(value);
                            if (price == null || price < 0) {
                              return isTC ? '請輸入有效價格' : 'Enter valid price';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Category (with dropdown)
                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: _categoryController.text),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return _commonCategories;
                          }
                          return _commonCategories.where((String option) {
                            return option
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) {
                          _categoryController.text = selection;
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          _categoryController.text = controller.text;
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: isTC ? '類別' : 'Category',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.category),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Image upload section
                      Text(
                        isTC ? '圖片（選填）' : 'Image (Optional)',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_selectedImage != null || _uploadedImageUrl != null) ...[
                        WideImagePreview(
                          image: _selectedImage ?? _uploadedImageUrl!,
                          aspectRatio: 16 / 9,
                          showRemoveButton: true,
                          onRemove: _removeImage,
                        ),
                        const SizedBox(height: 8),
                      ] else ...[
                        ImagePickerButton(
                          onImageSelected: _onImageSelected,
                          label: isTC ? '選擇圖片' : 'Select Image',
                          icon: Icons.add_photo_alternate,
                          showCropOption: true,
                          isTraditionalChinese: isTC,
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Upload progress indicator
                      UploadProgressWithError(isTraditionalChinese: isTC),
                      const SizedBox(height: 16),

                      // Availability toggle
                      SwitchListTile(
                        title: Text(isTC ? '可供應' : 'Available'),
                        subtitle: Text(
                          isTC
                              ? (_available ? '此項目可供應' : '此項目暫不可供應')
                              : (_available ? 'Item is available' : 'Item is sold out'),
                        ),
                        value: _available,
                        onChanged: (value) {
                          setState(() {
                            _available = value;
                          });
                        },
                        secondary: Icon(
                          _available ? Icons.check_circle : Icons.cancel,
                          color: _available ? Colors.green : Colors.red,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                isEdit
                                    ? (isTC ? '更新' : 'Update')
                                    : (isTC ? '建立' : 'Create'),
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
