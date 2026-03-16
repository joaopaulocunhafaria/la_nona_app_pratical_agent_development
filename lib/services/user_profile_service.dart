import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:la_nona/models/user_profile.dart';

class UserProfileService extends ChangeNotifier {
  UserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String usersCollection = 'users';

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static final RegExp _cepRegex = RegExp(r'^\d{8}$');

  String normalizeCep(String cep) {
    return cep.replaceAll(RegExp(r'\D'), '');
  }

  bool isValidCep(String cep) {
    return _cepRegex.hasMatch(normalizeCep(cep));
  }

  String formatCep(String cep) {
    final normalized = normalizeCep(cep);
    if (normalized.length != 8) return cep;
    return '${normalized.substring(0, 5)}-${normalized.substring(5)}';
  }

  Future<UserAddress> fetchAddressByCep(String cep) async {
    final normalized = normalizeCep(cep);

    if (!isValidCep(normalized)) {
      throw Exception('CEP inválido. Use 8 dígitos.');
    }

    final uri = Uri.parse('https://viacep.com.br/ws/$normalized/json/');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Falha ao consultar CEP. Tente novamente.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['erro'] == true) {
      throw Exception('CEP não encontrado.');
    }

    return UserAddress(
      cep: formatCep(normalized),
      rua: (data['logradouro'] ?? '').toString(),
      bairro: (data['bairro'] ?? '').toString(),
      numero: '',
      cidade: (data['localidade'] ?? '').toString(),
      estado: (data['uf'] ?? '').toString().toUpperCase(),
      complemento: '',
    );
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection(usersCollection).doc(uid);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> syncCurrentUser(User user) async {
    _setLoading(true);
    _setError(null);

    try {
      final docRef = _userDoc(user.uid);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        await docRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'provider': 'google',
          'address': const UserAddress(
            cep: '',
            rua: '',
            bairro: '',
            numero: '',
            cidade: '',
            estado: '',
            complemento: '',
          ).toMap(),
          'onboardingCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update({
          'email': user.email ?? '',
          'name': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'provider': 'google',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await watchCurrentUser(user.uid);
    } catch (e) {
      _setError('Erro ao sincronizar perfil do usuário: $e');
      debugPrint('Erro ao sincronizar usuário: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> watchCurrentUser(String uid) async {
    await _profileSubscription?.cancel();

    _profileSubscription = _userDoc(uid).snapshots().listen(
      (doc) {
        try {
          if (!doc.exists) {
            _profile = null;
          } else {
            _profile = UserProfile.fromDoc(doc);
          }
          _setError(null);
          notifyListeners();
        } catch (e, stackTrace) {
          debugPrint('Erro ao processar perfil do usuário: $e\n$stackTrace');
          _setError('Erro ao carregar perfil: $e');
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Erro na stream do perfil: $error\n$stackTrace');
        _setError('Erro ao carregar perfil: $error');
      },
    );
  }

  Future<void> saveAddress({
    required String cep,
    required String rua,
    required String bairro,
    required String numero,
    required String cidade,
    required String estado,
    String complemento = '',
  }) async {
    final current = _profile;
    if (current == null) {
      throw Exception('Perfil de usuário não carregado');
    }

    final address = UserAddress(
      cep: formatCep(cep.trim()),
      rua: rua.trim(),
      bairro: bairro.trim(),
      numero: numero.trim(),
      cidade: cidade.trim(),
      estado: estado.trim().toUpperCase(),
      complemento: complemento.trim(),
    );

    if (!address.isComplete || !isValidCep(address.cep)) {
      throw Exception('Preencha um endereço válido.');
    }

    _setLoading(true);
    _setError(null);

    try {
      await _userDoc(current.uid).update({
        'address': address.toMap(),
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _setError('Erro ao salvar endereço: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clear() async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;
    _profile = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}
