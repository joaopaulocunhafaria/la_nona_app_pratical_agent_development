import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Armazenamento local da sessão (access token, refresh token e cache do
/// usuário), substituindo a persistência automática que o Firebase Auth fazia.
///
/// Singleton: [instance] é inicializado uma única vez no `main()` via
/// [ensureInitialized] antes de `runApp`.
class SessionStore {
  SessionStore._(this._prefs);

  static const String _tokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _userKey = 'usuario';

  final SharedPreferences _prefs;

  static SessionStore? _instance;
  static SessionStore get instance {
    final value = _instance;
    if (value == null) {
      throw StateError(
        'SessionStore não inicializado. Chame SessionStore.ensureInitialized() no main().',
      );
    }
    return value;
  }

  static Future<SessionStore> ensureInitialized() async {
    return _instance ??= SessionStore._(await SharedPreferences.getInstance());
  }

  String? get token => _prefs.getString(_tokenKey);

  String? get refreshToken => _prefs.getString(_refreshTokenKey);

  bool get hasSession => (token ?? '').isNotEmpty;

  /// Usuário em cache (JSON do `UserResponse`), usado para exibir algo no boot
  /// antes do `GET /api/users/me` confirmar/atualizar a sessão.
  Map<String, dynamic>? get cachedUser {
    final raw = _prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    await _prefs.setString(_tokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    await saveUser(user);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    // A foto pode vir como data URI base64 e estourar a cota — guarda sem ela;
    // o valor completo é rebuscado via GET /api/users/me quando necessário.
    final lightweight = Map<String, dynamic>.from(user)..['photo'] = null;
    await _prefs.setString(_userKey, jsonEncode(lightweight));
  }

  Future<void> clear() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userKey);
  }
}
