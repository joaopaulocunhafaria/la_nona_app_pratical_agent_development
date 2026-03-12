import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Serviço responsável por gerenciar uploads de imagens no Firebase Storage
class StorageService {
  static final StorageService _instance = StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  /// Faz upload de uma única imagem de item de cardápio
  ///
  /// Parâmetros:
  /// - [file]: Arquivo de imagem a ser enviado
  /// - [itemId]: ID do item de cardápio
  ///
  /// Retorna a URL de download da imagem
  /// 
  /// Lança exceção se o upload falhar
  Future<String> uploadMenuItemImage(File file, String itemId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.jpg';
      final ref = _storage.ref('menu_items/$itemId/$fileName');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      return url;
    } catch (e) {
      throw Exception('Erro ao fazer upload da imagem: $e');
    }
  }

  /// Faz upload de múltiplas imagens de item de cardápio
  ///
  /// Parâmetros:
  /// - [files]: Lista de arquivos de imagem
  /// - [itemId]: ID do item de cardápio
  ///
  /// Retorna uma lista com as URLs de download de todas as imagens
  ///
  /// Lança exceção se algum upload falhar
  Future<List<String>> uploadMultipleImages(
    List<File> files,
    String itemId,
  ) async {
    try {
      const List<String> urls = [];
      final mutableUrls = [...urls];

      for (final file in files) {
        final url = await uploadMenuItemImage(file, itemId);
        mutableUrls.add(url);
      }

      return mutableUrls;
    } catch (e) {
      throw Exception('Erro ao fazer upload das imagens: $e');
    }
  }

  /// Deleta uma imagem do Firebase Storage
  ///
  /// Parâmetros:
  /// - [imageUrl]: URL da imagem a ser deletada
  ///
  /// Lança exceção se a deleção falhar
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Erro ao deletar imagem: $e');
    }
  }

  /// Deleta múltiplas imagens do Firebase Storage
  ///
  /// Parâmetros:
  /// - [imageUrls]: Lista de URLs das imagens a serem deletadas
  ///
  /// Lança exceção se alguma deleção falhar
  Future<void> deleteImages(List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        await deleteImage(url);
      }
    } catch (e) {
      throw Exception('Erro ao deletar imagens: $e');
    }
  }
}
