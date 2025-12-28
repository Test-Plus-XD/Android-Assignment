import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Location Picker Dialog Widget
///
/// Displays a full-screen Google Maps dialog where restaurant owners can
/// select their restaurant's location by tapping on the map.
/// The selected location is marked with a pin and can be confirmed or cancelled.
class LocationPickerDialog extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final bool isTraditionalChinese;

  const LocationPickerDialog({
    this.initialLatitude,
    this.initialLongitude,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Set initial location if provided
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _addMarker(_selectedLocation!);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _addMarker(position);
    });
  }

  void _addMarker(LatLng position) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
        draggable: true,
        onDragEnd: (newPosition) {
          setState(() {
            _selectedLocation = newPosition;
          });
        },
      ),
    );
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.of(context).pop({
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Default to Hong Kong if no initial location
    final initialPosition = _selectedLocation ??
        LatLng(
          widget.initialLatitude ?? 22.3193,
          widget.initialLongitude ?? 114.1694,
        );

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isTraditionalChinese ? '選擇位置' : 'Select Location',
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton(
              onPressed: _selectedLocation != null ? _confirmLocation : null,
              child: Text(
                widget.isTraditionalChinese ? '確認' : 'Confirm',
                style: TextStyle(
                  color: _selectedLocation != null
                      ? theme.colorScheme.primary
                      : theme.disabledColor,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Google Map
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 15.0,
              ),
              onTap: _onMapTapped,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            ),

            // Instructions card
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.isTraditionalChinese
                              ? '點擊地圖以選擇餐廳位置，您也可以拖動標記來調整位置'
                              : 'Tap on the map to select restaurant location. You can also drag the marker to adjust.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Selected coordinates display
            if (_selectedLocation != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isTraditionalChinese ? '已選位置' : 'Selected Location',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.isTraditionalChinese ? '緯度' : 'Latitude'}: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          '${widget.isTraditionalChinese ? '經度' : 'Longitude'}: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
