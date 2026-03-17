import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:la_nona/data/models/menu_item.dart';

class FavoritesService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Set<String> _favoriteIds = {};
  List<MenuItem> _favorites = [];
  bool _isLoading = false;

  Set<String> get favoriteIds => _favoriteIds;
  List<MenuItem> get favorites => _favorites;
  bool get isLoading => _isLoading;

  FavoritesService() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _listenToFavorites(user.uid);
      } else {
        _favoriteIds = {};
        _favorites = [];
        notifyListeners();
      }
    });
  }

  void _listenToFavorites(String uid) {
    _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
      _favoriteIds = snapshot.docs.map((doc) => doc.id).toSet();
      _favorites = snapshot.docs.map((doc) => MenuItem.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });
  }

  bool isFavorite(String itemId) {
    return _favoriteIds.contains(itemId);
  }

  Future<void> toggleFavorite(MenuItem item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore.collection('users').doc(user.uid).collection('favorites').doc(item.id);
      
      if (_favoriteIds.contains(item.id)) {
        await docRef.delete();
      } else {
        await docRef.set(item.toMap()..['id'] = item.id);
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }
}
