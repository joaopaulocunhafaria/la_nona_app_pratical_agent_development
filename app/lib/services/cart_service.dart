import 'package:flutter/foundation.dart';

import 'package:la_nona/data/api/api_client.dart';
import 'package:la_nona/data/models/menu_item.dart';

/// Linha do carrinho (espelha o `CartItemResponse`). [menuItem] traz os dados
/// atuais do item (o backend faz JOIN; o preço é sempre o preço atual).
class CartItem {
  final String id;
  final MenuItem menuItem;
  final int quantity;
  final double subtotal;
  final DateTime? addedAt;

  CartItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    required this.subtotal,
    this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: (json['id'] ?? '').toString(),
      menuItem: MenuItem.fromJson(json['menuItem'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      addedAt: DateTime.tryParse((json['addedAt'] ?? '').toString()),
    );
  }
}

/// Carrinho do usuário autenticado, via REST (`/api/cart`).
class CartService extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  List<CartItem> _items = [];
  double _total = 0;
  bool _isLoading = false;
  bool _loaded = false;

  List<CartItem> get items => _items;
  double get total => _total;
  bool get isLoading => _isLoading;

  /// Chamado pelo provider (durante o build) quando a autenticação muda.
  /// O trabalho é adiado para fora do ciclo de build atual.
  void onAuthChanged(bool authenticated) {
    if (authenticated) {
      if (!_loaded && !_isLoading) Future.microtask(load);
    } else {
      if (_loaded || _items.isNotEmpty) Future.microtask(_reset);
    }
  }

  void _reset() {
    _items = [];
    _total = 0;
    _loaded = false;
    notifyListeners();
  }

  void _apply(dynamic cartJson) {
    final json = cartJson as Map<String, dynamic>;
    _items = (json['items'] as List<dynamic>? ?? const [])
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();
    _total = (json['total'] as num?)?.toDouble() ?? 0.0;
    _loaded = true;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _apply(await _api.get('/cart'));
    } catch (e) {
      debugPrint('Erro ao carregar carrinho: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(MenuItem item, {int quantity = 1}) async {
    _apply(await _api.post('/cart/items', body: {
      'menuItemId': item.id,
      'quantity': quantity,
    }));
  }

  /// `quantity <= 0` remove o item (regra do backend).
  Future<void> updateQuantity(String menuItemId, int quantity) async {
    _apply(await _api.put('/cart/items/$menuItemId', body: {'quantity': quantity}));
  }

  Future<void> removeFromCart(String menuItemId) async {
    _apply(await _api.delete('/cart/items/$menuItemId'));
  }

  Future<void> clearCart() async {
    await _api.delete('/cart');
    _reset();
  }
}
