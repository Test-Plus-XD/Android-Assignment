import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/review_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/menu_service.dart';
import '../widgets/reviews/star_rating.dart';
import '../widgets/restaurant/contact_info_card.dart';
import '../widgets/restaurant/interactive_map_preview.dart';
import '../widgets/restaurant/menu_preview_section.dart';
import '../widgets/restaurant/reviews_carousel.dart';
import '../widgets/restaurant/restaurant_header.dart';
import '../widgets/restaurant/action_buttons_row.dart';
import '../widgets/restaurant/opening_hours_list.dart';
import '../widgets/restaurant/claim_restaurant_button.dart';
import '../widgets/booking/booking_dialog.dart';
import '../pages/chat_room_page.dart';
import '../pages/restaurant_reviews_page.dart';
import '../pages/restaurant_menu_page.dart';
import '../pages/gemini_page.dart';

/// Restaurant Detail Page
///
/// This is the most complex page in the app, showing all information for a
/// specific restaurant. It demonstrates:
/// - Advanced Layout (SliverAppBar with background image)
/// - Integration of multiple services (Booking, Review, Location, Chat)
/// - Interactive map integration
/// - Dynamic UI based on authentication and user role
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
  GoogleMapController? _mapController;
  // Review data
  Future<ReviewStats?>? _reviewStatsFuture;
  Future<List<Review>>? _reviewsFuture;
  // Menu data
  Future<List<MenuItem>>? _menuItemsFuture;
  // Map type for satellite toggle
  MapType _mapType = MapType.normal;
  // Track scroll position for AppBar actions
  bool _isCollapsed = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load data after build completes to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Detect when hero image is collapsed (after scrolling ~180 pixels)
    final isCollapsed = _scrollController.hasClients && _scrollController.offset > 180;
    if (isCollapsed != _isCollapsed) {
      setState(() => _isCollapsed = isCollapsed);
    }
  }

  /// Load all data for the page
  void _loadData() {
    final reviewService = context.read<ReviewService>();
    final menuService = context.read<MenuService>();
    setState(() {
      _reviewStatsFuture = reviewService.getReviewStats(widget.restaurant.id);
      _reviewsFuture = reviewService.getReviews(restaurantId: widget.restaurant.id);
      _menuItemsFuture = menuService.getMenuItems(widget.restaurant.id);
    });
  }

  /// Check if restaurant is currently open
  bool _isRestaurantOpen() {
    if (widget.restaurant.openingHours == null || widget.restaurant.openingHours!.isEmpty) {
      return false;
    }
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    final todayHours = widget.restaurant.openingHours![dayName];
    if (todayHours == null || todayHours.toString().toLowerCase() == 'closed') {
      return false;
    }
    // Try to parse opening hours (format: "11:00 - 21:00" or "11:00-21:00")
    final hoursStr = todayHours.toString();
    final timeParts = hoursStr.split(RegExp(r'\s*-\s*'));
    if (timeParts.length != 2) return true;
    try {
      final openTime = _parseTime(timeParts[0].trim());
      final closeTime = _parseTime(timeParts[1].trim());
      final currentMinutes = now.hour * 60 + now.minute;
      return currentMinutes >= openTime && currentMinutes <= closeTime;
    } catch (e) {
      return true;
    }
  }

  int _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Check if contact info has any data
  bool _hasContactInfo() {
    final contacts = widget.restaurant.contacts;
    if (contacts == null) return false;
    return (contacts['Phone'] != null && contacts['Phone'].toString().isNotEmpty) ||
        (contacts['Email'] != null && contacts['Email'].toString().isNotEmpty) ||
        (contacts['Website'] != null && contacts['Website'].toString().isNotEmpty);
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
    return widget.isTraditionalChinese ? '尚未提供' : 'Not provided';
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

  /// Open email app
  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isTraditionalChinese ? '無法打開郵件應用' : 'Could not open email app')),
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
  /// Creates or joins a chat room with ID format: restaurant-{restaurantId}
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

    // Use ensureConnected for lazy initialisation
    // This connects to Socket.IO only when the user actually needs chat
    await chatService.ensureConnected();

    // Create room ID in format: restaurant-{restaurantId}
    final roomId = 'restaurant-${widget.restaurant.id}';
    final currentUserId = authService.currentUser!.uid;

    try {
      // Try to join existing room or create new one
      final room = await chatService.getChatRoom(roomId);
      
      if (room == null) {
        // Room doesn't exist, create it
        final restaurantName = widget.isTraditionalChinese
            ? widget.restaurant.nameTc ?? widget.restaurant.nameEn
            : widget.restaurant.nameEn ?? widget.restaurant.nameTc;
            
        final createdRoomId = await chatService.createChatRoom(
          [currentUserId], // Start with current user, restaurant owner can join later
          roomName: restaurantName,
          roomId: roomId, // Use specific room ID format
        );
        
        if (createdRoomId == null) {
          throw Exception('Failed to create chat room');
        }
      } else {
        // Room exists, join it
        await chatService.joinRoom(roomId);
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              roomId: roomId,
              isTraditionalChinese: widget.isTraditionalChinese,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese
                ? '無法開始聊天：$e'
                : 'Failed to start chat: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Open Gemini AI chat for this restaurant (accessible to guests)
  void _openGeminiChat() {
    final restaurantName = widget.isTraditionalChinese
        ? widget.restaurant.nameTc ?? widget.restaurant.nameEn
        : widget.restaurant.nameEn ?? widget.restaurant.nameTc;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GeminiChatRoomPage(
          isTraditionalChinese: widget.isTraditionalChinese,
          restaurantName: restaurantName,
          restaurantId: widget.restaurant.id,
          restaurantCuisine: (widget.isTraditionalChinese ? widget.restaurant.keywordTc : widget.restaurant.keywordEn)?.isNotEmpty == true
              ? (widget.isTraditionalChinese ? widget.restaurant.keywordTc!.first : widget.restaurant.keywordEn!.first)
              : null,
          restaurantDistrict: widget.isTraditionalChinese ? widget.restaurant.districtTc : widget.restaurant.districtEn,
        ),
      ),
    );
  }

  /// Show booking dialog
  Future<void> _showBookingDialog() async {
    await showDialog(
      context: context,
      builder: (context) => BookingDialog(
        restaurant: widget.restaurant,
        isTraditionalChinese: widget.isTraditionalChinese,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final userService = context.watch<UserService>();
    final isOwner = authService.isLoggedIn && widget.restaurant.ownerId == authService.currentUser!.uid;
    final userType = userService.currentProfile?.type;
    final isDiner = authService.isLoggedIn && userType == 'Diner';

    // Get primary name and address for display
    final restaurantName = widget.isTraditionalChinese
        ? (widget.restaurant.nameTc ?? widget.restaurant.nameEn ?? '')
        : (widget.restaurant.nameEn ?? widget.restaurant.nameTc ?? '');
    final restaurantAddress = widget.isTraditionalChinese
        ? (widget.restaurant.addressTc ?? widget.restaurant.addressEn ?? '')
        : (widget.restaurant.addressEn ?? widget.restaurant.addressTc ?? '');

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Collapsible Header with Image
          // The image collapses into a regular AppBar as user scrolls
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Restaurant Image with placeholder
                  Image.network(
                    widget.restaurant.imageUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.restaurant, size: 80, color: Colors.grey[400]),
                    ),
                  ),
                  // Gradient overlay to make text readable on any image
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Show chat buttons in AppBar when hero is collapsed
              if (_isCollapsed) ...[
                // Gemini AI chat (accessible to everyone including guests)
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: _openGeminiChat,
                  tooltip: widget.isTraditionalChinese ? 'AI 助手' : 'AI Assistant',
                ),
                // Socket chat (requires login)
                if (authService.isLoggedIn)
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: _startChatWithRestaurant,
                    tooltip: widget.isTraditionalChinese ? '聊天' : 'Chat',
                  ),
              ],
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareRestaurant,
                tooltip: widget.isTraditionalChinese ? '分享' : 'Share',
              ),
            ],
          ),

          // Main Content Area
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Header (Name, Rating, Distance)
                  FutureBuilder<ReviewStats?>(
                    future: _reviewStatsFuture,
                    builder: (context, snapshot) {
                      return RestaurantHeader(
                        restaurantName: restaurantName,
                        reviewStats: snapshot.data,
                        distanceText: _getDistanceText(),
                        isTraditionalChinese: widget.isTraditionalChinese,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons (Call, Chat, AI, Map, Website)
                  ActionButtonsRow(
                    isTraditionalChinese: widget.isTraditionalChinese,
                    isLoggedIn: authService.isLoggedIn,
                    phoneNumber: widget.restaurant.contacts?['Phone'],
                    website: widget.restaurant.contacts?['Website'],
                    onCall: () => _makePhoneCall(widget.restaurant.contacts!['Phone']),
                    onChat: _startChatWithRestaurant,
                    onAI: _openGeminiChat,
                    onDirections: _openInMaps,
                    onWebsite: () => _openWebsite(widget.restaurant.contacts!['Website']),
                  ),

                  const SizedBox(height: 24),

                  // Claim Restaurant Button (for Restaurant-type users)
                  ClaimRestaurantButton(
                    restaurantId: widget.restaurant.id,
                    restaurantOwnerId: widget.restaurant.ownerId,
                    isTraditionalChinese: widget.isTraditionalChinese,
                    onClaimed: () {
                      // Refresh the page data after claiming
                      setState(() {
                        _loadData();
                      });
                    },
                  ),

                  const Divider(height: 48),

                  // Contact Info Section (above Address, only if data exists)
                  if (_hasContactInfo()) ...[
                    Text(
                      widget.isTraditionalChinese ? '聯絡方式' : 'Contact',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ContactInfoCard(
                      contacts: widget.restaurant.contacts!,
                      isTraditionalChinese: widget.isTraditionalChinese,
                      onPhoneCall: _makePhoneCall,
                      onSendEmail: _sendEmail,
                      onOpenWebsite: _openWebsite,
                    ),
                    const Divider(height: 48),
                  ],

                  // Address Section
                  Text(
                    widget.isTraditionalChinese ? '地址' : 'Address',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _openInMaps,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(restaurantAddress, style: theme.textTheme.bodyLarge),
                              const SizedBox(height: 4),
                              Text(
                                widget.isTraditionalChinese ? '查看地圖' : 'View on map',
                                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Interactive Map Preview with zoom and satellite toggle
                  if (widget.restaurant.latitude != null && widget.restaurant.longitude != null)
                    InteractiveMapPreview(
                      latitude: widget.restaurant.latitude!,
                      longitude: widget.restaurant.longitude!,
                      restaurantName: restaurantName,
                      mapType: _mapType,
                      onMapTypeChanged: (type) => setState(() => _mapType = type),
                      onMapCreated: (controller) => _mapController = controller,
                      isTraditionalChinese: widget.isTraditionalChinese,
                    ),

                  const Divider(height: 48),

                  // Opening Hours Section with Open/Closed badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isTraditionalChinese ? '營業時間' : 'Opening Hours',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      // Open/Closed badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isRestaurantOpen()
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isRestaurantOpen() ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _isRestaurantOpen()
                              ? (widget.isTraditionalChinese ? '營業中' : 'Open')
                              : (widget.isTraditionalChinese ? '休息中' : 'Closed'),
                          style: TextStyle(
                            color: _isRestaurantOpen() ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OpeningHoursList(
                    hours: widget.restaurant.openingHours,
                    isTraditionalChinese: widget.isTraditionalChinese,
                  ),

                  const Divider(height: 48),

                  // Menu Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isTraditionalChinese ? '菜單' : 'Menu',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantMenuPage(
                                restaurantId: widget.restaurant.id,
                                restaurantName: restaurantName,
                                isTraditionalChinese: widget.isTraditionalChinese,
                              ),
                            ),
                          );
                        },
                        child: Text(widget.isTraditionalChinese ? '查看全部' : 'See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MenuPreviewSection(
                    menuItemsFuture: _menuItemsFuture,
                    isTraditionalChinese: widget.isTraditionalChinese,
                    onSeeAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantMenuPage(
                            restaurantId: widget.restaurant.id,
                            restaurantName: restaurantName,
                            isTraditionalChinese: widget.isTraditionalChinese,
                          ),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 48),

                  // Reviews Section Preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isTraditionalChinese ? '用戶評價' : 'User Reviews',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantReviewsPage(
                                restaurantId: widget.restaurant.id,
                                restaurantName: restaurantName,
                                isTraditionalChinese: widget.isTraditionalChinese,
                              ),
                            ),
                          );
                        },
                        child: Text(widget.isTraditionalChinese ? '查看全部' : 'See all'),
                      ),
                    ],
                  ),
                  // Review Stats Summary with stars
                  FutureBuilder<ReviewStats?>(
                    future: _reviewStatsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        if (kDebugMode) print('Error loading review stats: ${snapshot.error}');
                        // Don't show error to user, just show no reviews
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            widget.isTraditionalChinese ? '暫無評論' : 'No reviews yet',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        );
                      }
                      if (snapshot.hasData && snapshot.data != null) {
                        final stats = snapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                stats.averageRating.toStringAsFixed(1),
                                style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StarRating(rating: stats.averageRating, size: 20),
                                  Text(
                                    '${stats.totalReviews} ${widget.isTraditionalChinese ? '則評論' : 'reviews'}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          widget.isTraditionalChinese ? '暫無評論' : 'No reviews yet',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      );
                    },
                  ),
                  // Reviews Carousel
                  ReviewsCarousel(
                    reviewsFuture: _reviewsFuture,
                    isTraditionalChinese: widget.isTraditionalChinese,
                  ),
                  const SizedBox(height: 100), // Spacing for bottom button
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Booking Button - Only visible for logged-in Diner users
      bottomSheet: (isOwner || !isDiner)
      ? null // Owners and non-Diner users shouldn't see booking button
      : Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _showBookingDialog,
                    child: Text(
                      widget.isTraditionalChinese ? '立即預訂餐桌' : 'Book a Table',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}