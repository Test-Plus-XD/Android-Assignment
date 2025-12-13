import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../config.dart';
import '../models.dart';
import 'chat.dart';
import 'store.dart';

/// Restaurant Detail Page - Native Android Integration
/// 
/// This page uses multiple native Android features working together:
/// - Information panels presented in a responsive GridView
/// - Google Maps integration for location display
/// - Cached network image for the restaurant (performance-conscious)
/// - Share functionality using Android's share sheet
/// - URL launching for phone/email/maps
/// - Date/time picker for bookings (still in progress)
/// - Local notifications for reminders (still in progress)
class RestaurantDetailPage extends StatefulWidget {
  final Restaurant restaurant;
  final bool isTraditionalChinese;

  const RestaurantDetailPage({
    required this.restaurant,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  // Google Maps controller for map interactions
  GoogleMapController? _mapController;
  // Booking date/time selection
  DateTime? _selectedDateTime;
  // Number of guests
  int _numberOfGuests = 1;
  // Loading states
  bool _isBooking = false;
  bool _isClaiming = false;
  // Map type and controls visibility
  MapType _currentMapType = MapType.normal;
  // Map type toggle states
  final bool _showMapControls = true;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Calculate distance from user's location
  ///
  /// Shows "1.2km away" text if we have user's location.
  /// This helps users understand if the restaurant is convenient.
  String? _getDistanceText() {
    final locationService = context.read<LocationService>();
    if (widget.restaurant.latitude == null || widget.restaurant.longitude == null) return null;
    final distance = locationService.calculateDistanceFromCurrent( widget.restaurant.latitude!, widget.restaurant.longitude!, );
    if (distance == null) return null;
    return locationService.formatDistance(distance);
  }

  /// Get display value with fallback
  ///
  /// Returns the primary language value, or falls back to the alternative
  /// if the primary is null or empty.
  String _getDisplayValue(String? primary, String? fallback) {
    if (primary != null && primary.trim().isNotEmpty) return primary;
    if (fallback != null && fallback.trim().isNotEmpty) return fallback;
    return widget.isTraditionalChinese ? '未提供' : 'Not provided';
  }

  /// Checks if current user can claim this restaurant
  bool _canClaimRestaurant() {
    final authService = context.read<AuthService>();
    final userService = context.read<UserService>();
    final user = userService.currentProfile;

    // Must be logged in
    if (!authService.isLoggedIn || user == null) return false;
    // User type must be Restaurant
    if (!user.isRestaurantOwner) return false;
    // User must not already own a restaurant
    if (user.hasClaimedRestaurant) return false;
    // Restaurant must not already have an owner
    if (widget.restaurant.ownerId != null && widget.restaurant.ownerId!.isNotEmpty) return false;

    return true;
  }

  /// Shows claim confirmation dialog with bilingual support
  Future<void> _showClaimDialog() async {
    final name = widget.isTraditionalChinese
        ? _getDisplayValue(widget.restaurant.nameTc, widget.restaurant.nameEn)
        : _getDisplayValue(widget.restaurant.nameEn, widget.restaurant.nameTc);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '認領餐廳' : 'Claim Restaurant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isTraditionalChinese
                  ? '您確定要認領「$name」嗎？'
                  : 'Are you sure you want to claim "$name"?',
            ),
            const SizedBox(height: 12),
            Text(
              widget.isTraditionalChinese
                  ? '認領後您將成為此餐廳的管理者，可以編輯餐廳資訊和管理預訂。'
                  : 'After claiming, you will become the manager of this restaurant and can edit its information and manage bookings.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.isTraditionalChinese ? '確認認領' : 'Confirm Claim'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _claimRestaurant();
    }
  }

  /// Claims the restaurant with comprehensive error handling
  Future<void> _claimRestaurant() async {
    final authService = context.read<AuthService>();
    final userService = context.read<UserService>();
    final user = userService.currentProfile;

    // Validation checks with bilingual error messages
    if (!authService.isLoggedIn || user == null) {
      _showClaimError(widget.isTraditionalChinese ? '請先登入' : 'Please log in first');
      return;
    }

    if (!user.isRestaurantOwner) {
      _showClaimError(widget.isTraditionalChinese
          ? '您沒有權限認領此餐廳'
          : 'You are not authorized to claim this restaurant');
      return;
    }

    if (user.hasClaimedRestaurant) {
      _showClaimError(widget.isTraditionalChinese
          ? '您已經擁有另一間餐廳'
          : 'You already own another restaurant');
      return;
    }

    if (widget.restaurant.ownerId != null && widget.restaurant.ownerId!.isNotEmpty) {
      _showClaimError(widget.isTraditionalChinese
          ? '此餐廳已被認領'
          : 'This restaurant has already been claimed');
      return;
    }

    setState(() => _isClaiming = true);

    try {
      final token = await authService.idToken;
      if (token == null) {
        _showClaimError(widget.isTraditionalChinese
            ? '無法獲取身份驗證令牌'
            : 'Failed to get authentication token');
        setState(() => _isClaiming = false);
        return;
      }

      // Call claim API endpoint
      final response = await http.post(
        Uri.parse(AppConfig.getClaimEndpoint(widget.restaurant.id)),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh user profile to get updated restaurantId
        await userService.getUserProfile(authService.uid!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isTraditionalChinese
                    ? '認領成功！正在跳轉到店舖管理頁面...'
                    : 'Claim successful! Redirecting to store management...',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to store page after delay
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: Text(widget.isTraditionalChinese ? '我的店舖' : 'My Store'),
                    ),
                    body: StorePage(
                      isTraditionalChinese: widget.isTraditionalChinese,
                      isDarkMode: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
              );
            }
          });
        }
      } else {
        // Parse error response
        String errorMsg;
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['error'] ?? errorData['message'] ?? 'Unknown error';
        } catch (_) {
          errorMsg = 'Server error: ${response.statusCode}';
        }

        // Map common errors to bilingual messages
        if (errorMsg.contains('already claimed') || errorMsg.contains('owner')) {
          _showClaimError(widget.isTraditionalChinese ? '此餐廳已被認領' : 'This restaurant has already been claimed');
        } else if (errorMsg.contains('already own')) {
          _showClaimError(widget.isTraditionalChinese ? '您已經擁有另一間餐廳' : 'You already own another restaurant');
        } else if (errorMsg.contains('not found')) {
          _showClaimError(widget.isTraditionalChinese ? '找不到此餐廳' : 'Restaurant not found');
        } else if (errorMsg.contains('unauthorized') || errorMsg.contains('permission')) {
          _showClaimError(widget.isTraditionalChinese ? '您沒有權限認領此餐廳' : 'You are not authorized to claim this restaurant');
        } else {
          _showClaimError(widget.isTraditionalChinese ? '認領失敗,請重試' : 'Claim failed, please try again');
        }
      }
    } catch (error) {
      if (kDebugMode) print('Claim error: $error');
      _showClaimError(widget.isTraditionalChinese ? '認領失敗,請重試' : 'Claim failed, please try again');
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  /// Shows claim error snackbar
  void _showClaimError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Opens the chat page for this restaurant
  void _openChat() {
    final authService = context.read<AuthService>();

    if (!authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTraditionalChinese ? '請先登入以使用聊天功能' : 'Please log in to use chat',
          ),
        ),
      );
      return;
    }

    final roomId = 'restaurant-${widget.restaurant.id}';
    final roomName = widget.isTraditionalChinese
        ? _getDisplayValue(widget.restaurant.nameTc, widget.restaurant.nameEn)
        : _getDisplayValue(widget.restaurant.nameEn, widget.restaurant.nameTc);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          roomId: roomId,
          roomName: roomName,
          isTraditionalChinese: widget.isTraditionalChinese,
        ),
      ),
    );
  }

  /// Share restaurant details
  ///
  /// Opens Android's native share sheet with restaurant information.
  /// User can share via WhatsApp, Email, SMS, etc.
  ///
  /// Why this matters:
  /// Sharing is a common action in restaurant apps. Friends share
  /// recommendations constantly. Making this one tap is crucial for
  /// word-of-mouth growth.
  Future<void> _shareRestaurant() async {
    try {
      final name = widget.isTraditionalChinese
          ? _getDisplayValue(widget.restaurant.nameTc, widget.restaurant.nameEn)
          : _getDisplayValue(widget.restaurant.nameEn, widget.restaurant.nameTc);
      final address = widget.isTraditionalChinese
          ? _getDisplayValue(widget.restaurant.addressTc, widget.restaurant.addressEn)
          : _getDisplayValue(widget.restaurant.addressEn, widget.restaurant.addressTc);

      // Build share text with restaurant details
      final shareText = widget.isTraditionalChinese
          ? '我啱啱發現咗呢間好正斗嘅素食餐廳！\n\n$name\n$address'
          : 'I found this great vegan restaurant!\n\n$name\n$address';
      // Open Android share sheet
      await Share.share(
        shareText,
        subject: name, // Used for email subject line
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isTraditionalChinese ? '分享失敗' : 'Failed to share')),
        );
      }
    }
  }

  /// Open phone dialler
  ///
  /// Launches Android's phone app with number pre-filled.
  /// User just needs to tap "call" to connect.
  ///
  /// URL Scheme: tel:+85212345678
  /// Android recognises this and opens the appropriate app.
  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isTraditionalChinese ? '無法撥打電話' : 'Could not make call')),
      );
    }
  }

  /// Open email client
  ///
  /// Launches user's email app with recipient pre-filled.
  ///
  /// URL Scheme: mailto:restaurant@example.com
  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isTraditionalChinese ? '無法發送電郵' : 'Could not send email')),
      );
    }
  }

  /// Open website in browser
  ///
  /// Launches user's default browser with restaurant website.
  ///
  /// LaunchMode options:
  /// - platformDefault: Let Android decide (usually external browser)
  /// - externalApplication: Force external browser
  /// - inAppWebView: Open in app (requires WebView setup)
  Future<void> _openWebsite(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isTraditionalChinese ? '無法打開網站' : 'Could not open website')),
      );
    }
  }

  /// Open location in Google Maps
  ///
  /// This is a very common pattern - tapping an address opens Google Maps
  /// with directions. Android users expect this behaviour.
  ///
  /// URL Scheme: geo:0,0?q=22.3964,114.1095(Restaurant Name)
  /// The "0,0" is placeholder, the query param has actual coordinates.
  Future<void> _openInMaps() async {
    if (widget.restaurant.latitude == null || widget.restaurant.longitude == null) return;
    final name = widget.isTraditionalChinese
        ? _getDisplayValue(widget.restaurant.nameTc, widget.restaurant.nameEn)
        : _getDisplayValue(widget.restaurant.nameEn, widget.restaurant.nameTc);
    final uri = Uri.parse('geo:0,0?q=${widget.restaurant.latitude},${widget.restaurant.longitude}($name)');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isTraditionalChinese ? '無法打開地圖' : 'Could not open maps')),
      );
    }
  }

  /// Show booking dialog
  ///
  /// This is where all our services come together:
  /// 1. User selects date/time and party size
  /// 2. BookingService creates reservation in Firestore
  /// 3. NotificationService schedules reminder
  /// 4. User sees confirmation
  ///
  /// This demonstrates coordinating multiple services for one feature.
  Future<void> _showBookingDialog() async {
    // Reset state
    _selectedDateTime = null;
    _numberOfGuests = 1;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            widget.isTraditionalChinese ? '預訂餐桌' : 'Book a Table',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              // Date and time picker
              children: [
                Text(
                  widget.isTraditionalChinese ? '日期和時間' : 'Date and Time',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _selectedDateTime == null
                        ? (widget.isTraditionalChinese ? '選擇日期時間' : 'Select date & time')
                        : _formatDateTime(_selectedDateTime!),
                  ),
                  onPressed: () async {
                    // Show date picker
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (date != null && context.mounted) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 17, minute: 0),
                      );
                      if (time != null) {
                        setState(() {
                          _selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Number of guests selector
                Text(
                  widget.isTraditionalChinese ? '人數' : 'Number of Guests',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _numberOfGuests > 1
                          ? () => setState(() => _numberOfGuests--)
                          : null,
                    ),
                    Text(
                      '$_numberOfGuests',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _numberOfGuests < 20
                          ? () => setState(() => _numberOfGuests++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: _selectedDateTime == null
                  ? null
                  : () {
                Navigator.pop(context);
                _confirmBooking();
              },
              child: Text(widget.isTraditionalChinese ? '確認' : 'Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirm and process booking
  ///
  /// This is the complete booking flow:
  /// 1. Create booking record in Firestore
  /// 2. Schedule notification reminder (2 hours before)
  /// 3. Show confirmation to user
  Future<void> _confirmBooking() async {
    if (_selectedDateTime == null) return;
    setState(() => _isBooking = true);
    try {
      final bookingService = context.read<BookingService>();
      final notificationService = context.read<NotificationService>();
      final name = widget.isTraditionalChinese
          ? _getDisplayValue(widget.restaurant.nameTc, widget.restaurant.nameEn)
          : _getDisplayValue(widget.restaurant.nameEn, widget.restaurant.nameTc);
      // Step 1: Create booking in Firestore
      final booking = await bookingService.createBooking(
        restaurantId: widget.restaurant.id,
        restaurantName: name,
        dateTime: _selectedDateTime!,
        numberOfGuests: _numberOfGuests,
      );
      if (booking == null) throw Exception('Failed to create booking');
      // Step 2: Schedule notification reminder
      // Show notification 2 hours before booking time
      final notificationTime = _selectedDateTime!.subtract(
        const Duration(hours: 2),
      );
      // Only schedule if notification time is in future
      if (notificationTime.isAfter(DateTime.now())) {
        await notificationService.scheduleBookingReminder(
          id: booking.id.hashCode, // Convert string ID to integer
          restaurantNameEn: widget.restaurant.nameEn ?? 'Restaurant',
          restaurantNameTc: widget.restaurant.nameTc ?? '餐廳',
          bookingDateTime: _selectedDateTime!,
          notificationTime: notificationTime,
          isTraditionalChinese: widget.isTraditionalChinese,
        );
      }
      // Step 3: Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isTraditionalChinese
                ? '預訂成功！您將在 2 小時前收到提醒。'
                : 'Booking confirmed! You\'ll receive a reminder 2 hours before.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isTraditionalChinese ? '預訂失敗：$e' : 'Booking failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isBooking = false);
    }
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    if (widget.isTraditionalChinese) {
      return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Toggle map type between normal, satellite, and terrain
  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : _currentMapType == MapType.satellite
          ? MapType.terrain
          : MapType.normal;
    });
  }

  /// Animate camera to restaurant location
  void _centerOnRestaurant() {
    if (_mapController != null && widget.restaurant.latitude != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              widget.restaurant.latitude!,
              widget.restaurant.longitude!,
            ),
            zoom: 16,
          ),
        ),
      );
    }
  }

  /// Build a grid tile card for information display
  ///
  /// Creates a consistent card layout for the "田"-shaped grid.
  Widget _buildGridTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onTap != null) Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build contact action tile
  ///
  /// Creates an interactive card for contact methods with appropriate icons.
  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get display values with fallback logic
    final name = widget.isTraditionalChinese
        ? _getDisplayValue(widget.restaurant.nameTc, widget.restaurant.nameEn)
        : _getDisplayValue(widget.restaurant.nameEn, widget.restaurant.nameTc);
    final address = widget.isTraditionalChinese
        ? _getDisplayValue(widget.restaurant.addressTc, widget.restaurant.addressEn)
        : _getDisplayValue(widget.restaurant.addressEn, widget.restaurant.addressTc);
    final district = widget.isTraditionalChinese
        ? _getDisplayValue(widget.restaurant.districtTc, widget.restaurant.districtEn)
        : _getDisplayValue(widget.restaurant.districtEn, widget.restaurant.districtTc);
    final keywords = widget.restaurant.getDisplayKeywords(widget.isTraditionalChinese);
    final distanceText = _getDistanceText();
    // Extract contact information
    final phone = widget.restaurant.contacts?['phone']?.toString();
    final email = widget.restaurant.contacts?['email']?.toString();
    final website = widget.restaurant.contacts?['website']?.toString();
    // Build list of available contact methods
    final contactMethods = <Widget>[];
    if (phone != null && phone.trim().isNotEmpty) {
      contactMethods.add(
        _buildContactTile(
          icon: Icons.phone,
          label: widget.isTraditionalChinese ? '電話' : 'Phone',
          value: phone,
          onTap: () => _makePhoneCall(phone),
        ),
      );
    }
    if (email != null && email.trim().isNotEmpty) {
      contactMethods.add(
        _buildContactTile(
          icon: Icons.email,
          label: widget.isTraditionalChinese ? '電郵' : 'Email',
          value: email,
          onTap: () => _sendEmail(email),
        ),
      );
    }
    if (website != null && website.trim().isNotEmpty) {
      contactMethods.add(
        _buildContactTile(
          icon: Icons.language,
          label: widget.isTraditionalChinese ? '網站' : 'Website',
          value: website,
          onTap: () => _openWebsite(website),
        ),
      );
    }

    return Scaffold(
      // Custom app bar with share button
      appBar: AppBar(
        title: Text(name),
        actions: [
          // Chat button for contacting restaurant
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: widget.isTraditionalChinese ? '聊天' : 'Chat',
            onPressed: _openChat,
          ),
          // Claim button (only shown if eligible)
          if (_canClaimRestaurant())
            IconButton(
              icon: _isClaiming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_business),
              tooltip: widget.isTraditionalChinese ? '認領餐廳' : 'Claim Restaurant',
              onPressed: _isClaiming ? null : _showClaimDialog,
            ),
          // Share button in app bar for easy access
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: widget.isTraditionalChinese ? '分享' : 'Share',
            onPressed: _shareRestaurant,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Restaurant Image
            ///
            /// Using CachedNetworkImage for better performance.
            /// Images are cached on device, so subsequent views are instant.
            CachedNetworkImage(
              imageUrl: widget.restaurant.imageUrl ?? '',
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 250,
                color: Colors.grey.shade300,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 250,
                color: Colors.grey.shade300,
                child: const Icon(Icons.restaurant, size: 64),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Restaurant Name and Distance Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (distanceText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distanceText,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  /// Basic Information - "田"-shaped Grid (2x2)
                  ///
                  /// Displays restaurant name, address, district, and seats
                  /// in a clean grid layout for easy scanning.
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _buildGridTile(
                        icon: Icons.restaurant_menu,
                        label: widget.isTraditionalChinese ? '餐廳名稱' : 'Name',
                        value: name,
                      ),
                      _buildGridTile(
                        icon: Icons.location_on,
                        label: widget.isTraditionalChinese ? '地址' : 'Address',
                        value: address,
                        onTap: _openInMaps,
                      ),
                      _buildGridTile(
                        icon: Icons.map,
                        label: widget.isTraditionalChinese ? '地區' : 'District',
                        value: district,
                      ),
                      _buildGridTile(
                        icon: Icons.event_seat,
                        label: widget.isTraditionalChinese ? '座位數量' : 'Seats',
                        value: widget.restaurant.seats?.toString() ??
                            (widget.isTraditionalChinese ? '未提供' : 'Not provided'),
                      ),
                    ],
                  ),
                  /// Contact Information - "田"-shaped Grid
                  ///
                  /// Displays available contact methods in a grid.
                  /// Only shows non-empty contact information.
                  /// Uses 2 columns if 2 or 4 items, 3 columns if 3 items.
                  if (contactMethods.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      widget.isTraditionalChinese ? '聯絡方式' : 'Contact Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: contactMethods.length == 3 ? 3 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: contactMethods.length == 3 ? 0.9 : 1.1,
                      children: contactMethods,
                    ),
                  ],
                  /// Keywords Section
                  ///
                  /// Displays restaurant features as chips between
                  /// contacts and map for better visual flow.
                  if (keywords.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      widget.isTraditionalChinese ? '特色' : 'Features',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: keywords
                          .map((keyword) => Chip(
                        label: Text(keyword),
                        backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ))
                          .toList(),
                    ),
                  ],
                  /// Map Section
                  ///
                  /// Interactive map with controls for viewing restaurant location.
                  if (widget.restaurant.latitude != null &&
                      widget.restaurant.longitude != null) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isTraditionalChinese ? '地圖' : 'Map',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            // Map type toggle
                            IconButton(
                              icon: const Icon(Icons.layers),
                              tooltip: widget.isTraditionalChinese ? '切換地圖類型' : 'Change map type',
                              onPressed: _toggleMapType,
                            ),
                            // Centre on restaurant
                            IconButton(
                              icon: const Icon(Icons.my_location),
                              tooltip: widget.isTraditionalChinese ? '定位餐廳' : 'Centre on restaurant',
                              onPressed: _centerOnRestaurant,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 300,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  widget.restaurant.latitude!,
                                  widget.restaurant.longitude!,
                                ),
                                zoom: 15,
                              ),
                              mapType: _currentMapType,
                              markers: {
                                Marker(
                                  markerId: MarkerId(widget.restaurant.id),
                                  position: LatLng(
                                    widget.restaurant.latitude!,
                                    widget.restaurant.longitude!,
                                  ),
                                  infoWindow: InfoWindow(
                                    title: name,
                                    snippet: address,
                                  ),
                                ),
                              },
                              onMapCreated: (controller) => _mapController = controller,
                              myLocationButtonEnabled: false,
                              myLocationEnabled: true,
                              zoomControlsEnabled: false,
                              compassEnabled: true,
                              mapToolbarEnabled: false,
                              minMaxZoomPreference: const MinMaxZoomPreference(12, 20),
                            ),
                            // Custom zoom controls
                            Positioned(
                              right: 16,
                              bottom: 80,
                              child: Column(
                                children: [
                                  FloatingActionButton.small(
                                    heroTag: 'zoom_in',
                                    onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                                    child: const Icon(Icons.add),
                                  ),
                                  const SizedBox(height: 8),
                                  FloatingActionButton.small(
                                    heroTag: 'zoom_out',
                                    onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                                    child: const Icon(Icons.remove),
                                  ),
                                ],
                              ),
                            ),
                            // Open in maps button
                            Positioned(
                              left: 16,
                              bottom: 16,
                              child: ElevatedButton.icon(
                                onPressed: _openInMaps,
                                icon: const Icon(Icons.map, size: 18),
                                label: Text(
                                  widget.isTraditionalChinese ? '在地圖中打開' : 'Open in Maps',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      /// Floating Book Button
      ///
      /// Prominent call-to-action button for booking.
      /// Positioned at bottom for thumb-friendly access.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isBooking ? null : _showBookingDialog,
        icon: _isBooking
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.calendar_today),
        label: Text(
          widget.isTraditionalChinese ? '預訂' : 'Book',
        ),
      ),
    );
  }
}