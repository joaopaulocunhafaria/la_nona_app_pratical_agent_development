import 'package:flutter/foundation.dart';

import 'package:la_nona/data/api/api_client.dart';
import 'package:la_nona/data/models/menu_item.dart';

/// Favoritos do usuário autenticado, via REST (`/api/favorites`).
class FavoritesService extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  List<MenuItem> _favorites = [];
  Set<String> _favoriteIds = {};
  bool _loaded = false;
  bool _loading = false;

  List<MenuItem> get favorites => _favorites;
  Set<String> get favoriteIds => _favoriteIds;

  /// Chamado pelo provider (durante o build) quando a autenticação muda.
  void onAuthChanged(bool authenticated) {
    if (authenticated) {
      if (!_loaded && !_loading) Future.microtask(load);
    } else {
      if (_loaded || _favorites.isNotEmpty) Future.microtask(_reset);
    }
  }

  void _reset() {
    _favorites = [];
    _favoriteIds = {};
    _loaded = false;
    notifyListeners();
  }

  bool isFavorite(String itemId) => _favoriteIds.contains(itemId);

  Future<void> load() async {
    _loading = true;
    try {
      final response = await _api.get('/favorites');
      _favorites = (response as List<dynamic>)
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _favoriteIds = _favorites.map((item) => item.id).toSet();
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar favoritos: $e');
    } finally {
      _loading = false;
    }
  }

  Future<void> toggleFavorite(MenuItem item) async {
    if (_favoriteIds.contains(item.id)) {
      await _api.delete('/favorites/${item.id}');
      _favorites = _favorites.where((f) => f.id != item.id).toList();
      _favoriteIds = _favoriteIds.where((id) => id != item.id).toSet();
    } else {
      await _api.post('/favorites/${item.id}');
      _favorites = [..._favorites, item];
      _favoriteIds = {..._favoriteIds, item.id};
    }
    notifyListeners();
  }
}
