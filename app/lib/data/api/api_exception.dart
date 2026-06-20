/// Exceção lançada pelo [ApiClient] quando o backend responde com erro ou a
/// requisição falha no transporte.
///
/// O backend La Nona devolve mensagens amigáveis em PT-BR no campo `message`
/// do corpo de erro (ver `GlobalExceptionHandler`); [message] já carrega esse
/// texto pronto para ser exibido ao usuário.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  /// Erro de autenticação/autorização (401/403) — a sessão precisa ser refeita.
  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}
