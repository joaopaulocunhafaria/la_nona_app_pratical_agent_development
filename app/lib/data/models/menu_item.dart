import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo representando um item do cardápio
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool available;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.available,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria um MenuItem a partir de um Map do Firestore
  ///
  /// Recebe o documento ID e os dados do documento
  factory MenuItem.fromMap(Map<String, dynamic> map, String id) {
    return MenuItem(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? '',
      available: map['available'] as bool? ?? true,
      imageUrls: List<String>.from(map['imageUrls'] as List<dynamic>? ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converte o MenuItem para um Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'available': available,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Cria uma cópia do MenuItem com alguns campos alterados
  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? available,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      available: available ?? this.available,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'MenuItem(id: $id, name: $name, price: $price, category: $category)';
  }
}
