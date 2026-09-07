/// API base URL, override with `--dart-define=API_BASE_URL=http://...`.
///
/// The default assumes an Android emulator talking to a Laravel dev server
/// running on the host machine at the project's non-default port (8010):
/// `10.0.2.2` is the emulator's special alias for the host's `localhost`
/// (plain `localhost` from inside the emulator means the emulator itself).
/// A physical device on the same Wi-Fi needs the host machine's real LAN IP
/// instead — pass it via --dart-define when running on one.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8010',
  );

  static const String apiPath = '$baseUrl/api/v1';
}
