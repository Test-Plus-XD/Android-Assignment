import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/advertisement_service.dart';
import '../services/image_service.dart';
import '../models.dart';

/// Advertisement Creation / Edit Form Page
///
/// Full-screen Material Design 3 page for creating or editing a restaurant ad.
///
/// Create flow (no existing ad passed):
///   1. Navigated to from StorePage Advertisements tab after Stripe payment succeeds
///   2. User fills in bilingual title + content, optionally uploads EN/TC images
///   3. On submit → calls [AdvertisementService.createAdvertisement]
///   4. Pops back with `true` so the caller can refresh the list
///
/// Edit flow (existing ad passed):
///   - Pre-fills all fields from the existing [Advertisement]
///   - On submit → calls [AdvertisementService.updateAdvertisement]
///
/// Language fallback:
///   If one language field is left empty the other language's value is copied
///   over before submission so the ad is always fully bilingual.
class StoreAdFormPage extends StatefulWidget {
  final String restaurantId;
  final bool isTraditionalChinese;
  // If provided, the form is in edit mode
  final Advertisement? advertisement;

  const StoreAdFormPage({
    required this.restaurantId,
    required this.isTraditionalChinese,
    this.advertisement,
    super.key,
  });

  @override
  State<StoreAdFormPage> createState() => _StoreAdFormPageState();
}

