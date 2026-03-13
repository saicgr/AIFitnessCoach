import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import '../../../widgets/glass_back_button.dart';

/// Full-screen image viewer with pinch-to-zoom and optional Hero animation.
class FullscreenImageViewer extends StatelessWidget {
  final String? imageUrl;
  final String? localFilePath;
  final String? heroTag;

  const FullscreenImageViewer({
    super.key,
    this.imageUrl,
    this.localFilePath,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = _buildImage();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(icon: Icons.close),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: heroTag != null
            ? Hero(tag: heroTag!, child: _interactiveViewer(imageWidget))
            : _interactiveViewer(imageWidget),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white24,
        onPressed: () => _saveToGallery(context),
        child: const Icon(Icons.save_alt, color: Colors.white),
      ),
    );
  }

  Widget _interactiveViewer(Widget child) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: child,
    );
  }

  Widget _buildImage() {
    if (localFilePath != null && localFilePath!.isNotEmpty) {
      final file = File(localFilePath!);
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.contain,
        placeholder: (_, __) => const CircularProgressIndicator(
          color: Colors.white,
        ),
        errorWidget: (_, __, ___) => _errorPlaceholder(),
      );
    }

    return _errorPlaceholder();
  }

  Widget _errorPlaceholder() {
    return const Icon(
      Icons.broken_image,
      color: Colors.white54,
      size: 64,
    );
  }

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      String? path;
      if (localFilePath != null && localFilePath!.isNotEmpty) {
        path = localFilePath;
      } else if (imageUrl != null && imageUrl!.isNotEmpty) {
        // Download remote image to local cache first
        final file = await DefaultCacheManager().getSingleFile(imageUrl!);
        path = file.path;
      }

      if (path != null) {
        await Gal.putImage(path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image saved to gallery')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image to save')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
        );
      }
    }
  }
}
