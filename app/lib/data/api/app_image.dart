import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Utilitários para lidar com imagens vindas/enviadas à API.
///
/// O backend guarda apenas a URL `http(s)` da imagem: uploads do usuário vão
/// para o bucket (S3) e somente a URL pública é persistida; a foto do Google
/// já é uma URL. Itens antigos podem ainda trazer uma data URI base64 legada
/// (`data:image/jpeg;base64,XXXX`), então o Flutter ainda decide como renderizar
/// pelo prefixo — `Image.network` sozinho não decodifica data URIs.

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

/// Payload de imagem aceito pelos endpoints de cardápio/perfil. Pode ser:
/// - uma imagem **nova** a enviar ([base64] + [contentType]); o backend faz o
///   upload para o bucket e devolve a URL pública;
/// - uma imagem **já existente** a manter na edição ([url]); nada é reenviado.
class ImagePayload {
  final String? url;
  final String? base64;
  final String? contentType;

  /// Imagem já armazenada no bucket, mantida na edição de um item.
  const ImagePayload.existing(this.url)
      : base64 = null,
        contentType = null;

  /// Imagem nova a enviar ao backend (será gravada no bucket).
  const ImagePayload.upload({required this.base64, required this.contentType}) : url = null;

  bool get isExisting => url != null && url!.isNotEmpty;

  /// Para `MenuItemRequest.images` → `{url}` (existente) ou `{base64, contentType}` (nova).
  Map<String, dynamic> toImageRequest() => isExisting
      ? {'url': url}
      : {
          'base64': base64,
          'contentType': contentType,
        };

  /// Para `PUT /api/users/me/photo` → `{imageBase64, contentType}` (sempre upload).
  Map<String, dynamic> toPhotoRequest() => {
        'imageBase64': base64,
        'contentType': contentType,
      };
}

/// Lê um arquivo de imagem e o converte para um [ImagePayload] de upload (base64).
Future<ImagePayload> filePayload(File file, {String contentType = 'image/jpeg'}) async {
  final bytes = await file.readAsBytes();
  return ImagePayload.upload(base64: base64Encode(bytes), contentType: contentType);
}
