// Phase 8: end-to-end flows for the core loop this app exists to support —
// browse -> contact -> post -> moderate — run on a real device/emulator
// against the LIVE backend (`php artisan serve --port=8010` + MySQL must
// already be running; see [[ghar-nepal-mobile-build-status]] memory for the
// dev-server gotchas on this machine). Unlike `test/widget_test.dart`, this
// is not mocked: real network calls, real seeded demo accounts
// (`DemoDataSeeder`/`DatabaseSeeder`), real writes to the dev database.
// Run with: flutter test integration_test/app_test.dart -d <device>
//
// The four flows are independent EXCEPT "post" and "moderate", which are
// deliberately chained (moderate acts on the exact listing "post" just
// created) — that's a more faithful test of the real loop than moderating
// arbitrary pre-seeded data, and the two tests share one Dart isolate run
// sequentially in this file, so a plain top-level variable carries the
// listing's title across them.
//
// pumpAndSettle() is avoided throughout: several screens here (province/
// district/... dropdown cascades, amenities, provider loading states) show
// an indeterminate LinearProgressIndicator/CircularProgressIndicator while
// their own data loads, and pumpAndSettle hangs waiting for *any* animation
// in the whole tree to stop — including one on a totally unrelated section
// of the same screen. Bounded pump loops (mirroring test/widget_test.dart's
// existing convention) sidestep that entirely.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ghar_nepal/app.dart';
import 'package:ghar_nepal/features/auth/application/auth_controller.dart';
import 'package:ghar_nepal/widgets/app_button.dart';
import 'package:ghar_nepal/widgets/property_card.dart';

// A demo owner seeded by backend/database/seeders/DemoDataSeeder.php.
const _ownerEmail = 'bikash.shrestha@demo.gharnepal.test';
const _ownerPassword = 'password';

// The seeded admin (backend/database/seeders/DatabaseSeeder.php). Used as
// the "contact" flow's buyer too, specifically because it's guaranteed not
// to be the poster of any demo listing — sidesteps having to know which
// demo owner authored which listing just to avoid a self-message edge case
// the app doesn't specially handle either way.
const _adminEmail = 'superadmin@gharnepal.local';
const _adminPassword = 'password';

// A minimal, real, valid 1x1 transparent PNG — real magic bytes matter
// because the backend's upload validation is a genuine `mimes:...` check
// against file content, not just the extension.
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

/// Set by the "post" test, read by the "moderate" test that follows it.
String? _postedListingTitle;

Future<void> _settle(WidgetTester tester, {int times = 15, Duration step = const Duration(milliseconds: 200)}) async {
  for (var i = 0; i < times; i++) {
    await tester.pump(step);
  }
}

/// Home/Search/Dashboard all render several CachedNetworkImages at once
/// (city banners, listing thumbnails); a slow or dropped fetch on the
/// emulator's virtual network reports an async image-loading error via
/// FlutterError, which the test framework otherwise treats as a test
/// failure even though no assertion here cares about that particular image
/// loading. Only silence exactly that class of error — and do it as the
/// first line of each `testWidgets` body, not in a shared `setUp()`:
/// `IntegrationTestWidgetsFlutterBinding` re-arms its own `FlutterError.onError`
/// as part of starting each test, which runs *after* `setUp` and would
/// otherwise clobber this override before the test body ever executes.
void _ignoreImageLoadErrors() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final isImageLoadError =
        details.library == 'image resource service' || details.stack.toString().contains('cache_manager');
    if (!isImageLoadError) originalOnError?.call(details);
  };
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: GharNepalApp()));
  // Waits for the splash screen's auth-session resolution to redirect to
  // Home, rather than assuming a fixed settle is always long enough —
  // tests share one Flutter engine/binding across the file, so leftover
  // timers from a previous test can occasionally slow this down.
  await _waitUntil(tester, () => find.text('Home').evaluate().isNotEmpty);
}

/// Pumps in bounded steps until [condition] is true, instead of guessing a
/// fixed settle duration — the right tool whenever what we're waiting for
/// is "one of a few possible states", not just "some async call finished".
Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxTries = 40,
  Duration step = const Duration(milliseconds: 200),
}) async {
  for (var i = 0; i < maxTries; i++) {
    if (condition()) return;
    await tester.pump(step);
  }
  final visibleText = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().join(' | ');
  throw TestFailure('Condition not met after ${maxTries * step.inMilliseconds}ms. Visible text: $visibleText');
}

