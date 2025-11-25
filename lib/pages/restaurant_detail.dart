import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/restaurant_service.dart';
import '../services/location_service.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import '../models.dart';

/// Restaurant Detail Page - Native Android Integration
/// 
/// This page demonstrates multiple native Android features working together:
/// - Google Maps integration for location display
/// - Share functionality using Android's share sheet
/// - URL launching for phone/email/maps
/// - Date/time picker for bookings
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
  bool _showMapControls = true;

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
      final name = widget.restaurant.getDisplayName(widget.isTraditionalChinese);
      final address = widget.restaurant.getDisplayAddress(widget.isTraditionalChinese);
      
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
    final name = widget.restaurant.getDisplayName(widget.isTraditionalChinese);
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
          title: Text( widget.isTraditionalChinese ? '預訂餐桌' : 'Book a Table', ),
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
                          _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
                      onPressed: _numberOfGuests > 1 ? () => setState(() => _numberOfGuests--) : null,
                    ),
                    Text('$_numberOfGuests', style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _numberOfGuests < 20 ? () => setState(() => _numberOfGuests++) : null,
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
              onPressed: _selectedDateTime == null ? null : () {
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
      // Step 1: Create booking in Firestore
      final booking = await bookingService.createBooking(
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.getDisplayName(widget.isTraditionalChinese),
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

  // Toggle map type between normal, satellite, and terrain
  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : _currentMapType == MapType.satellite
          ? MapType.terrain
          : MapType.normal;
    });
  }

  // Animate camera to restaurant location
  void _centerOnRestaurant() {
    if (_mapController != null && widget.restaurant.latitude != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.restaurant.latitude!, widget.restaurant.longitude!),
            zoom: 16,
          ),
        ),
      );
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {VoidCallback? onTap, IconData? actionIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (actionIcon != null) Icon(actionIcon, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.restaurant.getDisplayName(widget.isTraditionalChinese);
    final nameEn = widget.restaurant.nameEn ?? name;
    final nameTc = widget.restaurant.nameTc ?? name;
    final address = widget.restaurant.getDisplayAddress(widget.isTraditionalChinese);
    final addressEn = widget.restaurant.addressEn ?? address;
    final addressTc = widget.restaurant.addressTc ?? address;
    final district = widget.restaurant.getDisplayDistrict(widget.isTraditionalChinese);
    final districtEn = widget.restaurant.districtEn ?? district;
    final districtTc = widget.restaurant.districtTc ?? district;
    final keywords = widget.restaurant.getDisplayKeywords(widget.isTraditionalChinese);
    final distanceText = _getDistanceText();

    return Scaffold(
      // Custom app bar with share button
      appBar: AppBar(
        title: Text(name),
        actions: [
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
                  /// Restaurant Distance
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
                  const SizedBox(height: 16),
                  /// Restaurant name
                  _buildInfoCard(
                    icon: Icons.store,
                    title: widget.isTraditionalChinese ? '餐廳資料' : 'Restaurant Info',
                    children: [
                      _buildInfoRow(
                        widget.isTraditionalChinese ? '英文名稱' : 'English Name',
                        nameEn,
                      ),
                      _buildInfoRow(
                        widget.isTraditionalChinese ? '中文名稱' : 'Chinese Name',
                        nameTc,
                      ),
                      if (widget.restaurant.seats != null)
                        _buildInfoRow(
                          widget.isTraditionalChinese ? '座位數量' : 'Seats',
                          widget.restaurant.seats.toString(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  /// Address with tap-to-navigate
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: widget.isTraditionalChinese ? '地址資訊' : 'Location',
                    children: [
                      _buildInfoRow(
                        widget.isTraditionalChinese ? '英文地址' : 'English Address',
                        addressEn,
                        onTap: _openInMaps,
                        actionIcon: Icons.map,
                      ),
                      _buildInfoRow(
                        widget.isTraditionalChinese ? '中文地址' : 'Chinese Address',
                        addressTc,
                        onTap: _openInMaps,
                        actionIcon: Icons.map,
                      ),
                      _buildInfoRow(
                        widget.isTraditionalChinese ? '英文地區' : 'District (EN)',
                        districtEn,
                      ),
                      _buildInfoRow(
                        widget.isTraditionalChinese ? '中文地區' : 'District (TC)',
                        districtTc,
                      ),
                      if (widget.restaurant.latitude != null && widget.restaurant.longitude != null)
                        _buildInfoRow(
                          widget.isTraditionalChinese ? '座標' : 'Coordinates',
                          '${widget.restaurant.latitude!.toStringAsFixed(6)}, ${widget.restaurant.longitude!.toStringAsFixed(6)}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  /// Contact Information
                  /// 
                  /// Each contact method is tappable and opens the
                  /// appropriate native app. This is exactly how users
                  /// expect contact info to work on Android.
                  if (widget.restaurant.contacts != null && widget.restaurant.contacts!.isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.contact_phone,
                      title: widget.isTraditionalChinese ? '聯絡方式' : 'Contact',
                      children: [
                        if (widget.restaurant.contacts!['phone'] != null)
                          _buildInfoRow(
                            widget.isTraditionalChinese ? '電話' : 'Phone',
                            widget.restaurant.contacts!['phone'].toString(),
                            onTap: () => _makePhoneCall(widget.restaurant.contacts!['phone'].toString()),
                            actionIcon: Icons.phone,
                          ),
                        if (widget.restaurant.contacts!['email'] != null)
                          _buildInfoRow(
                            widget.isTraditionalChinese ? '電郵' : 'Email',
                            widget.restaurant.contacts!['email'].toString(),
                            onTap: () => _sendEmail(widget.restaurant.contacts!['email'].toString()),
                            actionIcon: Icons.email,
                          ),
                        if (widget.restaurant.contacts!['website'] != null)
                          _buildInfoRow(
                            widget.isTraditionalChinese ? '網站' : 'Website',
                            widget.restaurant.contacts!['website'].toString(),
                            onTap: () => _openWebsite(widget.restaurant.contacts!['website'].toString()),
                            actionIcon: Icons.language,
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  /// Keywords
                  if (keywords.isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.local_offer,
                      title: widget.isTraditionalChinese ? '特色' : 'Features',
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: keywords
                              .map((keyword) => Chip(label: Text(keyword)))
                              .toList(),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  /// Map
                  if (widget.restaurant.latitude != null && widget.restaurant.longitude != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.isTraditionalChinese ? '地圖' : 'Map',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(widget.restaurant.latitude!, widget.restaurant.longitude!),
                                zoom: 15,
                              ),
                              mapType: _currentMapType,
                              markers: {
                                Marker(
                                  markerId: MarkerId(widget.restaurant.id),
                                  position: LatLng(widget.restaurant.latitude!, widget.restaurant.longitude!),
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