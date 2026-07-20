/// Central place for the backend base URL.
///
/// - Android emulator reaches the host machine's `localhost` via `10.0.2.2`.
/// - A physical device needs the host machine's LAN IP instead (e.g. `192.168.1.23`)
///   and the API must be started with `--urls http://0.0.0.0:5080` so it accepts
///   connections from outside the host.
/// - Swap this for a real deployed URL once the API is hosted somewhere reachable
///   from the internet.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://10.0.2.2:5080/api';
}
