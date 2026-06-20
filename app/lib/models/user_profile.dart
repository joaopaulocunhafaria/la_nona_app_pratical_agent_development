/// Endereço do usuário (espelha o `AddressResponse` / colunas `address_*`).
class UserAddress {
  final String cep;
  final String rua;
  final String bairro;
  final String numero;
  final String cidade;
  final String estado;
  final String complemento;

  const UserAddress({
    required this.cep,
    required this.rua,
    required this.bairro,
    required this.numero,
    required this.cidade,
    required this.estado,
    this.complemento = '',
  });

  static const empty = UserAddress(
    cep: '',
    rua: '',
    bairro: '',
    numero: '',
    cidade: '',
    estado: '',
  );

  bool get isComplete {
    return cep.isNotEmpty &&
        rua.isNotEmpty &&
        bairro.isNotEmpty &&
        numero.isNotEmpty &&
        cidade.isNotEmpty &&
        estado.isNotEmpty;
  }

  factory UserAddress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    String s(dynamic v) => (v ?? '').toString();
    return UserAddress(
      cep: s(json['cep']),
      rua: s(json['rua']),
      bairro: s(json['bairro']),
      numero: s(json['numero']),
      cidade: s(json['cidade']),
      estado: s(json['estado']),
      complemento: s(json['complemento']),
    );
  }
}

/// Perfil do usuário autenticado (espelha o `UserResponse` do backend).
class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String photoUrl;
  final String provider;
  final UserAddress address;
  final bool onboardingCompleted;
  final bool isAdmin;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.photoUrl,
    required this.provider,
    required this.address,
    required this.onboardingCompleted,
    this.isAdmin = false,
    this.role = 'cliente',
    this.createdAt,
    this.updatedAt,
  });

  bool get hasAddress => address.isComplete;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();
    return UserProfile(
      uid: s(json['id']),
      email: s(json['email']),
      name: s(json['name']),
      photoUrl: s(json['photo']),
      provider: json['provider'] == null ? 'local' : s(json['provider']),
      address: UserAddress.fromJson(json['address'] as Map<String, dynamic>?),
      onboardingCompleted: json['onboardingCompleted'] == true,
      isAdmin: json['isAdmin'] == true || json['role'] == 'admin',
      role: json['role'] == null ? 'cliente' : s(json['role']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