class _StoreAdFormPageState extends State<StoreAdFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late final TextEditingController _titleEnCtrl;
  late final TextEditingController _titleTcCtrl;
  late final TextEditingController _contentEnCtrl;
  late final TextEditingController _contentTcCtrl;

  // Uploaded image URLs (stored in Firebase / API)
  String? _imageUrlEn;
  String? _imageUrlTc;

  // Local file selections (before upload)
  File? _imageFileEn;
  File? _imageFileTc;

  bool _isSubmitting = false;

  bool get _isEditing => widget.advertisement != null;

  @override
  void initState() {
    super.initState();
    final ad = widget.advertisement;
    _titleEnCtrl = TextEditingController(text: ad?.titleEn ?? '');
    _titleTcCtrl = TextEditingController(text: ad?.titleTc ?? '');
    _contentEnCtrl = TextEditingController(text: ad?.contentEn ?? '');
    _contentTcCtrl = TextEditingController(text: ad?.contentTc ?? '');
    _imageUrlEn = ad?.imageEn;
    _imageUrlTc = ad?.imageTc;
  }

  @override
  void dispose() {
    _titleEnCtrl.dispose();
    _titleTcCtrl.dispose();
    _contentEnCtrl.dispose();
    _contentTcCtrl.dispose();
    super.dispose();
  }

  bool get _isTC => widget.isTraditionalChinese;

  /// Pick an image from gallery and store it as a pending local file
  Future<void> _pickImage({required bool isEnglish}) async {
    final imageService = context.read<ImageService>();
    final file = await imageService.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    setState(() {
      if (isEnglish) {
        _imageFileEn = file;
      } else {
        _imageFileTc = file;
      }
    });
  }

  /// Upload both pending image files to Firebase Storage
  /// Returns false if any upload fails
  Future<bool> _uploadPendingImages() async {
    final imageService = context.read<ImageService>();

    if (_imageFileEn != null) {
      final result = await imageService.uploadImage(
        imageFile: _imageFileEn!,
        folder: 'Advertisements',
      );
      if (result == null) return false;
      _imageUrlEn = result['url'];
    }

    if (_imageFileTc != null) {
      final result = await imageService.uploadImage(
        imageFile: _imageFileTc!,
        folder: 'Advertisements',
      );
      if (result == null) return false;
      _imageUrlTc = result['url'];
    }

    return true;
  }

  /// Validate, apply language fallback, upload images, then save
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Upload any newly selected images
      final uploadOk = await _uploadPendingImages();
      if (!mounted) return;
      if (!uploadOk) {
        _showError(_isTC ? '圖片上傳失敗' : 'Image upload failed');
        return;
      }

      // Language fallback: copy from the filled language if one is empty
      final titleEn = _titleEnCtrl.text.trim().isNotEmpty
          ? _titleEnCtrl.text.trim()
          : _titleTcCtrl.text.trim();
      final titleTc = _titleTcCtrl.text.trim().isNotEmpty
          ? _titleTcCtrl.text.trim()
          : _titleEnCtrl.text.trim();
      final contentEn = _contentEnCtrl.text.trim().isNotEmpty
          ? _contentEnCtrl.text.trim()
          : _contentTcCtrl.text.trim();
      final contentTc = _contentTcCtrl.text.trim().isNotEmpty
          ? _contentTcCtrl.text.trim()
          : _contentEnCtrl.text.trim();

      final adService = context.read<AdvertisementService>();

      if (_isEditing) {
        // Edit mode: send only changed fields
        await adService.updateAdvertisement(
          widget.advertisement!.id,
          {
            'Title_EN': titleEn,
            'Title_TC': titleTc,
            'Content_EN': contentEn,
            'Content_TC': contentTc,
            if (_imageUrlEn != null) 'Image_EN': _imageUrlEn,
            if (_imageUrlTc != null) 'Image_TC': _imageUrlTc,
          },
        );
      } else {
        // Create mode
        final request = CreateAdvertisementRequest(
          restaurantId: widget.restaurantId,
          titleEn: titleEn.isNotEmpty ? titleEn : null,
          titleTc: titleTc.isNotEmpty ? titleTc : null,
          contentEn: contentEn.isNotEmpty ? contentEn : null,
          contentTc: contentTc.isNotEmpty ? contentTc : null,
          imageEn: _imageUrlEn,
          imageTc: _imageUrlTc,
        );
        await adService.createAdvertisement(request);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true); // true → caller should refresh
    } catch (e) {
      if (!mounted) return;
      _showError('${_isTC ? "儲存失敗：" : "Save failed: "}$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pageTitle = _isEditing
        ? (_isTC ? '編輯廣告' : 'Edit Advertisement')
        : (_isTC ? '建立廣告' : 'Create Advertisement');

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        actions: [
          // Save button in app bar
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isTC ? '儲存' : 'Save',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── English Section ──────────────────────────────────────────
              Text(
                _isTC ? '英文內容' : 'English Content',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Title EN
              TextFormField(
                controller: _titleEnCtrl,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: _isTC ? '標題（英文）' : 'Title (English)',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  // At least one title must be filled
                  if ((v == null || v.trim().isEmpty) &&
                      _titleTcCtrl.text.trim().isEmpty) {
                    return _isTC
                        ? '請填寫至少一個語言的標題'
                        : 'Please enter a title in at least one language';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Content EN
              TextFormField(
                controller: _contentEnCtrl,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: _isTC ? '內容（英文）' : 'Content (English)',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Image EN
              _buildImagePicker(
                label: _isTC ? '圖片（英文版）' : 'Image (English version)',
                imageFile: _imageFileEn,
                existingUrl: widget.advertisement?.imageEn,
                onPick: () => _pickImage(isEnglish: true),
                onClear: () => setState(() {
                  _imageFileEn = null;
                  _imageUrlEn = null;
                }),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // ── Traditional Chinese Section ───────────────────────────────
              Text(
                _isTC ? '中文內容' : 'Traditional Chinese Content',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Title TC
              TextFormField(
                controller: _titleTcCtrl,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: _isTC ? '標題（中文）' : 'Title (Chinese)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Content TC
              TextFormField(
                controller: _contentTcCtrl,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: _isTC ? '內容（中文）' : 'Content (Chinese)',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Image TC
              _buildImagePicker(
                label: _isTC ? '圖片（中文版）' : 'Image (Chinese version)',
                imageFile: _imageFileTc,
                existingUrl: widget.advertisement?.imageTc,
                onPick: () => _pickImage(isEnglish: false),
                onClear: () => setState(() {
                  _imageFileTc = null;
                  _imageUrlTc = null;
                }),
              ),

              const SizedBox(height: 32),

              // Bottom submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isEditing
                              ? (_isTC ? '儲存更改' : 'Save Changes')
                              : (_isTC ? '發布廣告' : 'Publish Advertisement'),
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Image picker row — shows selected local file preview or existing URL hint
  Widget _buildImagePicker({
    required String label,
    required File? imageFile,
    required String? existingUrl,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    final hasImage = imageFile != null || existingUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            // Preview thumbnail
            if (imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
            else if (existingUrl != null)
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, size: 32),
              ),
            if (hasImage) const SizedBox(width: 12),
            // Pick button
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(hasImage
                  ? (_isTC ? '更換圖片' : 'Change Image')
                  : (_isTC ? '選擇圖片' : 'Select Image')),
            ),
            // Clear button
            if (hasImage) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.clear, size: 20),
                tooltip: _isTC ? '移除圖片' : 'Remove image',
                color: Colors.red,
              ),
            ],
          ],
        ),
        // Show existing URL hint when no new file selected
        if (existingUrl != null && imageFile == null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _isTC ? '已有上傳圖片' : 'Existing image uploaded',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
