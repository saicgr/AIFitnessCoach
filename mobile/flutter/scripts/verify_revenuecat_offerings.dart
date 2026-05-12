// Verify that RevenueCat's "default" offering points at the right Play
// Console SKUs with the prices we shipped.
//
// Run after `backend/scripts/update_play_subscriptions.py` propagates
// (~6h) to assert the in-app paywall will display $7.99/$59.99 instead
// of the legacy $49.99/30-min sandbox values.
//
// Usage:
//     cd mobile/flutter
//     dart run scripts/verify_revenuecat_offerings.dart
//
// Reads RC_REST_API_KEY + RC_PROJECT_ID from `.env`. Exits non-zero on
// any drift so the script can gate CI.

import 'dart:convert';
import 'dart:io';

const _expected = {
  'monthly': {
    'sku': 'premium_monthly',
    'price_usd': 7.99,
  },
  'annual': {
    'sku': 'premium_yearly',
    'price_usd': 59.99,
  },
};

// >5% drift between RevenueCat price and our expected price flips this to a
// hard failure — anything tighter than that triggers false-positives from
// regional VAT rounding on the Play side.
const _priceDriftTolerance = 0.05;

Future<void> main(List<String> args) async {
  final envPath = File('.env');
  if (!envPath.existsSync()) {
    stderr.writeln('No .env in mobile/flutter — abort.');
    exit(2);
  }
  final env = <String, String>{};
  for (final line in envPath.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final eq = trimmed.indexOf('=');
    if (eq < 0) continue;
    env[trimmed.substring(0, eq).trim()] = trimmed.substring(eq + 1).trim();
  }

  final key = env['RC_REST_API_KEY'];
  final projectId = env['RC_PROJECT_ID'];
  if (key == null || key.isEmpty || projectId == null || projectId.isEmpty) {
    stderr.writeln('Missing RC_REST_API_KEY or RC_PROJECT_ID in .env.');
    exit(2);
  }

  final client = HttpClient();
  final req = await client.getUrl(Uri.parse(
      'https://api.revenuecat.com/v2/projects/$projectId/offerings'));
  req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $key');
  req.headers.set(HttpHeaders.acceptHeader, 'application/json');
  final res = await req.close();
  if (res.statusCode != 200) {
    final body = await res.transform(utf8.decoder).join();
    stderr.writeln('RevenueCat API error: ${res.statusCode}\n$body');
    exit(3);
  }
  final raw = await res.transform(utf8.decoder).join();
  final data = jsonDecode(raw) as Map<String, dynamic>;

  final offerings = (data['items'] as List? ?? <dynamic>[]);
  final defaultOffering = offerings.firstWhere(
    (o) => (o as Map<String, dynamic>)['lookup_key'] == 'default',
    orElse: () => null,
  );
  if (defaultOffering == null) {
    stderr.writeln('No "default" offering found — check RC dashboard.');
    exit(4);
  }

  final packages = ((defaultOffering as Map<String, dynamic>)['packages']
          as List? ??
      <dynamic>[]);

  var failed = false;
  for (final entry in _expected.entries) {
    final pkgKey = entry.key;
    final expectedSku = entry.value['sku'] as String;
    final expectedPrice = entry.value['price_usd'] as double;

    final pkg = packages.firstWhere(
      (p) => (p as Map<String, dynamic>)['lookup_key'] == pkgKey,
      orElse: () => null,
    );
    if (pkg == null) {
      stderr.writeln('✗ package "$pkgKey" missing from default offering');
      failed = true;
      continue;
    }

    final products = ((pkg as Map<String, dynamic>)['products'] as List? ??
        <dynamic>[]);
    final googleProduct = products.firstWhere(
      (p) => (p as Map<String, dynamic>)['app']?['type'] == 'play_store',
      orElse: () => null,
    );
    if (googleProduct == null) {
      stderr.writeln('✗ $pkgKey has no Play-store product attached');
      failed = true;
      continue;
    }

    final sku =
        (googleProduct as Map<String, dynamic>)['store_identifier'] as String?;
    if (sku != expectedSku) {
      stderr.writeln(
          '✗ $pkgKey: expected SKU "$expectedSku" but got "$sku"');
      failed = true;
      continue;
    }

    final priceMicros = (googleProduct['price']?['amount_micros'] as int?) ?? 0;
    final price = priceMicros / 1_000_000.0;
    final drift = (price - expectedPrice).abs() / expectedPrice;
    if (drift > _priceDriftTolerance) {
      stderr.writeln(
          '✗ $pkgKey: price drift ${(drift * 100).toStringAsFixed(1)}% '
          '(expected \$${expectedPrice.toStringAsFixed(2)}, got '
          '\$${price.toStringAsFixed(2)})');
      failed = true;
      continue;
    }

    stdout.writeln(
        '✓ $pkgKey → $sku @ \$${price.toStringAsFixed(2)} (drift '
        '${(drift * 100).toStringAsFixed(2)}%)');
  }

  client.close();
  if (failed) {
    stderr.writeln(
        '\nOne or more checks failed. Run the Play subscriptions script and '
        'wait ~6h for cache propagation before re-trying.');
    exit(1);
  }
  stdout.writeln('\nAll RevenueCat offerings match expected SKUs + pricing.');
}
