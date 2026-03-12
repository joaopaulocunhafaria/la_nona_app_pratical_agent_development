import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:la_nona/services/user_profile_service.dart';

/// Exceção personalizada para erros de autenticação
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException({required this.message, this.code});

  @override
  String toString() => message;
}

/// Provider para gerenciar informações do usuário autenticado
class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;
  String? get userEmail => _user?.email;
  String? get userName => _user?.displayName;
  String? get userPhotoUrl => _user?.photoURL;
  String? get userId => _user?.uid;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}

/// Serviço de autenticação com Firebase
///
/// Responsabilidades:
/// - Gerenciar registro de usuários
/// - Gerenciar login por email/senha
/// - Gerenciar login com Google
/// - Gerenciar logout
/// - Monitorar mudanças de estado de autenticação
/// - Persistir sessão entre compartimentalizações
class AuthService extends ChangeNotifier {
  AuthService({required UserProfileService userProfileService})
    : _userProfileService = userProfileService {
    _authCheck();
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserProfileService _userProfileService;

  User? _user;
  bool _isLoading = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  /// Monitora mudanças no estado de autenticação do Firebase
  /// Chamado automaticamente no construtor e enquanto o app está em execução
  void _authCheck() {
    _firebaseAuth.authStateChanges().listen((User? user) async {
      _user = user;
      try {
        if (user != null) {
          await _userProfileService.syncCurrentUser(user);
        } else {
          await _userProfileService.clear();
        }
      } catch (e) {
        debugPrint('Falha ao sincronizar usuário no Firestore: $e');
      }
      notifyListeners();
    });
  }

  /// Define o estado de carregamento
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Registra um novo usuário com email e senha
  ///
  /// Parâmetros:
  /// - email: email do usuário
  /// - senha: senha do usuário (mínimo 8 caracteres, deve conter maiúsculas/minúsculas/números)
  ///
  /// Lança AuthException em caso de erro
  Future<void> registrar({required String email, required String senha}) async {
    try {
      _setLoading(true);

      // Validações básicas
      if (email.isEmpty) {
        throw AuthException(message: 'Email não pode estar vazio');
      }
      if (senha.isEmpty) {
        throw AuthException(message: 'Senha não pode estar vazia');
      }
      if (senha.length < 8) {
        throw AuthException(message: 'Senha deve ter no mínimo 8 caracteres');
      }

      // Cria novo usuário no Firebase
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: senha);

      _user = userCredential.user;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(message: 'Erro ao registrar: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Autentica um usuário existente com email e senha
  ///
  /// Parâmetros:
  /// - email: email do usuário
  /// - senha: senha do usuário
  ///
  /// Lança AuthException em caso de erro
  Future<void> login({required String email, required String senha}) async {
    try {
      _setLoading(true);

      // Validações básicas
      if (email.isEmpty) {
        throw AuthException(message: 'Email não pode estar vazio');
      }
      if (senha.isEmpty) {
        throw AuthException(message: 'Senha não pode estar vazia');
      }

      // Autentica com Firebase
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: senha);

      _user = userCredential.user;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(message: 'Erro ao fazer login: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Autentica um usuário usando Google Sign-In
  ///
  /// Lança AuthException em caso de erro
  Future<void> loginComGoogle() async {
    try {
      _setLoading(true);

      // Faz o sign-in com Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException(message: 'Login com Google foi cancelado');
      }

      // Obtém as credenciais de autenticação
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Cria credencial do Firebase usando token do Google
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Autentica no Firebase com as credenciais do Google
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      _user = userCredential.user;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(
        message: 'Erro ao fazer login com Google: ${e.toString()}',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Realiza logout do usuário atual
  ///
  /// Desconecta do Firebase e também do Google Sign-In se foi usado
  Future<void> logout() async {
    try {
      _setLoading(true);
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await _userProfileService.clear();
      _user = null;
      notifyListeners();
    } catch (e) {
      throw AuthException(message: 'Erro ao fazer logout: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Trata exceções do Firebase e as converte em AuthException com mensagens amigáveis
  void _handleFirebaseAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'weak-password':
        message =
            'Senha fraca. Use pelo menos 8 caracteres com maiúsculas, minúsculas e números.';
        break;
      case 'email-already-in-use':
        message = 'Email já está cadastrado. Tente fazer login.';
        break;
      case 'invalid-email':
        message = 'Email inválido.';
        break;
      case 'user-disabled':
        message = 'Usuário foi desabilitado.';
        break;
      case 'user-not-found':
        message = 'Usuário não encontrado. Crie uma conta primeiro.';
        break;
      case 'wrong-password':
        message = 'Senha incorreta.';
        break;
      case 'operation-not-allowed':
        message = 'Operação não permitida. Contate o suporte.';
        break;
      case 'too-many-requests':
        message = 'Muitas tentativas de login. Tente novamente mais tarde.';
        break;
      default:
        message = 'Erro de autenticação: ${e.message}';
    }

    throw AuthException(message: message, code: e.code);
  }
}
