import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models.dart';
import '../../pages/restaurant_detail_page.dart';
import 'search_map_callout_card.dart';

/// Search Map View
///
/// Displays Algolia search results as map pins on a Google Map.
/// Mirrors the iOS SearchMapView with:
/// - Color-coded markers (green = open, red = closed)
/// - Auto-fit camera to show all pins
/// - Callout card on pin tap with navigation to detail page
/// - User location display
class SearchMapView extends StatefulWidget {
  final List<Restaurant> restaurants;
  final bool isTraditionalChinese;

  const SearchMapView({
    required this.restaurants,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<SearchMapView> createState() => _SearchMapViewState();
}

class _SearchMapViewState extends State<SearchMapView> {
  GoogleMapController? _mapController;
  String? _selectedRestaurantId;

  /// Default centre: Hong Kong
  static const _defaultPosition = LatLng(22.3193, 114.1694);

  /// Filter out restaurants with invalid coordinates
  List<Restaurant> get _validRestaurants => widget.restaurants
      .where((r) =>
          r.latitude != null &&
          r.longitude != null &&
          !(r.latitude == 0 && r.longitude == 0))
      .toList();

  /// Build marker set from valid restaurants
  Set<Marker> get _markers => _validRestaurants.map((r) {
        final isOpen = r.isOpenNow;
        return Marker(
          markerId: MarkerId(r.id),
          position: LatLng(r.latitude!, r.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isOpen ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: r.getDisplayName(widget.isTraditionalChinese),
          ),
          onTap: () {
            setState(() => _selectedRestaurantId = r.id);
          },
        );
      }).toSet();

  Restaurant? get _selectedRestaurant {
    if (_selectedRestaurantId == null) return null;
    try {
      return widget.restaurants.firstWhere((r) => r.id == _selectedRestaurantId);
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant SearchMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurants.length != widget.restaurants.length) {
      _fitCameraToBounds();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Delay to let map render before animating
    Future.delayed(const Duration(milliseconds: 300), _fitCameraToBounds);
  }

  void _fitCameraToBounds() {
    if (_mapController == null) return;
    final valid = _validRestaurants;
    if (valid.isEmpty) return;

    if (valid.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(valid.first.latitude!, valid.first.longitude!),
          15,
        ),
      );
      return;
    }

    double minLat = valid.first.latitude!;
    double maxLat = valid.first.latitude!;
    double minLng = valid.first.longitude!;
    double maxLng = valid.first.longitude!;

    for (final r in valid) {
      if (r.latitude! < minLat) minLat = r.latitude!;
      if (r.latitude! > maxLat) maxLat = r.latitude!;
      if (r.longitude! < minLng) minLng = r.longitude!;
      if (r.longitude! > maxLng) maxLng = r.longitude!;
    }

    // Ensure minimum span to avoid over-zoom
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    if (latSpan < 0.005) {
      minLat -= 0.0025;
      maxLat += 0.0025;
    }
    if (lngSpan < 0.005) {
      minLng -= 0.0025;
      maxLng += 0.0025;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedRestaurant;

    return Stack(
      children: [
        // Google Map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _validRestaurants.isNotEmpty
                ? LatLng(_validRestaurants.first.latitude!, _validRestaurants.first.longitude!)
                : _defaultPosition,
            zoom: 12,
          ),
          markers: _markers,
          onMapCreated: _onMapCreated,
          onTap: (_) => setState(() => _selectedRestaurantId = null),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: true,
          // Push map UI controls (zoom buttons, my-location) above the nav bar
          padding: const EdgeInsets.only(bottom: 96, right: 4),
        ),

        // Callout card for selected pin — positioned above the nav bar
        if (selected != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 96,
            child: SearchMapCalloutCard(
              restaurant: selected,
              isTraditionalChinese: widget.isTraditionalChinese,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RestaurantDetailPage(
                      restaurant: selected,
                      isTraditionalChinese: widget.isTraditionalChinese,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
