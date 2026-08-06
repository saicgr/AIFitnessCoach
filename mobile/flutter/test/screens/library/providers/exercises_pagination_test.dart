/// Regression test for Library → Exercises tab → search results pagination
/// (E2E row 24, HIGH — "scrolling re-serves page 1").
///
/// `ExercisesNotifier.loadExercises` had a skip-refetch guard that fired for
/// ANY non-refresh call once the filter signature matched the currently
/// loaded page — which is true for EVERY pagination continuation (same
/// filters, just the next page), not only the "re-entered the tab with
/// unchanged filters" case the comment describes. The unconditional
/// `!refresh` branch made every "load more" (scroll or the Load More button)
/// silently no-op: no second network request, `hasMore` and `offset` frozen,
/// the count never grew past the first page.
///
/// This pins that a second `loadExercises()` call (unchanged filters, no
/// `refresh`) actually reaches the network at `offset` = the first page's
/// size, and its results are appended — not silently dropped.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/services/api_client.dart';
import 'package:fitwiz/screens/library/models/exercises_state.dart';
import 'package:fitwiz/screens/library/providers/library_providers.dart';

/// Serves a deterministic page of fake exercises keyed by the request's
/// `offset` query parameter, and records every request URL that reached it.
class _PagedExercisesAdapter implements HttpClientAdapter {
  final List<String> requestedOffsets = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final offset = options.uri.queryParameters['offset'] ?? '0';
    requestedOffsets.add(offset);
    final start = int.parse(offset);
    final items = List.generate(
      100,
      (i) => '{"id":"ex-${start + i}","name":"Exercise ${start + i}"}',
    ).join(',');
    return ResponseBody.fromString(
      '[$items]',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        // Row 25's backend fix — the authoritative match count.
        'x-total-count': const ['260'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late ApiClient client;
  late _PagedExercisesAdapter adapter;
  late ProviderContainer container;

  setUp(() {
    client = ApiClient(const FlutterSecureStorage());
    adapter = _PagedExercisesAdapter();
    client.dio.httpClientAdapter = adapter;
    container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(client)],
    );
    addTearDown(container.dispose);
  });

  /// Same fixed-budget interceptor-chain drain pattern as
  /// `api_client_get_coalescing_test.dart` — deterministic, no polling.
  Future<void> settle() async {
    for (var i = 0; i < 64; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test(
    'a second loadExercises() call (unchanged filters, no refresh) issues a '
    'real page-2 request instead of silently no-op-ing',
    () async {
      container.read(exerciseSearchProvider.notifier).state = 'barbell bench';

      final notifier = container.read(exercisesNotifierProvider.notifier);
      await notifier.loadExercises();
      await settle();

      final afterPage1 = container.read(exercisesNotifierProvider);
      expect(afterPage1.exercises.length, 100);
      expect(afterPage1.hasMore, isTrue);
      expect(adapter.requestedOffsets, ['0']);

      // Simulate the scroll-triggered "load more" call — unchanged filters,
      // `refresh: false`, exactly what `_onScroll` / the Load More button do.
      await notifier.loadExercises();
      await settle();

      final afterPage2 = container.read(exercisesNotifierProvider);
      // The defect: this stayed at 100 forever because the guard returned
      // before the network call was ever made.
      expect(
        adapter.requestedOffsets,
        ['0', '100'],
        reason: 'page 2 must be requested at offset=100, not skipped',
      );
      expect(afterPage2.exercises.length, 200);
      // Real, distinct page-2 rows — not page 1 served again.
      expect(afterPage2.exercises.last.id, 'ex-199');

      // E2E row 25 — the header-sourced total, not `exercises.length`.
      expect(afterPage2.totalCount, 260);
    },
  );

  test(
    'ExercisesState.copyWith keeps hasMore/offset semantics the pagination '
    'test above relies on',
    () {
      const state = ExercisesState(hasMore: true, offset: 100);
      final copy = state.copyWith(offset: 200);
      expect(copy.hasMore, isTrue);
      expect(copy.offset, 200);
    },
  );
}
