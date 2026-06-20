import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import '../../services/session_store.dart';

/// Cliente HTTP central da API La Nona.
///
/// Responsabilidades (espelha o `AuthInterceptor` do cliente web Angular):
/// - injeta `Authorization: Bearer <token>` nas rotas autenticadas;
/// - desserializa JSON e normaliza erros para [ApiException] lendo a mensagem
///   amigável do backend (campo `message`);
/// - em 401/403 dispara [onUnauthorized] para a sessão ser encerrada.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  static const Duration _timeout = Duration(seconds: 30);

  /// Chamado quando uma resposta autenticada volta 401/403 — o [AuthService]
  /// registra aqui a limpeza da sessão.
  void Function()? onUnauthorized;

  Map<String, String> _headers({bool withBody = false, bool auth = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (withBody) headers['Content-Type'] = 'application/json';
    if (auth) {
      final token = SessionStore.instance.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanQuery = query == null
        ? null
        : (Map<String, dynamic>.from(query)
              ..removeWhere((_, value) => value == null))
            .map((key, value) => MapEntry(key, '$value'));
    return Uri.parse('${ApiConfig.apiUrl}$path')
        .replace(queryParameters: cleanQuery?.isEmpty == true ? null : cleanQuery);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) {
    return _send(() => _http.get(_uri(path, query), headers: _headers(auth: auth)));
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) {
    return _send(() => _http.post(
          _uri(path),
          headers: _headers(withBody: true, auth: auth),
          body: body == null ? null : jsonEncode(body),
        ));
  }

  Future<dynamic> put(String path, {Object? body, Map<String, dynamic>? query, bool auth = true}) {
    return _send(() => _http.put(
          _uri(path, query),
          headers: _headers(withBody: body != null, auth: auth),
          body: body == null ? null : jsonEncode(body),
        ));
  }

  Future<dynamic> delete(String path, {bool auth = true}) {
    return _send(() => _http.delete(_uri(path), headers: _headers(auth: auth)));
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Tempo de conexão esgotado. Verifique sua conexão e tente novamente.');
    } catch (e) {
      debugPrint('ApiClient erro de transporte: $e');
      throw ApiException('Não foi possível conectar ao servidor. Verifique sua conexão.');
    }

    final status = response.statusCode;

    if (status >= 200 && status < 300) {
      if (response.bodyBytes.isEmpty) return null;
      final text = utf8.decode(response.bodyBytes);
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    }

    if (status == 401 || status == 403) {
      onUnauthorized?.call();
    }

    throw ApiException(_extractMessage(response, status), statusCode: status);
  }

  String _extractMessage(http.Response response, int status) {
    try {
      if (response.bodyBytes.isNotEmpty) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['message'] is String) {
          final message = (decoded['message'] as String).trim();
          if (message.isNotEmpty) return message;
        }
      }
    } catch (_) {
      // corpo não-JSON: cai no fallback por status abaixo.
    }
    if (status == 401) return 'Sessão expirada. Faça login novamente.';
    if (status == 403) return 'Você não tem permissão para esta ação.';
    if (status == 404) return 'Recurso não encontrado.';
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }
}
