import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Interactive Map Preview Widget
///
/// Displays an interactive Google Map with zoom controls and map type toggle.
/// Features:
/// - Zoom in/out gestures and controls
/// - Switch between normal and satellite view
/// - Restaurant marker with info window
class InteractiveMapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String restaurantName;
  final MapType mapType;
  final Function(MapType) onMapTypeChanged;
  final Function(GoogleMapController) onMapCreated;
  final bool isTraditionalChinese;

  const InteractiveMapPreview({
    required this.latitude,
    required this.longitude,
    required this.restaurantName,
    required this.mapType,
    required this.onMapTypeChanged,
    required this.onMapCreated,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map type toggle buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SegmentedButton<MapType>(
              segments: [
                ButtonSegment(
                  value: MapType.normal,
                  label: Text(isTraditionalChinese ? '地圖' : 'Map'),
                  icon: const Icon(Icons.map_outlined, size: 18),
                ),
                ButtonSegment(
                  value: MapType.satellite,
                  label: Text(isTraditionalChinese ? '衛星' : 'Satellite'),
                  icon: const Icon(Icons.satellite_alt, size: 18),
                ),
              ],
              selected: {mapType},
              onSelectionChanged: (selected) => onMapTypeChanged(selected.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Map container
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          clipBehavior: Clip.antiAlias,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: LatLng(latitude, longitude), zoom: 16),
            markers: {
              Marker(markerId: MarkerId(restaurantName), position: LatLng(latitude, longitude), infoWindow: InfoWindow(title: restaurantName)),
            },
            mapType: mapType,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            mapToolbarEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: onMapCreated,
          ),
        ),
      ],
    );
  }
}
