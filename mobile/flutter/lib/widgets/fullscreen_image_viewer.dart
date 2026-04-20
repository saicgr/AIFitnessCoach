/// Shared fullscreen image viewer with pinch-zoom + fade transition.
/// Extracted from log_meal_sheet_ui.dart so multiple screens can reuse it.
library;

import 'dart:io';
import 'package:flutter/material.dart';

void showFullscreenImage(
  BuildContext context, {
  String? localPath,
  String? networkUrl,
  String heroTag = 'fullscreen_image',
}) {
  assert(localPath != null || networkUrl != null, 'Provide either localPath or networkUrl');
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Center(
                  child: Hero(
                    tag: heroTag,
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: localPath != null
                          ? Image.file(
                              File(localPath),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _errorPlaceholder(),
                            )
                          : Image.network(
                              networkUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _errorPlaceholder(),
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(color: Colors.white70),
                                );
                              },
                            ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _errorPlaceholder() {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_outlined, color: Colors.white38, size: 64),
        SizedBox(height: 12),
        Text(
          'Could not load image',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ],
    ),
  );
}
