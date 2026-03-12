import 'package:cloud_firestore/cloud_firestore.dart';

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

  bool get isComplete {
    return cep.isNotEmpty &&
        rua.isNotEmpty &&
        bairro.isNotEmpty &&
        numero.isNotEmpty &&
        cidade.isNotEmpty &&
        estado.isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'cep': cep,
      'rua': rua,
      'bairro': bairro,
      'numero': numero,
      'cidade': cidade,
      'estado': estado,
      'complemento': complemento,
    };
  }

  factory UserAddress.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const UserAddress(
        cep: '',
        rua: '',
        bairro: '',
        numero: '',
        cidade: '',
        estado: '',
      );
    }

    return UserAddress(
      cep: (map['cep'] ?? '').toString(),
      rua: (map['rua'] ?? '').toString(),
      bairro: (map['bairro'] ?? '').toString(),
      numero: (map['numero'] ?? '').toString(),
      cidade: (map['cidade'] ?? '').toString(),
      estado: (map['estado'] ?? '').toString(),
      complemento: (map['complemento'] ?? '').toString(),
    );
  }
}

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String photoUrl;
  final String provider;
  final UserAddress address;
  final bool onboardingCompleted;
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
    this.createdAt,
    this.updatedAt,
  });

  bool get hasAddress => address.isComplete;

  UserProfile copyWith({
    String? uid,
    String? email,
    String? name,
    String? photoUrl,
    String? provider,
    UserAddress? address,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      address: address ?? this.address,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'provider': provider,
      'address': address.toMap(),
      'onboardingCompleted': onboardingCompleted,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return UserProfile(
      uid: (data['uid'] ?? doc.id).toString(),
      email: (data['email'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      photoUrl: (data['photoUrl'] ?? '').toString(),
      provider: (data['provider'] ?? 'google').toString(),
      address: UserAddress.fromMap(data['address'] as Map<String, dynamic>?),
      onboardingCompleted: data['onboardingCompleted'] == true,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
