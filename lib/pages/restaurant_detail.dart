import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../services/menu_service.dart';
import '../services/chat_service.dart';
import '../models.dart';
import 'chat_page.dart';
import '../widgets/reviews/review_stats.dart';
import '../widgets/reviews/review_list.dart';
import '../widgets/reviews/review_form.dart';
import '../widgets/menu/menu_item_card.dart';
import '../widgets/menu/menu_list.dart';
import '../widgets/menu/menu_item_form.dart';
import '../widgets/ai/gemini_chat_button.dart';
import '../widgets/restaurant_detail/hero_image_section.dart';
import '../widgets/restaurant_detail/restaurant_info_card.dart';
import '../widgets/restaurant_detail/contact_actions.dart';
import '../widgets/restaurant_detail/opening_hours_card.dart';

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

  /// Start a chat with the restaurant
  ///
  /// Creates or opens a direct chat room with the restaurant
  Future<void> _startChatWithRestaurant() async {
    final authService = context.read<AuthService>();
    final chatService = context.read<ChatService>();

    // Check if user is logged in
    if (!authService.isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese ? '請先登入以使用聊天功能' : 'Please log in to use chat',
            ),
          ),
        );
      }
      return;
    }

    // Connect to socket if not connected
    if (!chatService.isConnected && authService.currentUser != null) {
      await chatService.connect(authService.currentUser!.uid);
    }

    // For now, create a chat room with restaurant ID as participant
    // In a real app, you would have a restaurant owner user ID
    final restaurantUserId = 'restaurant_${widget.restaurant.id}';
    final currentUserId = authService.currentUser!.uid;

    // Try to find existing room or create new one
    String? roomId;
    final existingRooms = chatService.rooms.where((room) =>
        room.type == 'direct' &&
        room.participants.contains(restaurantUserId) &&
        room.participants.contains(currentUserId)).toList();

    if (existingRooms.isNotEmpty) {
      roomId = existingRooms.first.roomId;
    } else {
      // Create new room
      roomId = await chatService.createChatRoom(
        [currentUserId, restaurantUserId],
        roomName: widget.isTraditionalChinese
            ? widget.restaurant.nameTc ?? widget.restaurant.nameEn
            : widget.restaurant.nameEn ?? widget.restaurant.nameTc,
      );
    }

    if (roomId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            roomId: roomId!,
            isTraditionalChinese: widget.isTraditionalChinese,
          ),
        ),
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
      // Custom app bar with share and chat buttons
      appBar: AppBar(
        title: Text(name),
        actions: [
          // AI Assistant button
          GeminiChatIconButton(
            isTraditionalChinese: widget.isTraditionalChinese,
            restaurantName: name,
            restaurantCuisine: widget.restaurant.keywordEn?.join(', '),
            restaurantDistrict: widget.restaurant.districtEn,
          ),
          // Chat button
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: widget.isTraditionalChinese ? '聊天' : 'Chat',
            onPressed: _startChatWithRestaurant,
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
            /// Hero Image Section with overlay
            HeroImageSection(
              imageUrl: widget.restaurant.imageUrl,
              distanceText: distanceText,
              isTraditionalChinese: widget.isTraditionalChinese,
            ),

            const SizedBox(height: 16),

            /// Restaurant Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Consumer<ReviewService>(
                builder: (context, reviewService, child) {
                  return FutureBuilder<ReviewStats?>(
                    future: reviewService.getReviewStats(widget.restaurant.id),
                    builder: (context, snapshot) {
                      return RestaurantInfoCard(
                        restaurant: widget.restaurant,
                        name: name,
                        address: address,
                        district: district,
                        keywords: keywords,
                        isTraditionalChinese: widget.isTraditionalChinese,
                        onAddressTap: _openInMaps,
                        reviewStats: snapshot.data,
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            /// Contact Actions
            ContactActions(
              contacts: widget.restaurant.contacts,
              isTraditionalChinese: widget.isTraditionalChinese,
              onPhonePressed: _makePhoneCall,
              onEmailPressed: _sendEmail,
              onWebsitePressed: _openWebsite,
            ),

            const SizedBox(height: 16),

            /// Opening Hours Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: OpeningHoursCard(
                openingHours: widget.restaurant.openingHours,
                isTraditionalChinese: widget.isTraditionalChinese,
              ),
            ),

            const SizedBox(height: 16),

            /// Map Section - Google Maps integration
            if (widget.restaurant.latitude != null &&
                widget.restaurant.longitude != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
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
                ),
            ],

            const SizedBox(height: 16),

            /// Menu Section - Restaurant menu items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Consumer<MenuService>(
                    builder: (context, menuService, child) {
                      return FutureBuilder<List<MenuItem>>(
                        future: menuService.getMenuItems(widget.restaurant.id),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      widget.isTraditionalChinese ? '菜單' : 'Menu',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Navigate to full menu page
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => _MenuPage(
                                              restaurantId: widget.restaurant.id,
                                              restaurantName: name,
                                              isTraditionalChinese: widget.isTraditionalChinese,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(widget.isTraditionalChinese ? '查看全部' : 'View All'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Show first 3 menu items as preview
                                ...snapshot.data!.take(3).map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: MenuItemCard(item: item),
                                )),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ),

            const SizedBox(height: 16),

            /// Reviews Section - Restaurant reviews and ratings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Consumer<ReviewService>(
                builder: (context, reviewService, child) {
                  return FutureBuilder<ReviewStats?>(
                    future: reviewService.getReviewStats(widget.restaurant.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.isTraditionalChinese ? '評價' : 'Reviews',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Navigate to full reviews page
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => _ReviewsPage(
                                          restaurantId: widget.restaurant.id,
                                          restaurantName: name,
                                          isTraditionalChinese: widget.isTraditionalChinese,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    widget.isTraditionalChinese ? '查看全部' : 'View All',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ReviewStatsWidget(
                              stats: snapshot.data!,
                              onTap: () {
                                // Navigate to full reviews page
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => _ReviewsPage(
                                      restaurantId: widget.restaurant.id,
                                      restaurantName: name,
                                      isTraditionalChinese: widget.isTraditionalChinese,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
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

/// Reviews Page
///
/// Full-screen page for viewing and managing reviews.
class _ReviewsPage extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final bool isTraditionalChinese;

  const _ReviewsPage({
    required this.restaurantId,
    required this.restaurantName,
    required this.isTraditionalChinese,
  });

  Future<void> _showAddReviewForm(BuildContext context) async {
    final authService = context.read<AuthService>();
    final reviewService = context.read<ReviewService>();

    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTraditionalChinese ? '請先登入以撰寫評價' : 'Please sign in to write a review',
          ),
          action: SnackBarAction(
            label: isTraditionalChinese ? '登入' : 'Sign In',
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ),
      );
      return;
    }

    await showReviewForm(
      context: context,
      restaurantId: restaurantId,
      isTraditionalChinese: isTraditionalChinese,
      onSubmit: (rating, comment, imageUrl) async {
        final request = CreateReviewRequest(
          restaurantId: restaurantId,
          rating: rating,
          comment: comment,
          imageUrl: imageUrl,
          dateTime: DateTime.now().toIso8601String(),
        );

        final reviewId = await reviewService.createReview(request);

        if (context.mounted) {
          if (reviewId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isTraditionalChinese ? '評價已提交' : 'Review submitted successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh stats
            await reviewService.getReviewStats(restaurantId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${isTraditionalChinese ? '提交失敗' : 'Failed to submit review'}: ${reviewService.error}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTraditionalChinese ? '評價' : 'Reviews',
        ),
      ),
      body: Column(
        children: [
          // Review stats at the top
          Consumer<ReviewService>(
            builder: (context, reviewService, child) {
              return FutureBuilder(
                future: reviewService.getReviewStats(restaurantId),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return ReviewStatsWidget(stats: snapshot.data!);
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
          const Divider(),
          // Reviews list
          Expanded(
            child: ReviewList(restaurantId: restaurantId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReviewForm(context),
        icon: const Icon(Icons.rate_review),
        label: Text(
          isTraditionalChinese ? '撰寫評價' : 'Write Review',
        ),
      ),
    );
  }
}

/// Menu Page
///
/// Full-screen page for viewing restaurant menu.
class _MenuPage extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final bool isTraditionalChinese;

  const _MenuPage({
    required this.restaurantId,
    required this.restaurantName,
    required this.isTraditionalChinese,
  });

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final isOwner = false; // TODO: Implement owner check based on user type

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTraditionalChinese ? '菜單' : 'Menu',
        ),
      ),
      body: MenuList(
        restaurantId: restaurantId,
        showActions: isOwner,
        onEdit: isOwner
            ? (item) {
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
            : null,
        onDelete: isOwner
            ? (item) async {
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
                        child: Text(isTraditionalChinese ? '刪除' : 'Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
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
            : null,
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => MenuItemForm(
                    restaurantId: restaurantId,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(
                isTraditionalChinese ? '新增項目' : 'Add Item',
              ),
            )
          : null,
    );
  }
}