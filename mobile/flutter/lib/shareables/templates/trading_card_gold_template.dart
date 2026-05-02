import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// Trading card — gold-foil border on dark navy interior with a ★ RARE
/// rarity pill, exercise illustration as the photo, and the user's name
/// + key stats below. Distinct from production's existing `tradingCard`
/// (which uses dynamic per-share accent coloring); this is the "rare
/// drop" aesthetic ported from the onboarding demo.
class TradingCardGoldTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const TradingCardGoldTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static const Color _gold1 = Color(0xFFFBBF24);
  static const Color _gold2 = Color(0xFFEAB308);
  static const Color _gold3 = Color(0xFFCA8A04);
  static const Color _border = Color(0xFF422006);
  static const Color _navy = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final firstName = (data.userDisplayName ?? '').trim().split(' ').first;
    final cardholder =
        firstName.isEmpty ? 'YOU' : firstName.toUpperCase();
    final exerciseImage =
        (data.exercises != null && data.exercises!.isNotEmpty)
            ? data.exercises!.first.imageUrl
            : data.heroImageUrl;
    final categoryLabel =
        (data.title.split(' ').first).toUpperCase();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF0B1020), Color(0xFF0B1020), Color(0xFF0B1020)],
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 0.72,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_gold1, _gold2, _gold3],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border, width: 3),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _navy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              categoryLabel,
                              style: TextStyle(
                                color: _gold1,
                                fontSize: 14 * mul,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '★ RARE',
                              style: TextStyle(
                                color: _gold1,
                                fontSize: 12 * mul,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _hero(exerciseImage),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          cardholder,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28 * mul,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Container(
                          height: 1,
                          color: _gold1.withValues(alpha: 0.4),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        ...data.highlights.take(3).map(
                              (m) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      m.label.toUpperCase(),
                                      style: TextStyle(
                                        color: _gold1,
                                        fontSize: 11 * mul,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      m.value,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13 * mul,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (showWatermark) ...[
              const SizedBox(height: 16),
              const AppWatermark(textColor: Colors.white60),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hero(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Image.asset(
        'assets/images/exercises/barbell_squat.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.white),
      );
}
