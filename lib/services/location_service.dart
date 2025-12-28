import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Location Service - GPS Functionality
/// 
/// This service manages device location access and provides distance calculations.
/// It handles the complex permission flow required for accessing user location,
/// which is one of the most sensitive permissions on mobile devices.
/// 
/// Why location permissions are complex:
/// - Android requires explicit user consent before accessing location
/// - Users can grant "while using" or "always" permissions
/// - Users can revoke permissions at any time
/// - Apps must handle permission denial gracefully
/// 
/// Battery considerations:
/// - GPS is battery-intensive, so we don't constantly track location
/// - We fetch location only when needed (e.g., when user opens app or refreshes)
/// - We cache the last known position to reduce GPS usage
class LocationService with ChangeNotifier {
  // Current user position - null if not yet fetched or permission denied
  Position? _currentPosition;
  // Loading state for UI feedback
  bool _isLoading = false;
  // Error message for permission denial or location errors
  String? _errorMessage;
  // Permission status tracking
  bool _hasPermission = false;

  // GETTERS
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPermission => _hasPermission;
  
  /// Get current latitude (convenience getter)
  double? get latitude => _currentPosition?.latitude;
  /// Get current longitude (convenience getter)
  double? get longitude => _currentPosition?.longitude;

  /// Check if location services are enabled on device
  /// 
  /// This is different from permissions. The device itself might have
  /// location services turned off in settings, which we need to detect.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permissions
  /// 
  /// This method handles the complete permission flow:
  /// 1. Check if we already have permission
  /// 2. If not, request it from the user
  /// 3. Handle the user's response (granted/denied/permanently denied)
  /// 
  /// Permission states explained:
  /// - granted: User allowed access, we can proceed
  /// - denied: User rejected this time, we can ask again later
  /// - permanentlyDenied: User rejected and checked "don't ask again"
  ///   In this case, we must direct user to system settings
  Future<bool> checkAndRequestPermission() async {
    try {
      // First check if location services are enabled on device
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled. Please enable location in your device settings.';
        _hasPermission = false;
        notifyListeners();
        return false;
      }

      // Check current permission status
      ph.PermissionStatus status = await ph.Permission.location.status;
      
      if (status.isGranted) {
        // We already have permission, proceed
        _hasPermission = true;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      if (status.isDenied) {
        // Permission denied but we can ask again
        // Request permission from user
        status = await ph.Permission.location.request();
        
        if (status.isGranted) {
          _hasPermission = true;
          _errorMessage = null;
          notifyListeners();
          return true;
        } else {
          _hasPermission = false;
          _errorMessage = 'Location permission denied. Grant permission to see nearby restaurants.';
          notifyListeners();
          return false;
        }
      }

      if (status.isPermanentlyDenied) {
        // User has permanently denied permission
        // We need to direct them to app settings
        _hasPermission = false;
        _errorMessage = 'Location permission permanently denied. Please enable it in app settings.';
        notifyListeners();
        return false;
      }

      // Unknown permission state
      _hasPermission = false;
      _errorMessage = 'Unable to determine location permission status.';
      notifyListeners();
      return false;

    } catch (e) {
      _errorMessage = 'Error checking location permission: $e';
      _hasPermission = false;
      notifyListeners();
      return false;
    }
  }

  /// Get current device position
  /// 
  /// This is the main method to fetch GPS coordinates. It includes:
  /// - Permission checking
  /// - Location service verification
  /// - Timeout handling (GPS can take time to acquire fix)
  /// - Accuracy settings
  /// 
  /// LocationSettings explained:
  /// - accuracy: How precise the location should be
  ///   * low: ~10km, uses cell towers, very battery efficient
  ///   * medium: ~100m, uses WiFi + cell towers, balanced
  ///   * high: ~10m, uses GPS, battery intensive but accurate
  ///   * best: ~1m, continuous GPS, very battery intensive
  /// 
  /// For restaurant search, 'high' accuracy is appropriate because:
  /// - We need accuracy within city blocks (~10-50m)
  /// - Users expect to see genuinely nearby restaurants
  /// - We only fetch position occasionally, not continuously
  Future<Position?> getCurrentPosition() async {
    try {
      _setLoading(true);

      // Verify we have permission
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        _setLoading(false);
        return null;
      }

      // Configure location settings for optimal balance of accuracy and battery
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Minimum distance (in metres) device must move before update
        timeLimit: Duration(seconds: 20), // Maximum time to wait for location
      );

      // Get current position
      // This might take a few seconds as GPS satellites are acquired
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      _currentPosition = position;
      _errorMessage = null;
      _setLoading(false);
      // notifyListeners is called in _setLoading
      if (kDebugMode)     print('LocationService: Position acquired - Lat: ${position.latitude}, Lng: ${position.longitude}');
      return position;
    } catch (e) {
      _errorMessage = 'Failed to get current location: $e';
      _setLoading(false);
      if (kDebugMode) print('LocationService: Error getting position - $e');
      return null;
    }
  }

  /// Calculate distance between two points
  /// 
  /// This uses the Haversine formula, which calculates the great-circle
  /// distance between two points on a sphere (Earth). It accounts for
  /// Earth's curvature, making it accurate for any distance.
  /// 
  /// Parameters:
  /// - lat1, lon1: First point (usually user's location)
  /// - lat2, lon2: Second point (restaurant location)
  /// 
  /// Returns: Distance in metres
  /// 
  /// Why we calculate distance client-side:
  /// - Algolia search doesn't include distance in results
  /// - We want to show "X km away" to help users decide
  /// - Calculating on device is fast and doesn't require extra API calls
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Calculate distance from current position to a point
  /// 
  /// Convenience method that uses the cached current position.
  /// Returns null if current position isn't available.
  double? calculateDistanceFromCurrent(double latitude, double longitude) {
    if (_currentPosition == null) {
      return null;
    }
    
    return calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  /// Format distance for display
  /// 
  /// Converts metres to a human-readable string:
  /// - Less than 1km: Show in metres (e.g., "250m")
  /// - 1km or more: Show in kilometres with 1 decimal (e.g., "2.5km")
  /// 
  /// This follows common convention in mapping apps like Google Maps.
  String formatDistance(double distanceInMetres) {
    if (distanceInMetres < 1000) {
      return '${distanceInMetres.round()}m';
    } else {
      return '${(distanceInMetres / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Open app settings
  /// 
  /// When permission is permanently denied, we need to direct users
  /// to their device's app settings where they can manually enable it.
  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }

  /// Clear cached position
  /// 
  /// Useful when you want to force a fresh location fetch,
  /// for example after user manually refreshes the page.
  void clearPosition() {
    _currentPosition = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }
}