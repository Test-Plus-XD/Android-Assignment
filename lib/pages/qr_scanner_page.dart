import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/restaurant_service.dart';
import '../models.dart';
import '../widgets/common/loading_indicator.dart';
import 'restaurant_menu_page.dart';

/// QR Scanner Page
///
/// This page allows diners to scan QR codes displayed at restaurants
/// to quickly access the restaurant's menu within the app.
///
/// Technical implementation:
/// - Uses mobile_scanner package for camera access and QR code detection
/// - Validates scanned QR codes match the expected format (pourrice://menu/{restaurantId})
/// - Fetches restaurant details from Algolia to verify the restaurant exists
/// - Navigates to the restaurant's menu page upon successful scan
///
/// User experience flow:
/// 1. User opens QR scanner from the app
/// 2. Camera viewfinder appears with scanning overlay
/// 3. User points camera at restaurant's QR code
/// 4. App detects QR code and validates the format
/// 5. App fetches restaurant details to verify it exists
/// 6. App navigates to the restaurant's menu page
/// 7. User can browse menu and make informed dining decisions
class QRScannerPage extends StatefulWidget {
  final bool isTraditionalChinese;
  const QRScannerPage({
    this.isTraditionalChinese = false,
    super.key,
  });
  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  /// Mobile scanner controller for managing camera and scanning
  MobileScannerController cameraController = MobileScannerController(
    // Only detect QR codes (not barcodes)
    formats: [BarcodeFormat.qrCode],
    // Use back camera for scanning
    facing: CameraFacing.back,
    // High-speed detection for responsive scanning
    detectionSpeed: DetectionSpeed.normal,
  );
  /// Whether a QR code is currently being processed
  /// This prevents multiple scans from being processed simultaneously
  bool _isProcessing = false;
  /// Whether the torch (flashlight) is currently enabled
  /// Useful for scanning in low-light conditions
  bool _torchEnabled = false;

  @override
  void dispose() {
    // Clean up camera controller when page is closed
    cameraController.dispose();
    super.dispose();
  }

