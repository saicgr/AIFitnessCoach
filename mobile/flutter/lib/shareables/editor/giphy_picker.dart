import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/glass_sheet.dart';
import 'giphy_service.dart';

/// A GIPHY search sheet for the food editor. Opens trending GIFs, searches
/// as the user types (debounced), and pops the chosen GIF's URL.
class GiphyPicker extends StatefulWidget {
  const GiphyPicker({super.key});

  /// Shows the picker; resolves to the selected GIF url, or null if
  /// dismissed.
  static Future<String?> pick(BuildContext context) {
    return showGlassSheet<String>(
      context: context,
      builder: (_) => const GlassSheet(
        opaque: true,
        child: GiphyPicker(),
      ),
    );
  }

  @override
  State<GiphyPicker> createState() => _GiphyPickerState();
}

class _GiphyPickerState extends State<GiphyPicker> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<GiphyGif> _gifs = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
    setState(() => _loading = true);
    final results = await GiphyService.search(query);
    if (!mounted) return;
    setState(() {
      _gifs = results;
      _loading = false;
    });
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(value));
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onQueryChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search GIFs…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(child: _grid()),
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'Powered by GIPHY',
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_gifs.isEmpty) {
      return const Center(
        child: Text(
          'No GIFs found — try another search',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _gifs.length,
      itemBuilder: (context, i) {
        final gif = _gifs[i];
        return GestureDetector(
          onTap: () => Navigator.pop(context, gif.fullUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              gif.previewUrl,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF22252C)),
              loadingBuilder: (ctx, child, prog) => prog == null
                  ? child
                  : const ColoredBox(color: Color(0xFF1A1D23)),
            ),
          ),
        );
      },
    );
  }
}
