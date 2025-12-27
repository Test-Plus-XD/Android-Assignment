import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

/// Menu QR Code Generator Widget
///
/// This widget generates a QR code that encodes a deep link to a restaurant's menu.
/// Restaurant owners can display this QR code on table tents, menus, or promotional materials.
/// When scanned by diners, it opens the restaurant's menu directly in the PourRice app.
///
/// The QR code format follows the pattern: `pourrice://menu/{restaurantId}`
/// This deep link is handled by the app to navigate to the restaurant's menu page.
class MenuQRGenerator extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final bool isTraditionalChinese;

  const MenuQRGenerator({
    required this.restaurantId,
    required this.restaurantName,
    this.isTraditionalChinese = false,
    super.key,
  });

  @override
  State<MenuQRGenerator> createState() => _MenuQRGeneratorState();
}

class _MenuQRGeneratorState extends State<MenuQRGenerator> {
  /// Global key for capturing the QR code as an image
  /// This allows us to convert the QR code widget into a PNG for sharing
  final GlobalKey _qrKey = GlobalKey();

  /// Whether the QR code is currently being exported/shared
  bool _isExporting = false;

  /// Generate the deep link URL for the restaurant menu
  ///
  /// Format: pourrice://menu/{restaurantId}
  /// This URL scheme will be handled by the app's deep link configuration
  /// to navigate directly to the restaurant's menu page when scanned.
  String get _deepLinkUrl => 'pourrice://menu/${widget.restaurantId}';

  /// Capture the QR code widget as a PNG image
  ///
  /// This uses Flutter's RenderRepaintBoundary to convert the QR code widget
  /// into an image that can be saved or shared. The process:
  /// 1. Find the RenderRepaintBoundary from the global key
  /// 2. Convert the boundary to an image at 3x pixel ratio for high quality
  /// 3. Convert the image to PNG format byte data
  /// 4. Return the bytes for sharing or saving
  Future<Uint8List?> _captureQRCode() async {
    try {
      // Step 1: Get the render object from the widget tree
      RenderRepaintBoundary? boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return null;

      // Step 2: Convert the render object to an image
      // pixelRatio: 3.0 provides high quality for printing/display
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // Step 3: Convert the image to PNG byte data
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      // Step 4: Return the PNG bytes
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing QR code: $e');
      return null;
    }
  }

  /// Share the QR code image
  ///
  /// This captures the QR code as a PNG and opens Android's share sheet,
  /// allowing restaurant owners to share the QR code via WhatsApp, email,
  /// social media, or save it to their device for printing.
  Future<void> _shareQRCode() async {
    setState(() => _isExporting = true);

    try {
      // Capture the QR code as PNG bytes
      final Uint8List? pngBytes = await _captureQRCode();

      if (pngBytes == null) {
        throw Exception('Failed to capture QR code');
      }

      // Share the image using Android's native share sheet
      // The filename helps users identify the file when saved
      await Share.shareXFiles(
        [
          XFile.fromData(
            pngBytes,
            mimeType: 'image/png',
            name: 'pourrice_menu_qr_${widget.restaurantId}.png',
          ),
        ],
        text: widget.isTraditionalChinese
            ? '掃描此二維碼查看${widget.restaurantName}的菜單'
            : 'Scan this QR code to view ${widget.restaurantName}\'s menu',
      );
    } catch (e) {
      // Show error message if sharing fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese
                  ? '分享失敗：$e'
                  : 'Failed to share: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  /// Show QR code in full-screen dialog
  ///
  /// This displays a larger version of the QR code for easier scanning,
  /// especially useful when showing the code to customers at the restaurant.
  void _showFullScreenQR() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                widget.isTraditionalChinese ? '掃描查看菜單' : 'Scan to View Menu',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // Restaurant name
              Text(
                widget.restaurantName,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Large QR code for scanning
              QrImageView(
                data: _deepLinkUrl,
                version: QrVersions.auto,
                size: 300.0,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
              const SizedBox(height: 24),

              // Close button
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(widget.isTraditionalChinese ? '關閉' : 'Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with icon and title
            Row(
              children: [
                Icon(
                  Icons.qr_code_2,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isTraditionalChinese ? '菜單二維碼' : 'Menu QR Code',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isTraditionalChinese
                            ? '顧客可掃描此二維碼查看您的菜單'
                            : 'Customers can scan this to view your menu',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // QR code display
            // Wrapped in RepaintBoundary to enable capturing as image
            Center(
              child: RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // QR code with error correction
                      // Level H provides highest error correction (30%)
                      // This means the QR code can still be scanned even if
                      // up to 30% of it is damaged or obscured
                      QrImageView(
                        data: _deepLinkUrl,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                      ),
                      const SizedBox(height: 12),

                      // Restaurant name label on QR code
                      Text(
                        widget.restaurantName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Expand button - shows full-screen QR for easy scanning
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFullScreenQR,
                    icon: const Icon(Icons.fullscreen),
                    label: Text(
                      widget.isTraditionalChinese ? '放大' : 'Expand',
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Share button - exports QR as image
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isExporting ? null : _shareQRCode,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.share),
                    label: Text(
                      widget.isTraditionalChinese ? '分享' : 'Share',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Instructions section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isTraditionalChinese
                          ? '提示：您可以將此二維碼列印並放置在餐桌上，或在社交媒體上分享，讓顧客輕鬆瀏覽您的菜單。'
                          : 'Tip: Print this QR code and place it on tables, or share it on social media so customers can easily browse your menu.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
