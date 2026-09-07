// Foundation smoke test: with no stored token, the app should skip past the
// splash screen straight to the (public) home screen — Search and Listing
// Detail are public too, but Home is the router's default landing route.
// Proves the router, theme, and auth session wiring all boot correctly
// without touching the network (flutter_secure_storage's platform channel
// isn't available under `flutter test`, so a fake with no token stands in
// for a fresh install).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ghar_nepal/app.dart';
import 'package:ghar_nepal/core/network/token_storage.dart';
import 'package:ghar_nepal/core/network/providers.dart';

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> clearToken() async {}
}

void main() {
  testWidgets('a guest is routed to the public home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(_FakeTokenStorage())],
        child: const GharNepalApp(),
      ),
    );

    // Session resolution is async, and Home's banner/municipality providers
    // are network-backed (so they fail fast under `flutter test`, which
    // fakes every HttpClient response as a 400). Pump a bounded number of
    // frames rather than pumpAndSettle: the Skeleton shimmer and the
    // municipalities loading spinner both animate forever and would make
    // pumpAndSettle hang waiting for them to stop.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Ghar Nepal'), findsOneWidget);
    expect(find.text('Search houses, land, rooms...'), findsOneWidget);
  });
}
