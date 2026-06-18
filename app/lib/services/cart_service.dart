import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:la_nona/data/models/menu_item.dart';

class CartItem {
  final String id;
  final MenuItem menuItem;
  final int quantity;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'menuItem': menuItem.toMap(),
      'quantity': quantity,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map, String id) {
    return CartItem(
      id: id,
      menuItem: MenuItem.fromMap(map['menuItem'], map['menuItem']['id'] ?? ''),
      quantity: map['quantity'] ?? 1,
      addedAt: (map['addedAt'] as Timestamp).toDate(),
    );
  }
}

class CartService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  double get total => _items.fold(0, (sum, item) => sum + (item.menuItem.price * item.quantity));

  CartService() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _listenToCart(user.uid);
      } else {
        _items = [];
        notifyListeners();
      }
    });
  }

  void _listenToCart(String uid) {
    _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _items = snapshot.docs.map((doc) => CartItem.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });
  }

  Future<void> addToCart(MenuItem menuItem) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');
      
      // Check if item already exists
      final existing = await cartRef.doc(menuItem.id).get();
      
      if (existing.exists) {
        await cartRef.doc(menuItem.id).update({
          'quantity': FieldValue.increment(1),
          'addedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await cartRef.doc(menuItem.id).set({
          'menuItem': menuItem.toMap()..['id'] = menuItem.id,
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).collection('cart').doc(itemId).delete();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      if (quantity <= 0) {
        await removeFromCart(itemId);
      } else {
        await _firestore.collection('users').doc(user.uid).collection('cart').doc(itemId).update({
          'quantity': quantity,
        });
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');
      final snapshot = await cartRef.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }
}
