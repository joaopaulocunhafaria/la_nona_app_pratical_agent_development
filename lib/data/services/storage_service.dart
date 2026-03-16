import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
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
      try {
        // ignore: unused_local_variable
        final app = _storage.app;
      } catch (firebaseError) {
        throw Exception('Firebase Storage não inicializado: $firebaseError');
      }
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado!');
      }
      
      if (!file.existsSync()) {
        throw Exception('Arquivo não encontrado: ${file.path}');
      }
      
      final fileSize = await file.length();
      
      if (fileSize == 0) {
        throw Exception('Arquivo vazio (tamanho = 0 bytes)');
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.jpg';
      final storagePath = 'menu_items/$itemId/$fileName';
      final ref = _storage.ref(storagePath);

      const maxRetries = 2;
      int retryCount = 0;
      
      while (retryCount <= maxRetries) {
        UploadTask? uploadTask;
        try {
          if (retryCount > 0) {
            await Future.delayed(Duration(seconds: 5 * retryCount));
          }
          
          final Uint8List fileBytes = await file.readAsBytes();
          
          final SettableMetadata metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'itemId': itemId},
          );

          uploadTask = ref.putData(fileBytes, metadata);
          
          await uploadTask.timeout(
            const Duration(seconds: 120),
            onTimeout: () async {
              try {
                await uploadTask?.cancel();
              } catch (_) {}
              throw TimeoutException('Upload timeout');
            },
          );
          
          break; // Sucesso, sair do loop
          
        } on TimeoutException catch (_) {
          retryCount++;
          if (retryCount > maxRetries) {
            throw Exception('TIMEOUT FINAL: Upload falhou após múltiplas tentativas. Verifique sua conexão.');
          }
        } catch (_) {
          rethrow;
        }
      }
      
      const maxUrlRetries = 2;
      int urlRetryCount = 0;
      
      while (urlRetryCount <= maxUrlRetries) {
        try {
          if (urlRetryCount > 0) {
            await Future.delayed(Duration(seconds: 3 * urlRetryCount));
          }
          
          final url = await ref.getDownloadURL().timeout(
            const Duration(seconds: 90),
            onTimeout: () {
              throw TimeoutException('getDownloadURL timeout');
            },
          );
          
          return url;
          
        } on TimeoutException catch (_) {
          urlRetryCount++;
          if (urlRetryCount > maxUrlRetries) {
            throw Exception('TIMEOUT: getDownloadURL falhou após múltiplas tentativas');
          }
        } catch (_) {
          rethrow;
        }
      }
      
      throw Exception('Erro: Não foi possível obter a URL após todas as tentativas');
      
    } catch (e) {
      throw Exception('Erro upload: $e');
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
      final mutableUrls = <String>[];

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        try {
          final url = await uploadMenuItemImage(file, itemId);
          mutableUrls.add(url);
        } catch (_) {
          rethrow;
        }
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
      
      await ref.delete().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('TIMEOUT: Delete excedeu 30 segundos');
        },
      );
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
      for (int i = 0; i < imageUrls.length; i++) {
        try {
          await deleteImage(imageUrls[i]);
        } catch (_) {
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Erro ao deletar imagens: $e');
    }
  }

  /// Testa a conectividade com Firebase Storage
  /// 
  /// Retorna true se a conexão está funcionando, false caso contrário
  /// Este método é útil para diagnosticar problemas de conexão
  /// 
  /// Exemplo de uso:
  /// ```dart
  /// final storage = StorageService();
  /// final isConnected = await storage.testFirebaseConnection();
  /// if (!isConnected) {
  ///   // Lidar com erro de conexão
  /// }
  /// ```
  Future<bool> testFirebaseConnection() async {
    try {
      try {
        // ignore: unused_local_variable
        final app = _storage.app;
      } catch (_) {
        return false;
      }
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }
      
      final testPath = 'connectivity-test/${DateTime.now().millisecondsSinceEpoch}.txt';
      final testRef = _storage.ref(testPath);
      
      try {
        await testRef.putString('connectivity test').timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Timeout ao fazer upload do arquivo de teste');
          },
        );
        
        await testRef.delete().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Timeout ao deletar arquivo de teste');
          },
        );
        
        return true;
      } catch (_) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }
}