/// Picks a `DropdownButtonFormField<T>`'s first option, without hardcoding
/// server-seeded data (province/district/... names) into the test — and
/// without ever tapping the popup route, whose items fade/scale in as they
/// open (`_DropdownMenuItemButtonState`'s per-item stagger animation) and
/// can report a hit-testable offset before they're actually positioned
/// there, silently landing the tap on the route's modal barrier instead.
/// `DropdownButtonFormField` builds a real (if privately-constructed)
/// `DropdownButton<T>` as its child, whose `items`/`onChanged` fields are
/// public — reading the former and calling the latter directly reproduces
/// exactly what a successful tap-and-select would do, with no popup, no
/// animation, and no hit-testing involved at all.
Future<void> _selectFirstDropdownOption<T>(WidgetTester tester, Finder dropdownFormFieldFinder) async {
  final button = tester.widget<DropdownButton<T>>(
    find.descendant(of: dropdownFormFieldFinder, matching: find.byType(DropdownButton<T>)),
  );
  button.onChanged!(button.items!.first.value);
  await _settle(tester);
}

Future<void> _login(WidgetTester tester, {required String email, required String password}) async {
  // `/account` isn't in the router's public-route allowlist (app_router.dart
  // `_isPublic`), so a guest tapping "Account" is redirected straight to
  // `/login` — AccountScreen's own `if (user == null)` guest branch is
  // unreachable via normal navigation. So the two real possible outcomes
  // here are "already on LoginScreen" or "already logged in as someone".
  await tester.tap(find.text('Account'));
  final onLoginScreenFinder = find.widgetWithText(ElevatedButton, 'Log in');
  // "My properties" is the first item in AccountScreen's own (long, for an
  // admin) ListTile list, so — unlike "Log out", the very last item — it's
  // already built and visible without scrolling, making it a safe signal
  // for "already logged in as someone" that doesn't need a scroll first.
  final loggedInFinder = find.text('My properties');
  await _waitUntil(tester, () => onLoginScreenFinder.evaluate().isNotEmpty || loggedInFinder.evaluate().isNotEmpty);

  // flutter_secure_storage persists to the real Android keystore, which
  // survives a debug-APK reinstall — so a token saved by an earlier test
  // run (or a *different* logged-in demo account from an earlier test in
  // this same file/process) can still be there. Log out first if so, so
  // every flow starts from a known, logged-out state.
  if (loggedInFinder.evaluate().isNotEmpty) {
    // Bypasses the "Log out" ListTile entirely — for an admin's long
    // AccountScreen menu it renders below the fold, and both tapping it
    // and locating it via find.ancestor proved unreliable (same class of
    // "widget exists but isn't where a hit test/ancestor lookup expects"
    // problem as the dropdown popup items above). This calls the exact
    // same method that ListTile's onTap does, with no widget lookup at all.
    final container = ProviderScope.containerOf(tester.element(find.byType(GharNepalApp)));
    await container.read(authControllerProvider.notifier).logout();
    // `/account` isn't public (see above), so logging out while on it redirects
    // straight to `/login` — no need to navigate there again.
    await _waitUntil(tester, () => onLoginScreenFinder.evaluate().isNotEmpty);
  }

  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
  await tester.enterText(find.widgetWithText(TextFormField, 'Password'), password);
  await tester.tap(onLoginScreenFinder);
  await _settle(tester, times: 20);
}

