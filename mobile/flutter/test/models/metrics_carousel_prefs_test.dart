import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/metrics_carousel_prefs.dart';

void main() {
  group('visibleCarouselPages', () {
    test('Recovery hidden without Health — even if its enabled flag is true',
        () {
      final prefs = MetricsCarouselPrefs.defaults();
      // Defaults ship Recovery "enabled" (the user hasn't opted out), but the
      // page must still be absent from the carousel until Health data is
      // actually available — hidden entirely, not shown as an empty card.
      final visible = visibleCarouselPages(prefs, recoveryAvailable: false);

      expect(visible.contains(CarouselPageId.recovery), isFalse);
      expect(visible, containsAll([CarouselPageId.training, CarouselPageId.volumeTrend]));
    });

    test('Recovery appears once its data is available', () {
      final prefs = MetricsCarouselPrefs.defaults();
      final visible = visibleCarouselPages(prefs, recoveryAvailable: true);

      expect(visible.contains(CarouselPageId.recovery), isTrue);
    });

    test('Recovery stays hidden even when available if the user disabled it',
        () {
      final prefs = MetricsCarouselPrefs.defaults();
      final withRecoveryOff = MetricsCarouselPrefs(
        pages: [
          for (final p in prefs.pages)
            if (p.id == CarouselPageId.recovery) p.copyWith(enabled: false) else p,
        ],
      );
      final visible = visibleCarouselPages(withRecoveryOff, recoveryAvailable: true);

      expect(visible.contains(CarouselPageId.recovery), isFalse);
    });

    test('disabled pages never appear', () {
      final prefs = MetricsCarouselPrefs.defaults();
      final visible = visibleCarouselPages(prefs, recoveryAvailable: false);

      // Muscle balance + PR ladder ship off by default.
      expect(visible.contains(CarouselPageId.muscleBalance), isFalse);
      expect(visible.contains(CarouselPageId.prLadder), isFalse);
    });

    test('page order follows prefs.pages order', () {
      final prefs = MetricsCarouselPrefs.defaults();
      final reordered = MetricsCarouselPrefs(
        pages: [prefs.pages[1], prefs.pages[0], ...prefs.pages.sublist(2)],
      );
      final visible = visibleCarouselPages(reordered, recoveryAvailable: false);

      expect(visible.first, CarouselPageId.volumeTrend);
      expect(visible[1], CarouselPageId.training);
    });
  });

  group('MetricsCarouselPrefs JSON round-trip', () {
    test('round-trips through toJson/fromJson', () {
      final prefs = MetricsCarouselPrefs.defaults();
      final decoded = MetricsCarouselPrefs.fromJson(prefs.toJson());

      expect(decoded.pages.length, prefs.pages.length);
      for (var i = 0; i < prefs.pages.length; i++) {
        expect(decoded.pages[i].id, prefs.pages[i].id);
        expect(decoded.pages[i].enabled, prefs.pages[i].enabled);
        expect(decoded.pages[i].slots, prefs.pages[i].slots);
      }
    });

    test('falls back to defaults on a corrupt blob', () {
      final decoded = MetricsCarouselPrefs.fromJson({'pages': 'not a list'});
      expect(decoded.pages.length, MetricsCarouselPrefs.defaults().pages.length);
    });

    test('drops an unknown slot name rather than throwing', () {
      final decoded = MetricsCarouselPrefs.fromJson({
        'pages': [
          {
            'id': 'training',
            'enabled': true,
            'tall': false,
            'slots': ['volumeKg', 'someFutureSlotThisBuildDoesNotKnow'],
          },
        ],
      });
      final training =
          decoded.pages.firstWhere((p) => p.id == CarouselPageId.training);
      expect(training.slots, [CarouselSlotId.volumeKg]);
    });
  });

  group('page + slot caps', () {
    test('there are exactly kCarouselMaxPages page ids', () {
      expect(CarouselPageId.values.length, kCarouselMaxPages);
    });

    test('normal card caps at 4 slots, tall card at 6', () {
      const normal = CarouselPageConfig(id: CarouselPageId.training, enabled: true);
      const tall =
          CarouselPageConfig(id: CarouselPageId.training, enabled: true, tall: true);
      expect(normal.maxSlots, kCarouselMaxSlotsNormal);
      expect(tall.maxSlots, kCarouselMaxSlotsTall);
    });
  });
}
