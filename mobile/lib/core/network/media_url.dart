import 'api_config.dart';

/// The backend returns fully-qualified media URLs built from its own
/// `APP_URL` (correct for a browser on the same host, e.g.
/// `http://localhost:8010/storage/...`). Android can't resolve that from
/// inside an emulator or a physical device — only `ApiConfig.baseUrl`
/// (10.0.2.2, or a LAN IP on a real device) is reachable. Rewrite the
/// scheme+host+port of any such URL to match, leaving the path untouched.
/// In production, where `APP_URL` matches the real public domain and
/// `API_BASE_URL` is set to the same, this is a no-op.
String resolveMediaUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasAuthority) return url;

  final isLoopback = uri.host == 'localhost' || uri.host == '127.0.0.1';
  if (!isLoopback) return url;

  final target = Uri.parse(ApiConfig.baseUrl);
  return uri.replace(scheme: target.scheme, host: target.host, port: target.port).toString();
}
