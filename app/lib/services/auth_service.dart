import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:la_nona/data/api/api_client.dart';
import 'package:la_nona/data/api/api_config.dart';
import 'package:la_nona/data/api/api_exception.dart';
import 'package:la_nona/models/user_profile.dart';
import 'package:la_nona/services/chat_service.dart';
import 'package:la_nona/services/session_store.dart';
import 'package:la_nona/services/user_profile_service.dart';

/// Exceção de autenticação. Mantida por compatibilidade; a mensagem amigável
/// agora vem do backend via [ApiException].
class AuthException implements Exception {
  final String message;
  AuthException({required this.message});
  @override
  String toString() => message;
}

/// Serviço de autenticação contra a API La Nona (substitui o Firebase Auth).
///
/// - registra/loga via `POST /api/auth/{register,login,google}`;
/// - persiste o JWT + refresh token localmente ([SessionStore]);
/// - no boot, restaura a sessão e confirma com `GET /api/users/me`;
/// - encerra a sessão (logout explícito ou 401/403 vindo de qualquer request).
class AuthService extends ChangeNotifier {
  AuthService({required UserProfileService userProfileService})
      : _userProfileService = userProfileService {
    _api.onUnauthorized = _handleUnauthorized;
    _bootstrap();
  }

  final ApiClient _api = ApiClient.instance;
  final SessionStore _session = SessionStore.instance;
  final UserProfileService _userProfileService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: ApiConfig.googleServerClientId.isEmpty
        ? null
        : ApiConfig.googleServerClientId,
  );

  bool _isLoading = false;
  bool _isBootstrapping = true;
  bool _authenticated = false;
  bool _clearing = false;

  bool get isLoading => _isLoading;
  bool get isBootstrapping => _isBootstrapping;
  bool get isAuthenticated => _authenticated;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Restaura a sessão salva (se houver) e confirma com o backend.
  Future<void> _bootstrap() async {
    try {
      if (!_session.hasSession) return;

      final cached = _session.cachedUser;
      if (cached != null) {
        _userProfileService.setProfile(UserProfile.fromJson(cached));
        _authenticated = true;
        notifyListeners();
      }

      // Confirma/atualiza a sessão com o perfil completo (inclui a foto).
      await _userProfileService.refreshMe();
      _authenticated = true;
      ChatService().connect();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _clearSession();
      } else {
        // Backend fora do ar no boot: mantém a sessão otimista em cache.
        debugPrint('Falha ao confirmar sessão no boot: ${e.message}');
      }
    } catch (e) {
      debugPrint('Erro inesperado no bootstrap de sessão: $e');
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> registrar({required String email, required String senha, String? nome}) async {
    await _authenticate('/auth/register', {
      'email': email.trim(),
      'password': senha,
      if (nome != null && nome.trim().isNotEmpty) 'name': nome.trim(),
    });
  }

  Future<void> login({required String email, required String senha}) async {
    await _authenticate('/auth/login', {'email': email.trim(), 'password': senha});
  }

  Future<void> loginComGoogle() async {
    try {
      _setLoading(true);
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        throw AuthException(message: 'Login com Google foi cancelado.');
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthException(
          message: 'Não foi possível obter o token do Google. Verifique a configuração do login Google.',
        );
      }
      final response = await _api.post('/auth/google', body: {'idToken': idToken}, auth: false);
      await _storeAuth(response as Map<String, dynamic>);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _authenticate(String path, Map<String, dynamic> body) async {
    try {
      _setLoading(true);
      final response = await _api.post(path, body: body, auth: false);
      await _storeAuth(response as Map<String, dynamic>);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _storeAuth(Map<String, dynamic> response) async {
    final user = response['user'] as Map<String, dynamic>;
    await _session.saveSession(
      accessToken: response['accessToken'] as String,
      refreshToken: response['refreshToken'] as String,
      user: user,
    );
    _userProfileService.setProfile(UserProfile.fromJson(user));
    _authenticated = true;
    notifyListeners();
    ChatService().connect();
  }

  Future<void> logout() async {
    final refreshToken = _session.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      // Best-effort: revoga o refresh token no servidor; ignora falhas.
      try {
        await _api.post('/auth/logout', body: {'refreshToken': refreshToken});
      } catch (_) {}
    }
    await _clearSession();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Disparado pelo [ApiClient] quando qualquer request autenticado volta 401/403.
  void _handleUnauthorized() {
    if (_clearing || !_authenticated) return;
    // Adia para fora do ciclo de request/build atual.
    Future.microtask(_clearSession);
  }

  Future<void> _clearSession() async {
    if (_clearing) return;
    _clearing = true;
    try {
      ChatService().disconnect();
      await _session.clear();
      _userProfileService.clear();
      _authenticated = false;
      notifyListeners();
    } finally {
      _clearing = false;
    }
  }
}
