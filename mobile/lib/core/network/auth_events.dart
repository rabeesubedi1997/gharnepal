import 'dart:async';

/// Decouples the Dio client (which has no business knowing about Riverpod)
/// from the auth session provider: the API client's 401 interceptor emits
/// here, and `AuthController` listens to force a logout — the mobile
/// equivalent of the web app's 401 interceptor treating "not logged in" as
/// a normal outcome rather than throwing (frontend/src/lib/api/client.ts).
class AuthEvents {
  AuthEvents._();

  static final _controller = StreamController<void>.broadcast();

  static Stream<void> get onUnauthorized => _controller.stream;

  static void notifyUnauthorized() => _controller.add(null);
}
