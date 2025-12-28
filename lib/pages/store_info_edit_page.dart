import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/store_service.dart';
import '../services/auth_service.dart';
import '../models.dart';
import '../constants/districts.dart';
import '../constants/keywords.dart';
import '../constants/payments.dart';
import '../constants/weekdays.dart';
import '../widgets/store/location_picker_dialog.dart';
import '../widgets/store/restaurant_image_upload.dart';

/// Store Information Edit Page
///
/// Allows restaurant owners to edit their restaurant information including:
/// - Name (EN/TC)
/// - Address (EN/TC)
/// - District
/// - Keywords
/// - Seats
/// - Contact info (phone, email, website)
/// - Payment methods
/// - Opening hours
/// - Location (latitude/longitude)
class StoreInfoEditPage extends StatefulWidget {
  final Restaurant restaurant;
  final bool isTraditionalChinese;

  const StoreInfoEditPage({
    required this.restaurant,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<StoreInfoEditPage> createState() => _StoreInfoEditPageState();
}

class _StoreInfoEditPageState extends State<StoreInfoEditPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Form fields
  late TextEditingController _nameEnController;
  late TextEditingController _nameTcController;
  late TextEditingController _addressEnController;
  late TextEditingController _addressTcController;
  late TextEditingController _seatsController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  String? _selectedDistrictEn;
  String? _selectedDistrictTc;
  List<String> _selectedKeywordsEn = [];
  List<String> _selectedKeywordsTc = [];
  List<String> _selectedPayments = [];
  Map<String, String> _openingHours = {};
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final r = widget.restaurant;

    _nameEnController = TextEditingController(text: r.nameEn ?? '');
    _nameTcController = TextEditingController(text: r.nameTc ?? '');
    _addressEnController = TextEditingController(text: r.addressEn ?? '');
    _addressTcController = TextEditingController(text: r.addressTc ?? '');
    _seatsController = TextEditingController(text: r.seats?.toString() ?? '');
    _phoneController = TextEditingController(text: r.contacts?['Phone']?.toString() ?? '');
    _emailController = TextEditingController(text: r.contacts?['Email']?.toString() ?? '');
    _websiteController = TextEditingController(text: r.contacts?['Website']?.toString() ?? '');
    _latitudeController = TextEditingController(text: r.latitude?.toString() ?? '');
    _longitudeController = TextEditingController(text: r.longitude?.toString() ?? '');

    _selectedDistrictEn = r.districtEn;
    _selectedDistrictTc = r.districtTc;
    _selectedKeywordsEn = List<String>.from(r.keywordEn ?? []);
    _selectedKeywordsTc = List<String>.from(r.keywordTc ?? []);
    _selectedPayments = List<String>.from(r.payments ?? []);
    _openingHours = (r.openingHours ?? {}).map((key, value) => MapEntry(key, value.toString()));
    _imageUrl = r.imageUrl;
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameTcController.dispose();
    _addressEnController.dispose();
    _addressTcController.dispose();
    _seatsController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final payload = <String, dynamic>{
        'Name_EN': _nameEnController.text.trim().isEmpty ? null : _nameEnController.text.trim(),
        'Name_TC': _nameTcController.text.trim().isEmpty ? null : _nameTcController.text.trim(),
        'Address_EN': _addressEnController.text.trim().isEmpty ? null : _addressEnController.text.trim(),
        'Address_TC': _addressTcController.text.trim().isEmpty ? null : _addressTcController.text.trim(),
        'ImageUrl': _imageUrl,
        'District_EN': _selectedDistrictEn,
        'District_TC': _selectedDistrictTc,
        'Keyword_EN': _selectedKeywordsEn.isEmpty ? null : _selectedKeywordsEn,
        'Keyword_TC': _selectedKeywordsTc.isEmpty ? null : _selectedKeywordsTc,
        'Seats': _seatsController.text.trim().isEmpty ? null : int.tryParse(_seatsController.text.trim()),
        'Contacts': {
          'Phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'Email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          'Website': _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        },
        'Payments': _selectedPayments.isEmpty ? null : _selectedPayments,
        'Opening_Hours': _openingHours.isEmpty ? null : _openingHours,
        if (_latitudeController.text.trim().isNotEmpty)
          'Latitude': double.tryParse(_latitudeController.text.trim()),
        if (_longitudeController.text.trim().isNotEmpty)
          'Longitude': double.tryParse(_longitudeController.text.trim()),
      };

      final storeService = context.read<StoreService>();
      await storeService.updateRestaurantInfo(widget.restaurant.id, payload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isTraditionalChinese ? '更新成功' : 'Updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isTraditionalChinese ? '更新失敗：$e' : 'Update failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showDistrictPicker() async {
    final selected = await showDialog<DistrictOption>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '選擇地區' : 'Select District'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: HKDistricts.all.length,
            itemBuilder: (context, index) {
              final district = HKDistricts.all[index];
              return RadioListTile<DistrictOption>(
                title: Text(widget.isTraditionalChinese ? district.tc : district.en),
                value: district,
                groupValue: HKDistricts.all.firstWhere(
                  (d) => d.en == _selectedDistrictEn,
                  orElse: () => HKDistricts.all.first,
                ),
                onChanged: (value) => Navigator.of(context).pop(value),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedDistrictEn = selected.en;
        _selectedDistrictTc = selected.tc;
      });
    }
  }

  void _showKeywordsPicker() async {
    final selected = await showDialog<List<KeywordOption>>(
      context: context,
      builder: (context) {
        final tempSelected = List<KeywordOption>.from(
          RestaurantKeywords.all.where((k) => _selectedKeywordsEn.contains(k.en)),
        );

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(widget.isTraditionalChinese ? '選擇關鍵字' : 'Select Keywords'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: RestaurantKeywords.all.length,
                itemBuilder: (context, index) {
                  final keyword = RestaurantKeywords.all[index];
                  final isSelected = tempSelected.contains(keyword);

                  return CheckboxListTile(
                    title: Text(widget.isTraditionalChinese ? keyword.tc : keyword.en),
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          tempSelected.add(keyword);
                        } else {
                          tempSelected.remove(keyword);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(tempSelected),
                child: Text(widget.isTraditionalChinese ? '確定' : 'OK'),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedKeywordsEn = selected.map((k) => k.en).toList();
        _selectedKeywordsTc = selected.map((k) => k.tc).toList();
      });
    }
  }

  void _showPaymentsPicker() async {
    final selected = await showDialog<List<PaymentOption>>(
      context: context,
      builder: (context) {
        final tempSelected = List<PaymentOption>.from(
          PaymentMethods.all.where((p) => _selectedPayments.contains(p.en)),
        );

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(widget.isTraditionalChinese ? '選擇付款方式' : 'Select Payment Methods'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: PaymentMethods.all.length,
                itemBuilder: (context, index) {
                  final payment = PaymentMethods.all[index];
                  final isSelected = tempSelected.contains(payment);

                  return CheckboxListTile(
                    title: Text(widget.isTraditionalChinese ? payment.tc : payment.en),
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          tempSelected.add(payment);
                        } else {
                          tempSelected.remove(payment);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(tempSelected),
                child: Text(widget.isTraditionalChinese ? '確定' : 'OK'),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedPayments = selected.map((p) => p.en).toList();
      });
    }
  }

  void _editOpeningHours(String dayEn, String dayTc) async {
    final controller = TextEditingController(text: _openingHours[dayEn] ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? dayTc : dayEn),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: widget.isTraditionalChinese
                ? '例如：09:00-22:00 或 休息'
                : 'e.g., 09:00-22:00 or Closed',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(widget.isTraditionalChinese ? '確定' : 'OK'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result != null) {
      setState(() {
        if (result.trim().isEmpty) {
          _openingHours.remove(dayEn);
        } else {
          _openingHours[dayEn] = result.trim();
        }
      });
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => LocationPickerDialog(
        initialLatitude: double.tryParse(_latitudeController.text.trim()),
        initialLongitude: double.tryParse(_longitudeController.text.trim()),
        isTraditionalChinese: widget.isTraditionalChinese,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitudeController.text = result['latitude']!.toStringAsFixed(6);
        _longitudeController.text = result['longitude']!.toStringAsFixed(6);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create a list of day objects for the loop
    final days = List.generate(7, (i) => {
      'en': Weekdays.enFull[i],
      'tc': Weekdays.tc[i],
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTraditionalChinese ? '編輯餐廳資訊' : 'Edit Restaurant Info'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
              tooltip: widget.isTraditionalChinese ? '儲存' : 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Image Upload Section
            RestaurantImageUpload(
              currentImageUrl: _imageUrl,
              onImageUploaded: (imageUrl) {
                setState(() {
                  _imageUrl = imageUrl;
                });
              },
              isTraditionalChinese: widget.isTraditionalChinese,
            ),
            const SizedBox(height: 24),

            // Basic Info Section
            _buildSectionHeader(widget.isTraditionalChinese ? '基本資訊' : 'Basic Information'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameEnController,
              decoration: InputDecoration(
                labelText: widget.isTraditionalChinese ? '名稱（英文）' : 'Name (English)',
                border: const OutlineInputBorder(),
              ),
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
              controller: _addressEnController,
              decoration: InputDecoration(
                labelText: widget.isTraditionalChinese ? '地址（英文）' : 'Address (English)',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _addressTcController,
              decoration: InputDecoration(
                labelText: widget.isTraditionalChinese ? '地址（中文）' : 'Address (Chinese)',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            ListTile(
              title: Text(widget.isTraditionalChinese ? '地區' : 'District'),
              subtitle: Text(
                _selectedDistrictEn != null
                    ? (widget.isTraditionalChinese ? _selectedDistrictTc! : _selectedDistrictEn!)
                    : (widget.isTraditionalChinese ? '未選擇' : 'Not selected'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showDistrictPicker,
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 12),

            ListTile(
              title: Text(widget.isTraditionalChinese ? '關鍵字' : 'Keywords'),
              subtitle: Text(
                _selectedKeywordsEn.isNotEmpty
                    ? (widget.isTraditionalChinese
                        ? _selectedKeywordsTc.join(', ')
                        : _selectedKeywordsEn.join(', '))
                    : (widget.isTraditionalChinese ? '未選擇' : 'Not selected'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showKeywordsPicker,
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _seatsController,
              decoration: InputDecoration(
                labelText: widget.isTraditionalChinese ? '座位數' : 'Seats',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Contact Info Section
            _buildSectionHeader(widget.isTraditionalChinese ? '聯絡資訊' : 'Contact Information'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: widget.isTraditionalChinese ? '電話' : 'Phone',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: widget.isTraditionalChinese ? '電郵' : 'Email',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _websiteController,
              decoration: InputDecoration(
                labelText: widget.isTraditionalChinese ? '網站' : 'Website',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.language),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // Payment Methods Section
            _buildSectionHeader(widget.isTraditionalChinese ? '付款方式' : 'Payment Methods'),
            const SizedBox(height: 12),

            ListTile(
              title: Text(widget.isTraditionalChinese ? '付款方式' : 'Payment Methods'),
              subtitle: Text(
                _selectedPayments.isNotEmpty
                    ? _selectedPayments.map((code) {
                        final payment = PaymentMethods.all.firstWhere(
                          (p) => p.en == code,
                          orElse: () => PaymentOption(en: code, tc: code, icon: ''),
                        );
                        return widget.isTraditionalChinese ? payment.tc : payment.en;
                      }).join(', ')
                    : (widget.isTraditionalChinese ? '未選擇' : 'Not selected'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showPaymentsPicker,
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 24),

            // Opening Hours Section
            _buildSectionHeader(widget.isTraditionalChinese ? '營業時間' : 'Opening Hours'),
            const SizedBox(height: 12),

            ...days.map((day) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                title: Text(widget.isTraditionalChinese ? day['tc']! : day['en']!),
                subtitle: Text(_openingHours[day['en']] ??
                    (widget.isTraditionalChinese ? '未設定' : 'Not set')),
                trailing: const Icon(Icons.edit),
                onTap: () => _editOpeningHours(day['en']!, day['tc']!),
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )),
            const SizedBox(height: 24),

            // Location Section
            _buildSectionHeader(widget.isTraditionalChinese ? '位置' : 'Location'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _latitudeController,
              decoration: InputDecoration(
                labelText: widget.isTraditionalChinese ? '緯度' : 'Latitude',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _longitudeController,
              decoration: InputDecoration(
                labelText: widget.isTraditionalChinese ? '經度' : 'Longitude',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),

            // Location picker button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openLocationPicker,
                icon: const Icon(Icons.map),
                label: Text(
                  widget.isTraditionalChinese ? '在地圖上選擇位置' : 'Select Location on Map',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 80), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
