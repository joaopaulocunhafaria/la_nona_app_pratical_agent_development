import 'package:la_nona/data/api/api_client.dart';
import 'package:la_nona/data/api/app_image.dart';
import 'package:la_nona/data/models/menu_item.dart';

/// CRUD do cardápio via REST (`/api/menu-items`). Imagens novas sobem como
/// base64 no corpo (o backend grava no bucket e devolve a URL); imagens já
/// existentes são mantidas apenas pela URL, sem reenviar o binário.
class MenuItemService {
  static final MenuItemService _instance = MenuItemService._internal();
  MenuItemService._internal();
  factory MenuItemService() => _instance;

  final ApiClient _api = ApiClient.instance;

  /// `GET /api/menu-items?category=&available=&q=` (público).
  Future<List<MenuItem>> getMenuItems({String? category, bool? available, String? query}) async {
    final response = await _api.get('/menu-items', auth: false, query: {
      if (category != null) 'category': category,
      if (available != null) 'available': available,
      if (query != null && query.isNotEmpty) 'q': query,
    });
    return (response as List<dynamic>)
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/menu-items/{id}` (público).
  Future<MenuItem> getMenuItem(String id) async {
    final response = await _api.get('/menu-items/$id', auth: false);
    return MenuItem.fromJson(response as Map<String, dynamic>);
  }

  /// Cria (POST) ou atualiza (PUT) um item — restrito a ROLE_ADMIN. A lista
  /// [images] substitui integralmente as imagens do item.
  Future<MenuItem> saveMenuItem({
    String? id,
    required String name,
    required String description,
    required double price,
    required String category,
    required bool available,
    required List<ImagePayload> images,
  }) async {
    final body = {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'available': available,
      'images': images.map((image) => image.toImageRequest()).toList(),
    };
    final response = id == null
        ? await _api.post('/menu-items', body: body)
        : await _api.put('/menu-items/$id', body: body);
    return MenuItem.fromJson(response as Map<String, dynamic>);
  }

  /// `DELETE /api/menu-items/{id}` (ROLE_ADMIN).
  Future<void> deleteMenuItem(String id) async {
    await _api.delete('/menu-items/$id');
  }
}
