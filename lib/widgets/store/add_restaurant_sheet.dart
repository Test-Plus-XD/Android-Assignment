import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/store_service.dart';
import '../../constants/districts.dart';
import '../../constants/keywords.dart';
import '../common/loading_indicator.dart';
import '../../constants/payments.dart';
import '../../constants/weekdays.dart';
import 'location_picker_dialog.dart';

/// Add Restaurant Bottom Sheet
///
/// Allows restaurant owners to create a new restaurant listing.
/// Shown as a draggable modal bottom sheet.
class AddRestaurantSheet extends StatefulWidget {
  final bool isTraditionalChinese;

  const AddRestaurantSheet({
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<AddRestaurantSheet> createState() => _AddRestaurantSheetState();
}

class _AddRestaurantSheetState extends State<AddRestaurantSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Form controllers
  late TextEditingController _nameEnController;
  late TextEditingController _nameTcController;
  late TextEditingController _addressEnController;
  late TextEditingController _addressTcController;
  late TextEditingController _seatsController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;

  // District
  String? _selectedDistrictEn;
  String? _selectedDistrictTc;

  // Location
  double? _latitude;
  double? _longitude;

  // Opening hours: each day has a toggle (open/closed) + from/to times
  final Map<String, bool> _dayOpen = {};
  final Map<String, TimeOfDay?> _dayFrom = {};
  final Map<String, TimeOfDay?> _dayTo = {};

  // Keywords
  List<String> _selectedKeywordsEn = [];
  List<String> _selectedKeywordsTc = [];

  // Payments
  List<String> _selectedPayments = [];

  bool get _isTC => widget.isTraditionalChinese;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController();
    _nameTcController = TextEditingController();
    _addressEnController = TextEditingController();
    _addressTcController = TextEditingController();
    _seatsController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();

    // Initialize opening hours state for all 7 days
    for (final day in Weekdays.enFull) {
      _dayOpen[day] = false;
      _dayFrom[day] = null;
      _dayTo[day] = null;
    }
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
    super.dispose();
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  void _showDistrictPicker() async {
    final selected = await showDialog<DistrictOption>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isTC ? '選擇地區' : 'Select District'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: HKDistricts.all.length,
            itemBuilder: (context, index) {
              final district = HKDistricts.all[index];
              return RadioListTile<DistrictOption>(
                title: Text(_isTC ? district.tc : district.en),
                value: district,
                groupValue: _selectedDistrictEn != null
                    ? HKDistricts.all.firstWhere(
                        (d) => d.en == _selectedDistrictEn,
                        orElse: () => HKDistricts.all.first,
                      )
                    : null,
                onChanged: (value) => Navigator.of(context).pop(value),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_isTC ? '取消' : 'Cancel'),
          ),
        ],
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
            title: Text(_isTC ? '選擇關鍵字' : 'Select Keywords'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: RestaurantKeywords.all.length,
                itemBuilder: (context, index) {
                  final keyword = RestaurantKeywords.all[index];
                  final isSelected = tempSelected.contains(keyword);
                  return CheckboxListTile(
                    title: Text(_isTC ? keyword.tc : keyword.en),
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
                child: Text(_isTC ? '取消' : 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(tempSelected),
                child: Text(_isTC ? '確定' : 'OK'),
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
            title: Text(_isTC ? '選擇付款方式' : 'Select Payment Methods'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: PaymentMethods.all.length,
                itemBuilder: (context, index) {
                  final payment = PaymentMethods.all[index];
                  final isSelected = tempSelected.contains(payment);
                  return CheckboxListTile(
                    title: Text(_isTC ? payment.tc : payment.en),
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
                child: Text(_isTC ? '取消' : 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(tempSelected),
                child: Text(_isTC ? '確定' : 'OK'),
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

  Future<void> _openLocationPicker() async {
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => LocationPickerDialog(
        initialLatitude: _latitude,
        initialLongitude: _longitude,
        isTraditionalChinese: _isTC,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });
    }
  }

  Future<void> _pickTime(String dayEn, bool isFrom) async {
    final initial = (isFrom ? _dayFrom[dayEn] : _dayTo[dayEn]) ??
        TimeOfDay(hour: isFrom ? 9 : 22, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _dayFrom[dayEn] = picked;
        } else {
          _dayTo[dayEn] = picked;
        }
      });
    }
  }

  // ── Formatting helpers ────────────────────────────────────────────────────

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final nameEn = _nameEnController.text.trim();
    final nameTc = _nameTcController.text.trim();

    if (nameEn.isEmpty && nameTc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isTC
                ? '請輸入至少一個餐廳名稱'
                : 'Please enter at least one restaurant name',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Build opening hours map: "Monday" -> "09:00-22:00"
      final openingHours = <String, String>{};
      for (final day in Weekdays.enFull) {
        if (_dayOpen[day] == true) {
          final from = _dayFrom[day];
          final to = _dayTo[day];
          if (from != null && to != null) {
            openingHours[day] = '${_formatTime(from)}-${_formatTime(to)}';
          }
        }
      }

      final payload = <String, dynamic>{
        if (nameEn.isNotEmpty) 'Name_EN': nameEn,
        if (nameTc.isNotEmpty) 'Name_TC': nameTc,
        if (_addressEnController.text.trim().isNotEmpty)
          'Address_EN': _addressEnController.text.trim(),
        if (_addressTcController.text.trim().isNotEmpty)
          'Address_TC': _addressTcController.text.trim(),
        if (_selectedDistrictEn != null) 'District_EN': _selectedDistrictEn,
        if (_selectedDistrictTc != null) 'District_TC': _selectedDistrictTc,
        if (_seatsController.text.trim().isNotEmpty)
          'Seats': int.tryParse(_seatsController.text.trim()),
        'Contacts': {
          if (_phoneController.text.trim().isNotEmpty)
            'Phone': _phoneController.text.trim(),
          if (_emailController.text.trim().isNotEmpty)
            'Email': _emailController.text.trim(),
          if (_websiteController.text.trim().isNotEmpty)
            'Website': _websiteController.text.trim(),
        },
        if (_selectedKeywordsEn.isNotEmpty) 'Keyword_EN': _selectedKeywordsEn,
        if (_selectedKeywordsTc.isNotEmpty) 'Keyword_TC': _selectedKeywordsTc,
        if (_selectedPayments.isNotEmpty) 'Payments': _selectedPayments,
        if (openingHours.isNotEmpty) 'Opening_Hours': openingHours,
        if (_latitude != null) 'Latitude': _latitude,
        if (_longitude != null) 'Longitude': _longitude,
      };

      final storeService = context.read<StoreService>();
      final success = await storeService.createRestaurant(payload);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isTC ? '餐廳已成功新增！' : 'Restaurant added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isTC ? '新增餐廳失敗，請稍後再試' : 'Failed to add restaurant. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_isTC ? "錯誤：" : "Error: "}$e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build helpers ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildDivider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(),
      );

  // ── Main build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (i) => {'en': Weekdays.enFull[i], 'tc': Weekdays.tc[i]},
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isTC ? '新增餐廳' : 'Add Restaurant',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Scrollable form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Required ──────────────────────────────────────
                          _buildSectionHeader(
                            _isTC ? '必填資訊' : 'Required',
                          ),

                          TextFormField(
                            controller: _nameEnController,
                            decoration: InputDecoration(
                              labelText: _isTC ? '名稱（英文）' : 'Name (English)',
                              border: const OutlineInputBorder(),
                              hintText: _isTC ? '至少填寫一個名稱' : 'At least one name required',
                            ),
                            validator: (value) {
                              if ((value == null || value.trim().isEmpty) &&
                                  _nameTcController.text.trim().isEmpty) {
                                return _isTC
                                    ? '請輸入英文或中文名稱'
                                    : 'Please enter EN or TC name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _nameTcController,
                            decoration: InputDecoration(
                              labelText: _isTC ? '名稱（中文）' : 'Name (Chinese)',
                              border: const OutlineInputBorder(),
                            ),
                          ),

                          _buildDivider(),

                          // ── Address ───────────────────────────────────────
                          _buildSectionHeader(_isTC ? '地址' : 'Address'),

                          TextFormField(
                            controller: _addressEnController,
                            decoration: InputDecoration(
                              labelText: _isTC ? '地址（英文）' : 'Address (English)',
                              border: const OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _addressTcController,
                            decoration: InputDecoration(
                              labelText: _isTC ? '地址（中文）' : 'Address (Chinese)',
                              border: const OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),

                          ListTile(
                            title: Text(_isTC ? '地區' : 'District'),
                            subtitle: Text(
                              _selectedDistrictEn != null
                                  ? (_isTC
                                      ? _selectedDistrictTc!
                                      : _selectedDistrictEn!)
                                  : (_isTC ? '未選擇' : 'Not selected'),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _showDistrictPicker,
                            tileColor:
                                Theme.of(context).colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),

                          _buildDivider(),

                          // ── Details ───────────────────────────────────────
                          _buildSectionHeader(_isTC ? '詳細資訊' : 'Details'),

                          TextFormField(
                            controller: _seatsController,
                            decoration: InputDecoration(
                              labelText: _isTC ? '座位數' : 'Seats',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.event_seat),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: _isTC ? '電話' : 'Phone',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: _isTC ? '電郵' : 'Email',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _websiteController,
                            decoration: InputDecoration(
                              labelText: _isTC ? '網站' : 'Website',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.language),
                            ),
                            keyboardType: TextInputType.url,
                          ),

                          _buildDivider(),

                          // ── Location ──────────────────────────────────────
                          _buildSectionHeader(_isTC ? '位置' : 'Location'),

                          if (_latitude != null && _longitude != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_isTC ? "緯度" : "Lat"}: ${_latitude!.toStringAsFixed(6)}\n'
                                      '${_isTC ? "經度" : "Lng"}: ${_longitude!.toStringAsFixed(6)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _latitude = null;
                                        _longitude = null;
                                      });
                                    },
                                    child: Text(_isTC ? '清除' : 'Clear'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ] else
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                _isTC
                                    ? '尚未設定位置'
                                    : 'No location set',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _openLocationPicker,
                              icon: const Icon(Icons.map),
                              label: Text(
                                _isTC ? '在地圖上選擇位置' : 'Select Location on Map',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),

                          _buildDivider(),

                          // ── Opening Hours ─────────────────────────────────
                          _buildSectionHeader(
                              _isTC ? '營業時間' : 'Opening Hours'),

                          ...days.map((day) {
                            final dayEn = day['en']!;
                            final dayTc = day['tc']!;
                            final isOpen = _dayOpen[dayEn] ?? false;
                            final fromTime = _dayFrom[dayEn];
                            final toTime = _dayTo[dayEn];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _isTC ? dayTc : dayEn,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                      Switch(
                                        value: isOpen,
                                        onChanged: (val) {
                                          setState(() {
                                            _dayOpen[dayEn] = val;
                                          });
                                        },
                                      ),
                                      Text(
                                        isOpen
                                            ? (_isTC ? '營業中' : 'Open')
                                            : (_isTC ? '休息' : 'Closed'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isOpen
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (isOpen) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                _pickTime(dayEn, true),
                                            icon: const Icon(Icons.access_time,
                                                size: 16),
                                            label: Text(
                                              fromTime != null
                                                  ? _formatTime(fromTime)
                                                  : (_isTC ? '開始時間' : 'From'),
                                              style: const TextStyle(
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward,
                                            size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                _pickTime(dayEn, false),
                                            icon: const Icon(Icons.access_time,
                                                size: 16),
                                            label: Text(
                                              toTime != null
                                                  ? _formatTime(toTime)
                                                  : (_isTC ? '結束時間' : 'To'),
                                              style: const TextStyle(
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),

                          _buildDivider(),

                          // ── Keywords ──────────────────────────────────────
                          _buildSectionHeader(_isTC ? '關鍵字' : 'Keywords'),

                          ListTile(
                            title: Text(_isTC ? '關鍵字' : 'Keywords'),
                            subtitle: Text(
                              _selectedKeywordsEn.isNotEmpty
                                  ? (_isTC
                                      ? _selectedKeywordsTc.join(', ')
                                      : _selectedKeywordsEn.join(', '))
                                  : (_isTC
                                      ? '點擊選擇（已選 0 個）'
                                      : 'Tap to select (0 selected)'),
                            ),
                            trailing: Text(
                              '${_selectedKeywordsEn.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            onTap: _showKeywordsPicker,
                            tileColor:
                                Theme.of(context).colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),

                          _buildDivider(),

                          // ── Payments ──────────────────────────────────────
                          _buildSectionHeader(
                              _isTC ? '付款方式' : 'Payment Methods'),

                          ListTile(
                            title: Text(_isTC ? '付款方式' : 'Payment Methods'),
                            subtitle: Text(
                              _selectedPayments.isNotEmpty
                                  ? _selectedPayments.map((code) {
                                      final p = PaymentMethods.all.firstWhere(
                                        (p) => p.en == code,
                                        orElse: () => PaymentOption(
                                            en: code, tc: code, icon: ''),
                                      );
                                      return _isTC ? p.tc : p.en;
                                    }).join(', ')
                                  : (_isTC
                                      ? '點擊選擇（已選 0 個）'
                                      : 'Tap to select (0 selected)'),
                            ),
                            trailing: Text(
                              '${_selectedPayments.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            onTap: _showPaymentsPicker,
                            tileColor:
                                Theme.of(context).colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),

                          const SizedBox(height: 24),

                          // ── Submit button ─────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: LoadingIndicator.small(),
                                    )
                                  : Text(
                                      _isTC ? '新增餐廳' : 'Add Restaurant',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
