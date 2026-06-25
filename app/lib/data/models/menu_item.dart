/// Uma imagem de um item de cardápio (espelha o `MenuItemImageResponse`).
/// [url] é a URL pública da imagem no bucket (ou uma data URI legada de itens
/// cadastrados antes da migração para o bucket).
class MenuItemImage {
  final String id;
  final String url;
  final int position;

  const MenuItemImage({required this.id, required this.url, this.position = 0});

  factory MenuItemImage.fromJson(Map<String, dynamic> json) {
    return MenuItemImage(
      id: (json['id'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Item do cardápio (espelha o `MenuItemResponse` do backend).
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool available;
  final List<MenuItemImage> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.available,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Conveniência para a UI: lista de URLs de imagem, na ordem do carrossel.
  List<String> get imageUrls => images.map((image) => image.url).toList();

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final rawImages = (json['images'] as List<dynamic>? ?? const [])
        .map((e) => MenuItemImage.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return MenuItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: (json['category'] ?? '').toString(),
      available: json['available'] as bool? ?? true,
      images: rawImages,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() => 'MenuItem(id: $id, name: $name, price: $price)';
}
