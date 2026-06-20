import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:la_nona/data/api/api_client.dart';
import 'package:la_nona/data/api/app_image.dart';
import 'package:la_nona/models/user_profile.dart';
import 'package:la_nona/services/session_store.dart';

/// Perfil do usuário, endereço e gestão de usuários (admin) contra a API.
///
/// Substitui o acesso direto ao Firestore. A consulta de CEP (ViaCEP)
/// permanece client-side, exatamente como antes.
class UserProfileService extends ChangeNotifier {
  UserProfileService();

  final ApiClient _api = ApiClient.instance;

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _profile?.isAdmin ?? false;

  void setProfile(UserProfile profile) {
    _profile = profile;
    _error = null;
    notifyListeners();
  }

  void clear() {
    _profile = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CEP (ViaCEP — inalterado)
  // ---------------------------------------------------------------------------

  static final RegExp _cepRegex = RegExp(r'^\d{8}$');

  String normalizeCep(String cep) => cep.replaceAll(RegExp(r'\D'), '');

  bool isValidCep(String cep) => _cepRegex.hasMatch(normalizeCep(cep));

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

  // ---------------------------------------------------------------------------
  // Perfil
  // ---------------------------------------------------------------------------

  /// `GET /api/users/me` — confirma a sessão e atualiza o perfil em cache.
  Future<void> refreshMe() async {
    final response = await _api.get('/users/me');
    final user = response as Map<String, dynamic>;
    _profile = UserProfile.fromJson(user);
    await SessionStore.instance.saveUser(user);
    notifyListeners();
  }

  /// `PUT /api/users/me/address` (define `onboardingCompleted = true`).
  Future<void> saveAddress({
    required String cep,
    required String rua,
    required String bairro,
    required String numero,
    required String cidade,
    required String estado,
    String complemento = '',
  }) async {
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
    _error = null;
    try {
      final response = await _api.put('/users/me/address', body: {
        'cep': address.cep,
        'rua': address.rua,
        'bairro': address.bairro,
        'numero': address.numero,
        'cidade': address.cidade,
        'estado': address.estado,
        'complemento': address.complemento,
      });
      _applyUser(response as Map<String, dynamic>);
    } finally {
      _setLoading(false);
    }
  }

  /// `PUT /api/users/me/photo` — recebe a imagem já em base64.
  Future<void> updateProfilePhoto(ImagePayload payload) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _api.put('/users/me/photo', body: payload.toPhotoRequest());
      _applyUser(response as Map<String, dynamic>);
    } finally {
      _setLoading(false);
    }
  }

  void _applyUser(Map<String, dynamic> user) {
    _profile = UserProfile.fromJson(user);
    SessionStore.instance.saveUser(user);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Admin — gestão de usuários
  // ---------------------------------------------------------------------------

  /// `GET /api/admin/users?search=` (ROLE_ADMIN).
  Future<List<UserProfile>> getUsers({String? search}) async {
    final response = await _api.get(
      '/admin/users',
      query: {if (search != null && search.isNotEmpty) 'search': search},
    );
    return (response as List<dynamic>)
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `PUT /api/admin/users/{id}/role` (ROLE_ADMIN).
  Future<void> updateUserRole(String userId, String newRole) async {
    await _api.put('/admin/users/$userId/role', body: {'role': newRole});
  }
}
