/// Central place for the backend base URL.
///
/// - Android emulator reaches the host machine's `localhost` via `10.0.2.2`.
/// - A physical device needs the host machine's LAN IP instead (e.g. `192.168.1.23`)
///   and the API must be started with `--urls http://0.0.0.0:5080` so it accepts
///   connections from outside the host.
/// - Production points at the same CloudFront distribution as the Angular
///   client's environment.prod.ts — keep the two in sync when either moves.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://d1303bxd595i6l.cloudfront.net/api';
}
