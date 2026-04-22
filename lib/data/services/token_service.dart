/// Manages JWT access and refresh tokens.
///
/// Currently stores tokens in memory. Swap the implementation for
/// `flutter_secure_storage` or `shared_preferences` when persistence
/// across app restarts is needed.
class TokenService {
  String? _accessToken;
  String? _refreshToken;

  Future<String?> getAccessToken() async => _accessToken;

  Future<String?> getRefreshToken() async => _refreshToken;

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  bool get hasTokens => _accessToken != null;
}
