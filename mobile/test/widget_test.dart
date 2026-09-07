// Foundation smoke test: with no stored token, the app should skip past the
// splash screen straight to the login screen — proving the router, theme,
// and auth session wiring all boot correctly without touching the network
// (flutter_secure_storage's platform channel isn't available under
// `flutter test`, so a fake with no token stands in for a fresh install).

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
  testWidgets('a guest is routed to the login screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(_FakeTokenStorage())],
        child: const GharNepalApp(),
      ),
    );

    // Session resolution is async; let it settle before asserting on the route.
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
