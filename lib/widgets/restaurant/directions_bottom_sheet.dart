import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models.dart';
import '../../services/location_service.dart';

/// Transport mode for directions
enum _TransportMode {
  transit,
  walking,
  driving;

  IconData get icon => switch (this) {
        _TransportMode.transit => Icons.directions_transit,
        _TransportMode.walking => Icons.directions_walk,
        _TransportMode.driving => Icons.directions_car,
      };

  String label(bool isTC) => switch (this) {
        _TransportMode.transit => isTC ? '公共交通' : 'Transit',
        _TransportMode.walking => isTC ? '步行' : 'Walking',
        _TransportMode.driving => isTC ? '駕車' : 'Driving',
      };

  /// Average speed in km/h for time estimation
  double get speedKmh => switch (this) {
        _TransportMode.transit => 20.0,
        _TransportMode.walking => 5.0,
        _TransportMode.driving => 30.0,
      };

  /// Google Maps directions mode parameter
  String get googleMapsMode => switch (this) {
        _TransportMode.transit => 'transit',
        _TransportMode.walking => 'walking',
        _TransportMode.driving => 'driving',
      };
}

/// Directions Bottom Sheet
///
/// Shows a modal sheet with:
/// - Map displaying user location and restaurant with straight-line route
/// - Transport mode picker (transit/walking/driving)
/// - Estimated travel time and distance
/// - "Open in Google Maps" button for real turn-by-turn navigation
///
/// Mirrors the iOS DirectionsView using Google Maps Flutter.
class DirectionsBottomSheet extends StatefulWidget {
  final Restaurant restaurant;
  final bool isTraditionalChinese;

  const DirectionsBottomSheet({
    required this.restaurant,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<DirectionsBottomSheet> createState() => _DirectionsBottomSheetState();
}

class _DirectionsBottomSheetState extends State<DirectionsBottomSheet> {
  _TransportMode _selectedMode = _TransportMode.transit;
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Format travel time from minutes
  String _formatTravelTime(double minutes) {
    if (minutes < 1) return widget.isTraditionalChinese ? '< 1 分鐘' : '< 1 min';
    final hours = minutes ~/ 60;
    final mins = (minutes % 60).round();
    if (hours > 0 && mins > 0) {
      return widget.isTraditionalChinese
          ? '$hours 小時 $mins 分鐘'
          : '${hours}h ${mins}min';
    } else if (hours > 0) {
      return widget.isTraditionalChinese ? '$hours 小時' : '${hours}h';
    }
    return widget.isTraditionalChinese ? '$mins 分鐘' : '$mins min';
  }

  /// Open Google Maps for turn-by-turn directions
  Future<void> _openInGoogleMaps() async {
    final lat = widget.restaurant.latitude!;
    final lng = widget.restaurant.longitude!;
    final mode = _selectedMode.googleMapsMode;

    // Try native Google Maps navigation first
    final nativeUri = Uri.parse('google.navigation:q=$lat,$lng&mode=$mode');
    if (await canLaunchUrl(nativeUri)) {
      await launchUrl(nativeUri);
      return;
    }

    // Fallback to web URL
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=$mode',
    );
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isTraditionalChinese ? '無法打開地圖' : 'Could not open maps'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationService = context.read<LocationService>();
    final userPos = locationService.currentPosition;
    final restaurantLat = widget.restaurant.latitude!;
    final restaurantLng = widget.restaurant.longitude!;
    final restaurantName = widget.restaurant.getDisplayName(widget.isTraditionalChinese);

    // Calculate distance and estimated time
    double? distanceMetres;
    if (userPos != null) {
      distanceMetres = locationService.calculateDistanceFromCurrent(restaurantLat, restaurantLng);
    }

    final estimatedMinutes = distanceMetres != null
        ? (distanceMetres / 1000.0) / _selectedMode.speedKmh * 60.0
        : null;

    // Build polyline from user to restaurant
    final polylines = <Polyline>{};
    if (userPos != null) {
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(userPos.latitude, userPos.longitude),
          LatLng(restaurantLat, restaurantLng),
        ],
        color: theme.colorScheme.primary,
        width: 5,
      ));
    }

    // Camera position: fit both points or just restaurant
    final initialTarget = userPos != null
        ? LatLng(
            (userPos.latitude + restaurantLat) / 2,
            (userPos.longitude + restaurantLng) / 2,
          )
        : LatLng(restaurantLat, restaurantLng);

    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
            child: Row(
              children: [
                Icon(Icons.directions, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isTraditionalChinese ? '路線' : 'Directions',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Map section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialTarget,
                  zoom: userPos != null ? 13 : 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('restaurant'),
                    position: LatLng(restaurantLat, restaurantLng),
                    infoWindow: InfoWindow(title: restaurantName),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ),
                },
                polylines: polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                compassEnabled: true,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (userPos != null) {
                    // Fit both points
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (!mounted) return;
                      final bounds = LatLngBounds(
                        southwest: LatLng(
                          userPos.latitude < restaurantLat ? userPos.latitude : restaurantLat,
                          userPos.longitude < restaurantLng ? userPos.longitude : restaurantLng,
                        ),
                        northeast: LatLng(
                          userPos.latitude > restaurantLat ? userPos.latitude : restaurantLat,
                          userPos.longitude > restaurantLng ? userPos.longitude : restaurantLng,
                        ),
                      );
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngBounds(bounds, 60),
                      );
                    });
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Transport mode picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<_TransportMode>(
              segments: _TransportMode.values.map((mode) {
                return ButtonSegment(
                  value: mode,
                  label: Text(mode.label(widget.isTraditionalChinese), style: const TextStyle(fontSize: 12)),
                  icon: Icon(mode.icon, size: 18),
                );
              }).toList(),
              selected: {_selectedMode},
              onSelectionChanged: (selected) {
                setState(() => _selectedMode = selected.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Route summary card
          if (distanceMetres != null && estimatedMinutes != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Row(
                    children: [
                      // Estimated time
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.schedule, color: theme.colorScheme.primary),
                            const SizedBox(height: 4),
                            Text(
                              _formatTravelTime(estimatedMinutes),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.isTraditionalChinese ? '預計時間' : 'Est. Time',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      Container(
                        width: 1,
                        height: 50,
                        color: theme.dividerColor,
                      ),
                      // Distance
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.straighten, color: theme.colorScheme.primary),
                            const SizedBox(height: 4),
                            Text(
                              locationService.formatDistance(distanceMetres),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.isTraditionalChinese ? '距離' : 'Distance',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.location_off, color: theme.colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.isTraditionalChinese
                              ? '請啟用定位服務以查看路線資訊'
                              : 'Enable location services to see route info',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const Spacer(),

          // Open in Google Maps button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: FilledButton.icon(
              onPressed: _openInGoogleMaps,
              icon: const Icon(Icons.map),
              label: Text(
                widget.isTraditionalChinese ? '在 Google Maps 中打開' : 'Open in Google Maps',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
