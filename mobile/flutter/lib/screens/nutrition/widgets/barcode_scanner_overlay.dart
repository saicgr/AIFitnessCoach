import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';

class BarcodeScannerOverlay extends StatefulWidget {
  final void Function(String) onBarcodeDetected;
  final bool isDark;

  const BarcodeScannerOverlay({super.key, required this.onBarcodeDetected, required this.isDark});

  @override
  State<BarcodeScannerOverlay> createState() => _BarcodeScannerOverlayState();
}

class _BarcodeScannerOverlayState extends State<BarcodeScannerOverlay> {
  MobileScannerController? _controller;
  bool _hasDetected = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return GlassSheet(
      maxHeightFraction: 0.75,
      child: Column(
        children: [
          // Header with close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Icon(Icons.qr_code_scanner, color: teal, size: 22),
                const SizedBox(width: 10),
                Text('Scan a Barcode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: textMuted)),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: (capture) {
                        if (_hasDetected) return;
                        for (final barcode in capture.barcodes) {
                          final value = barcode.rawValue;
                          if (value != null && RegExp(r'^\d{8,14}$').hasMatch(value)) {
                            _hasDetected = true;
                            widget.onBarcodeDetected(value);
                            break;
                          }
                        }
                      },
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: teal, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Point your camera at a product barcode', style: TextStyle(fontSize: 14, color: textMuted)),
          ),
        ],
      ),
    );
  }
}