/// Opens Search, waits for the results list, and taps the first listing.
Future<void> _openFirstSearchResult(WidgetTester tester) async {
  await tester.tap(find.text('Search'));
  await _settle(tester, times: 20);

  await tester.tap(find.byType(PropertyCard).first);
  await _settle(tester, times: 20);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('browse: guest can search and open a listing', (tester) async {
    _ignoreImageLoadErrors();
    await _pumpApp(tester);

    await _openFirstSearchResult(tester);

    // Listing Detail rendered real data: a price line (NprFormatter prefixes
    // "Rs "), and the poster/actions section that only appears once the
    // detail payload (not just the search-card summary) has loaded.
    expect(find.textContaining('Rs '), findsWidgets);
    expect(find.text('Message owner'), findsOneWidget);
  });

  testWidgets('contact: a logged-in buyer can message the poster', (tester) async {
    _ignoreImageLoadErrors();
    await _pumpApp(tester);
    await _login(tester, email: _adminEmail, password: _adminPassword);

    await _openFirstSearchResult(tester);

    await tester.tap(find.text('Message owner'));
    await _settle(tester);

    final messageBody = 'Integration test contact ${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(find.byType(TextField).first, messageBody);
    await tester.tap(find.text('Send'));
    await _settle(tester, times: 20);

    // A successful send pops the composer and pushes /messages/{id}; the
    // just-sent body rendered back from the server is the real proof.
    expect(find.text(messageBody), findsOneWidget);
  });

  testWidgets('post: an owner can publish a new listing', (tester) async {
    _ignoreImageLoadErrors();
    await _pumpApp(tester);
    await _login(tester, email: _ownerEmail, password: _ownerPassword);

    await tester.tap(find.text('Account'));
    await _settle(tester);
    await tester.tap(find.text('My properties'));
    await _settle(tester, times: 20);

    await tester.tap(find.byType(FloatingActionButton));
    await _settle(tester, times: 20);

    // --- Step: location ---
    await _selectFirstDropdownOption<String>(tester, find.byType(DropdownButtonFormField<String>).first);
    await _selectFirstDropdownOption<int>(tester, find.byType(DropdownButtonFormField<int>).last); // province
    await _selectFirstDropdownOption<int>(tester, find.byType(DropdownButtonFormField<int>).last); // district
    await _selectFirstDropdownOption<int>(tester, find.byType(DropdownButtonFormField<int>).last); // municipality
    await _selectFirstDropdownOption<int>(tester, find.byType(DropdownButtonFormField<int>).last); // ward
    await tester.tap(find.text('Continue'));
    await _settle(tester);

    // --- Step: basics (property type was the list's first entry, 'room',
    // which needs bedroom/bathroom counts) ---
    await tester.enterText(find.widgetWithText(TextField, 'Area value'), '120');
    await _selectFirstDropdownOption<String>(tester, find.byType(DropdownButtonFormField<String>).first);
    await tester.enterText(find.widgetWithText(TextField, 'Bedrooms'), '2');
    await tester.enterText(find.widgetWithText(TextField, 'Bathrooms'), '1');
    await tester.tap(find.text('Continue'));
    await _settle(tester, times: 20); // real createProperty API call

    // --- Step: media (a real photo is required to continue) ---
    final tempFile = File('${Directory.systemTemp.path}/integration_test_photo.png')
      ..writeAsBytesSync(base64Decode(_pngBase64));
    ImagePickerPlatform.instance = _FakeImagePicker(tempFile.path);
    await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
    await _settle(tester, times: 20); // real uploadMedia API call
    await tester.tap(find.text('Continue'));
    await _settle(tester);

    // --- Step: pricing ---
    final title = 'Integration test flat ${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(find.widgetWithText(TextField, 'Price (Rs)'), '2500000');
    await tester.enterText(find.widgetWithText(TextField, 'Title'), title);
    await tester.tap(find.text('Continue'));
    await _settle(tester, times: 20); // real createListing API call

    // --- Step: review ---
    await tester.tap(find.text('Submit for review'));
    await _settle(tester, times: 20); // real transitionListing('submit') call

    // Back on the Dashboard, with the new listing's title visible.
    expect(find.text(title), findsOneWidget);
    _postedListingTitle = title;
  });

  testWidgets('moderate: an admin can approve the listing just posted', (tester) async {
    _ignoreImageLoadErrors();
    final title = _postedListingTitle;
    if (title == null) {
      fail('the "post" test must run first in this file and set _postedListingTitle');
    }

    await _pumpApp(tester);
    await _login(tester, email: _adminEmail, password: _adminPassword);

    // Both "Admin console" (a long way down AccountScreen's ListTile menu
    // for an admin) and "Listings" (behind AdminDrawer, itself opened via
    // ScaffoldState.openDrawer()) hit the exact same "widget exists but a
    // tap/hit-test on it lands elsewhere" problem already worked around
    // for "Log out" above. Same fix, generalized: drive GoRouter directly
    // from a live BuildContext instead of simulating the taps that would
    // normally get there.
    final router = GoRouter.of(tester.element(find.byType(Scaffold).last));
    router.push('/admin');
    await _settle(tester, times: 20);
    router.push('/admin/listings');
    await _settle(tester, times: 20);

    // The moderation queue defaults to the pending_review filter, which is
    // exactly the status "Submit for review" above just put this listing in.
    // Same off-screen-tap risk as above once the queue has more than a
    // couple of items (ours is oldest-first FIFO, so newest = furthest
    // down) — call the card's own InkWell.onTap instead of tapping it.
    final card = tester.widget<InkWell>(find.ancestor(of: find.text(title), matching: find.byType(InkWell)).first);
    card.onTap!();
    await _settle(tester, times: 20);

    final approveButton = tester.widget<AppButton>(find.widgetWithText(AppButton, 'Approve'));
    approveButton.onPressed!();
    await _settle(tester, times: 20);

    expect(find.text('published'), findsWidgets);
  });
}

class _FakeImagePicker extends ImagePickerPlatform {
  _FakeImagePicker(this._path);

  final String _path;

  @override
  Future<List<XFile>> getMultiImageWithOptions({MultiImagePickerOptions options = const MultiImagePickerOptions()}) async {
    return [XFile(_path)];
  }
}
