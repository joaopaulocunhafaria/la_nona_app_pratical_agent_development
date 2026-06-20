import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Utilitários para lidar com imagens vindas/enviadas à API.
///
/// O backend guarda imagens como TEXT em duas formas (ver SPRINGBOOT.md,
/// premissa 8):
/// - data URI base64: `data:image/jpeg;base64,XXXX` (uploads do usuário);
/// - URL `http(s)`: foto de perfil original do Google.
///
/// O Flutter precisa decidir como renderizar pelo prefixo — `Image.network`
/// sozinho não decodifica data URIs.

/// Retorna o [ImageProvider] adequado para [src], ou `null` se vazio/ inválido.
ImageProvider? appImageProvider(String? src) {
  if (src == null || src.isEmpty) return null;
  if (src.startsWith('data:')) {
    final bytes = _decodeDataUri(src);
    return bytes == null ? null : MemoryImage(bytes);
  }
  if (src.startsWith('http')) return NetworkImage(src);
  return null;
}

/// Widget que renderiza uma imagem da API (data URI base64 ou URL `http`),
/// com um placeholder quando a fonte é vazia/inválida ou falha ao carregar.
class AppImage extends StatelessWidget {
  final String? src;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;

  const AppImage(
    this.src, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  Widget get _placeholder =>
      placeholder ??
      Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final provider = appImageProvider(src);
    if (provider == null) return _placeholder;
    return Image(
      image: provider,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => _placeholder,
    );
  }
}

Uint8List? _decodeDataUri(String dataUri) {
  final commaIndex = dataUri.indexOf(',');
  if (commaIndex < 0) return null;
  try {
    return base64Decode(dataUri.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

/// Payload de imagem aceito pelos endpoints (`MenuItemImageRequest` e
/// `PhotoRequest` compartilham o formato base64 + contentType).
class ImagePayload {
  final String base64;
  final String contentType;

  const ImagePayload({required this.base64, required this.contentType});

  /// Para `MenuItemRequest.images` → `{base64, contentType}`.
  Map<String, dynamic> toImageRequest() => {
        'base64': base64,
        'contentType': contentType,
      };

  /// Para `PUT /api/users/me/photo` → `{imageBase64, contentType}`.
  Map<String, dynamic> toPhotoRequest() => {
        'imageBase64': base64,
        'contentType': contentType,
      };
}

/// Lê um arquivo de imagem e o converte para [ImagePayload] (base64).
Future<ImagePayload> filePayload(File file, {String contentType = 'image/jpeg'}) async {
  final bytes = await file.readAsBytes();
  return ImagePayload(base64: base64Encode(bytes), contentType: contentType);
}

/// Converte uma data URI já existente (vinda da API) de volta para o payload de
/// envio, separando o contentType do conteúdo base64. Usado ao reenviar imagens
/// já cadastradas na edição de um item.
ImagePayload? dataUriToPayload(String src) {
  if (!src.startsWith('data:')) return null;
  final commaIndex = src.indexOf(',');
  final semicolonIndex = src.indexOf(';');
  if (commaIndex < 0) return null;
  final contentType = (semicolonIndex > 5 && semicolonIndex < commaIndex)
      ? src.substring(5, semicolonIndex)
      : 'image/jpeg';
  return ImagePayload(base64: src.substring(commaIndex + 1), contentType: contentType);
}
