// REGRESSION GATE — E2E 2026-08-05, stats lane finding row 19.
//
// The Photos tab's "Compare" button was live (tappable, full accent styling)
// even with 0 or 1 photos. The Compare flow needs 2 photos to pick from
// (Choose Layout -> Select Photos -> Customize), so tapping it with fewer
// always walked the user two full wizard steps before hard-stopping on
// "No Photos Found" with a disabled Next — a dead end that should never have
// been enterable.
//
// This test pins that the Compare control is disabled (not tappable, muted
// styling) below 2 photos, and enabled at/above 2.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/models/progress_photos.dart';
import 'package:fitwiz/data/repositories/progress_photos_repository.dart';
import 'package:fitwiz/data/services/api_client.dart' as data_api;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/stats/widgets/photos_tab.dart';

const _userId = 'u1';

/// Publishes a fixed [ProgressPhotosState] and never touches the network —
/// the real notifier's `loadAll()` is never called, so the underlying
/// repository/ApiClient exist only to satisfy the constructor.
class _FakeProgressPhotosNotifier extends ProgressPhotosNotifier {
  _FakeProgressPhotosNotifier(int totalPhotos)
      : super(
          ProgressPhotosRepository(
            data_api.ApiClient(const FlutterSecureStorage()),
          ),
          _userId,
        ) {
    state = ProgressPhotosState(
      stats: PhotoStats(userId: _userId, totalPhotos: totalPhotos),
    );
  }
}

Future<void> _pumpPhotosTab(WidgetTester tester, {required int totalPhotos}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        progressPhotosNotifierProvider(_userId).overrideWith(
          (ref) => _FakeProgressPhotosNotifier(totalPhotos),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: <Locale>[Locale('en')],
        home: Scaffold(
          body: PhotosTab(userId: _userId),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('Compare is disabled (not tappable) with 0 photos',
      (tester) async {
    await _pumpPhotosTab(tester, totalPhotos: 0);

    final gesture = tester.widget<GestureDetector>(
      find.ancestor(
        of: find.byIcon(Icons.compare_arrows_rounded),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(gesture.onTap, isNull,
        reason: 'Compare must not be enterable with 0 photos — the wizard '
            'always dead-ends on "No Photos Found" two steps later');
  });

  testWidgets('Compare is disabled (not tappable) with 1 photo',
      (tester) async {
    await _pumpPhotosTab(tester, totalPhotos: 1);

    final gesture = tester.widget<GestureDetector>(
      find.ancestor(
        of: find.byIcon(Icons.compare_arrows_rounded),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(gesture.onTap, isNull,
        reason: 'the layout picker always asks for 2 photos to compare');
  });

  testWidgets('Compare is enabled (tappable) with 2+ photos', (tester) async {
    await _pumpPhotosTab(tester, totalPhotos: 2);

    final gesture = tester.widget<GestureDetector>(
      find.ancestor(
        of: find.byIcon(Icons.compare_arrows_rounded),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(gesture.onTap, isNotNull,
        reason: 'with enough photos the flow can actually complete');
  });
}