  /// Toggle the device torch (flashlight)
  ///
  /// This is helpful when scanning QR codes in dimly lit restaurants.
  /// The torch illuminates the QR code for better detection.
  Future<void> _toggleTorch() async {
    try {
      await cameraController.toggleTorch();
      setState(() {
        _torchEnabled = !_torchEnabled;
      });
    } catch (e) {
      // Some devices may not support torch
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese
                  ? '開唔到閃光燈'
                  : 'Failed to toggle torch',
            ),
          ),
        );
      }
    }
  }

  /// Switch between front and back camera
  ///
  /// Most users will use the back camera for scanning, but the front
  /// camera option is available if someone else is showing them a QR code.
  Future<void> _switchCamera() async {
    try {
      await cameraController.switchCamera();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese
                  ? '切換唔到相機'
                  : 'Failed to switch camera',
            ),
          ),
        );
      }
    }
  }

  /// Process scanned QR code
  ///
  /// This handles the complete flow after a QR code is detected:
  /// 1. Validate the QR code format (must be pourrice://menu/{restaurantId})
  /// 2. Extract the restaurant ID from the URL
  /// 3. Fetch restaurant details from Algolia to verify it exists
  /// 4. Navigate to the restaurant's menu page
  /// 5. Handle any errors (invalid format, restaurant not found, etc.)
  Future<void> _handleQRCodeDetected(BarcodeCapture capture) async {
    // Prevent processing multiple scans simultaneously
    if (_isProcessing) return;
    // Get the scanned QR code data
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final String? scannedData = barcodes.first.rawValue;
    if (scannedData == null || scannedData.isEmpty) return;
    // Set processing flag to prevent duplicate processing
    setState(() => _isProcessing = true);
    try {
      // Step 1: Validate QR code format
      // Expected format: pourrice://menu/{restaurantId}
      final Uri? uri = Uri.tryParse(scannedData);
      if (uri == null ||
          uri.scheme != 'pourrice' ||
          uri.host != 'menu' ||
          uri.pathSegments.isEmpty) {
        throw Exception(
          widget.isTraditionalChinese
              ? '呢個二維碼格式唔啱'
              : 'Invalid QR code format',
        );
      }
      // Step 2: Extract restaurant ID from the URL
      // Format: pourrice://menu/{restaurantId}
      final String restaurantId = uri.pathSegments.first;
      // Step 3: Fetch restaurant details to verify it exists
      // This also gets the restaurant name for display
      final restaurantService = context.read<RestaurantService>();
      final Restaurant? restaurant = await restaurantService.getRestaurantById(restaurantId);
      if (restaurant == null) {
        throw Exception(
          widget.isTraditionalChinese
              ? '搵唔到呢間餐廳'
              : 'Restaurant not found',
        );
      }
      // Step 4: Navigate to restaurant's menu page
      if (mounted) {
        // Get the restaurant name for display
        final String restaurantName = widget.isTraditionalChinese
            ? (restaurant.nameTc ?? restaurant.nameEn ?? 'Restaurant')
            : (restaurant.nameEn ?? restaurant.nameTc ?? 'Restaurant');
        // Navigate to menu page and pop the scanner when done
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantMenuPage(
              restaurantId: restaurantId,
              restaurantName: restaurantName,
              isTraditionalChinese: widget.isTraditionalChinese,
            ),
          ),
        );
      }
    } catch (e) {
      // Step 5: Handle errors
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        // Reset processing flag to allow retry
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // Dark app bar for better contrast with camera viewfinder
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.isTraditionalChinese ? '掃描二維碼' : 'Scan QR Code',
        ),
        actions: [
          // Torch toggle button
          IconButton(
            icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
            tooltip: widget.isTraditionalChinese ? '閃光燈' : 'Torch',
          ),
          // Camera switch button
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: _switchCamera,
            tooltip: widget.isTraditionalChinese ? '切換相機' : 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera viewfinder
          // This displays the live camera feed and handles QR code detection
          MobileScanner(
            controller: cameraController,
            onDetect: _handleQRCodeDetected,
          ),
          // Scanning overlay
          // This provides visual guidance to help users align the QR code
          CustomPaint(
            painter: _ScannerOverlayPainter(
              scanAreaSize: 250,
              borderColor: theme.colorScheme.primary,
            ),
            child: Container(),
          ),
          // Processing indicator
          // Shows when a QR code has been scanned and is being processed
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LoadingIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      widget.isTraditionalChinese
                          ? '處理緊...'
                          : 'Processing...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Instructions overlay
          // Positioned at the bottom to guide users
          if (!_isProcessing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isTraditionalChinese
                          ? '將鏡頭對準餐廳嘅二維碼'
                          : 'Point camera at restaurant\'s QR code',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isTraditionalChinese
                          ? '二維碼會自動掃描'
                          : 'The QR code will scan automatically',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for the scanner overlay
///
/// This draws a semi-transparent overlay with a transparent square in the centre,
/// creating a visual guide for where users should position the QR code.
/// The overlay helps users understand the scanning area and improves scan accuracy.
class _ScannerOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final Color borderColor;

  _ScannerOverlayPainter({
    required this.scanAreaSize,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the centre position for the scan area
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    // Create the scan area rectangle
    final Rect scanArea = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Draw the dark overlay around the scan area
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5);

    // Top rectangle
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, top),
      overlayPaint,
    );

    // Bottom rectangle
    canvas.drawRect(
      Rect.fromLTWH(0, top + scanAreaSize, size.width, size.height - top - scanAreaSize),
      overlayPaint,
    );

    // Left rectangle
    canvas.drawRect(
      Rect.fromLTWH(0, top, left, scanAreaSize),
      overlayPaint,
    );

    // Right rectangle
    canvas.drawRect(
      Rect.fromLTWH(left + scanAreaSize, top, size.width - left - scanAreaSize, scanAreaSize),
      overlayPaint,
    );

    // Draw corner borders for the scan area
    // These corners help users align the QR code within the scanning area
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double cornerLength = 30;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      borderPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize - cornerLength, top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + cornerLength),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left, top + scanAreaSize - cornerLength),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}