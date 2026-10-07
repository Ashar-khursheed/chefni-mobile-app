import '../models/user_session.dart';
import '../network/api_client.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<UserSession> register({
    required String name,
    required String email,
    required String password,
    String countryCode = 'PK',
  }) async {
    final json = await _api.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'country_code': countryCode,
    });

    await _api.setToken(json['access_token'] as String?);
    return UserSession.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    await _api.setToken(json['access_token'] as String?);
    return UserSession.fromJson(json['user'] as Map<String, dynamic>);
  }

  /// Ask for a login code. The server answers the same way whether or not the
  /// number has an account, so this tells the caller nothing about who is
  /// registered.
  Future<void> requestOtp(String phone) async {
    await _api.post('/auth/phone/request', body: {'phone': phone});
  }

  /// Exchange a code for a session. The account is created on first verify,
  /// so there is no separate sign-up call.
  Future<UserSession> verifyOtp({
    required String phone,
    required String code,
    String? name,
    String countryCode = 'PK',
  }) async {
    final json = await _api.post('/auth/phone/verify', body: {
      'phone': phone,
      'code': code,
      if (name != null && name.isNotEmpty) 'name': name,
      'country_code': countryCode,
    });

    await _api.setToken(json['access_token'] as String?);
    return UserSession.fromJson(json['user'] as Map<String, dynamic>);
  }

  /// Restores a session from a persisted token. Returns null when there is
  /// no token or the server has revoked it.
  Future<UserSession?> restoreSession() async {
    await _api.loadToken();
    if (!_api.hasToken) return null;

    try {
      final json = await _api.get('/auth/me');
      return UserSession.fromJson(json['user'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _api.setToken(null);
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on ApiException {
      // Local sign-out proceeds even if the revoke call fails.
    }
    await _api.setToken(null);
  }

  Future<void> deleteAccount() async {
    await _api.post('/user/delete-account');
    await _api.setToken(null);
  }
}
