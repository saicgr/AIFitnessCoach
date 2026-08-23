import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
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

  /// Row #129: `MobileScanner`'s default error view has no retry / Open
  /// Settings action, so denying the camera permission once left the sheet a
  /// permanent dead end — and the static footer below kept instructing
  /// "Point your camera at a product barcode" even though no camera was
  /// showing. Tracked so the footer can be swapped for real guidance and the
  /// scanner can be reconstructed after the user grants permission from
  /// Settings (re-opening the sheet alone didn't re-check it — a fresh
  /// [MobileScannerController] does, since `autoStart` re-requests on init).
  MobileScannerErrorCode? _errorCode;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
    );
  }

  /// Tears down and rebuilds the controller so a fresh `start()` re-checks
  /// the OS permission state — the only way to recover after the user grants
  /// it from Settings without leaving this sheet entirely.
  Future<void> _retryAfterSettings() async {
    await ph.openAppSettings();
    if (!mounted) return;
    final old = _controller;
    setState(() {
      _errorCode = null;
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
      );
    });
    unawaited(old?.dispose());
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
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
            child: Row(
              children: [
                Icon(Icons.qr_code_scanner, color: teal, size: 22),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context).barcodeScannerOverlayScanABarcode, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary)),
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
                      errorBuilder: (errorContext, error) {
                        // Deferred: this runs during MobileScanner's own
                        // build, so flip the sibling footer/target state on
                        // the NEXT frame rather than calling setState here.
                        if (_errorCode != error.errorCode) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _errorCode = error.errorCode);
                            }
                          });
                        }
                        return _buildScannerError(
                          error.errorCode, isDark, textPrimary, textMuted, teal);
                      },
                    ),
                  ),
                ),
                if (_errorCode == null)
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _footerMessage(context),
                  style: TextStyle(fontSize: 14, color: textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _showManualEntryDialog,
                  child: Text(
                    'ENTER BARCODE NUMBER',
                    style: TextStyle(color: teal, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Footer copy driven off the same `_errorCode` the error view uses.
  String _footerMessage(BuildContext context) {
    switch (_errorCode) {
      case null:
        return AppLocalizations.of(context).barcodeScannerOverlayPointYourCameraAt;
      case MobileScannerErrorCode.unsupported:
        return "This device can't scan barcodes — enter the number below.";
      case MobileScannerErrorCode.permissionDenied:
        return 'Grant camera access to scan a barcode.';
      default:
        return 'Enter the barcode number below instead.';
    }
  }

  Future<void> _showManualEntryDialog() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter barcode number'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 14,
          decoration: const InputDecoration(hintText: 'e.g. 012345678905'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context).buttonCancel),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (RegExp(r'^\d{8,14}$').hasMatch(text)) {
                Navigator.pop(dialogContext, text);
              }
            },
            child: const Text('LOG'),
          ),
        ],
      ),
    );
    if (value != null && mounted) {
      widget.onBarcodeDetected(value);
    }
  }

  /// Row #129: replaces `MobileScanner`'s bare error text with the real
  /// recovery affordance it was missing — "Open Settings" for a denied
  /// permission (the only way to grant it once denied on iOS/Android without
  /// leaving the app), a plain retry for anything else.
  Widget _buildScannerError(
    MobileScannerErrorCode code,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color teal,
  ) {
    final isPermissionDenied = code == MobileScannerErrorCode.permissionDenied;
    final isUnsupported = code == MobileScannerErrorCode.unsupported;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermissionDenied
                  ? Icons.no_photography_outlined
                  : Icons.error_outline_rounded,
              size: 40,
              color: textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              code.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (isPermissionDenied)
              OutlinedButton(
                onPressed: _retryAfterSettings,
                style: OutlinedButton.styleFrom(
                  foregroundColor: teal,
                  side: BorderSide(color: teal),
                ),
                child: const Text('OPEN SETTINGS'),
              )
            else if (!isUnsupported)
              OutlinedButton(
                onPressed: () {
                  setState(() => _errorCode = null);
                  _controller?.start();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: teal,
                  side: BorderSide(color: teal),
                ),
                child: const Text('RETRY'),
              ),
          ],
        ),
      ),
    );
  }
}
