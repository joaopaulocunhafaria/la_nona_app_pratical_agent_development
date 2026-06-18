import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:la_nona/data/models/menu_item.dart';
import 'package:la_nona/data/services/storage_service.dart';

/// Serviço responsável por gerenciar operações de itens de cardápio no Firestore
class MenuItemService {
  static final MenuItemService _instance = MenuItemService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  static const String _collectionName = 'menu_items';

  MenuItemService._internal();

  factory MenuItemService() {
    return _instance;
  }

  /// Cria um novo item de cardápio no Firestore
  ///
  /// Atualiza o timestamp de criação e modificação
  ///
  /// Lança exceção se a criação falhar
  Future<void> createMenuItem(MenuItem item) async {
    try {
      final now = DateTime.now();
      final itemWithTimestamps = item.copyWith(
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_collectionName)
          .doc(item.id)
          .set(itemWithTimestamps.toMap());
    } catch (e) {
      throw Exception('Erro ao criar item de cardápio: $e');
    }
  }

  /// Atualiza um item de cardápio existente no Firestore
  ///
  /// Atualiza apenas o timestamp de modificação
  ///
  /// Lanza exceção se a atualização falhar
  Future<void> updateMenuItem(MenuItem item) async {
    try {
      final itemWithTimestamp = item.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collectionName)
          .doc(item.id)
          .update(itemWithTimestamp.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar item de cardápio: $e');
    }
  }

  /// Deleta um item de cardápio do Firestore
  ///
  /// Também deleta todas as imagens associadas do Storage
  ///
  /// Lanza exceção se a deleção falhar
  Future<void> deleteMenuItem(String id) async {
    try {
      // Busca o item para obter as URLs das imagens
      final item = await getMenuItem(id);

      // Deleta as imagens do Storage
      if (item != null && item.imageUrls.isNotEmpty) {
        await _storageService.deleteImages(item.imageUrls);
      }

      // Deleta o documento do Firestore
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao deletar item de cardápio: $e');
    }
  }

  /// Obtém um item de cardápio pelo ID
  ///
  /// Retorna null se o item não for encontrado
  ///
  /// Lanza exceção se a busca falhar
  Future<MenuItem?> getMenuItem(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();

      if (!doc.exists) {
        return null;
      }

      return MenuItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Erro ao buscar item de cardápio: $e');
    }
  }

  /// Obtém todos os itens de cardápio como um Stream
  ///
  /// Permite atualização em tempo real
  ///
  /// Retorna um Stream com uma lista de MenuItems
  Stream<List<MenuItem>> getMenuItems() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MenuItem.fromMap(
              doc.data(),
              doc.id,
            );
          }).toList();
        })
        .handleError((e) {
          throw Exception('Erro ao buscar itens de cardápio: $e');
        });
  }

  /// Obtém itens de cardápio por categoria
  ///
  /// Retorna um Stream com uma lista de MenuItems da categoria especificada
  Stream<List<MenuItem>> getMenuItemsByCategory(String category) {
    return _firestore
        .collection(_collectionName)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MenuItem.fromMap(
              doc.data(),
              doc.id,
            );
          }).toList();
        })
        .handleError((e) {
          throw Exception('Erro ao buscar itens por categoria: $e');
        });
  }

  /// Obtém apenas itens disponíveis
  ///
  /// Retorna um Stream com uma lista de MenuItems disponíveis
  Stream<List<MenuItem>> getAvailableMenuItems() {
    return _firestore
        .collection(_collectionName)
        .where('available', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MenuItem.fromMap(
              doc.data(),
              doc.id,
            );
          }).toList();
        })
        .handleError((e) {
          throw Exception('Erro ao buscar itens disponíveis: $e');
        });
  }

  /// Busca itens de cardápio por nome
  ///
  /// Retorna um Future com uma lista de MenuItems que correspondem à busca
  Future<List<MenuItem>> searchMenuItems(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('name')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();

      return snapshot.docs.map((doc) {
        return MenuItem.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar itens de cardápio: $e');
    }
  }
}
