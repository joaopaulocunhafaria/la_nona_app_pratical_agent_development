/// Configuração de endpoints da API La Nona (backend Spring Boot).
///
/// A URL base é configurável em tempo de build/execução via `--dart-define`:
///
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://192.168.7.12:8080
/// ```
///
/// Padrões úteis conforme o alvo:
/// - Emulador Android: `http://10.0.2.2:8080`
/// - Aparelho físico (mesma rede Wi-Fi): `http://<IP-da-máquina>:8080`
/// - Aparelho físico via USB com `adb reverse tcp:8080 tcp:8080`: `http://localhost:8080`
/// - Desktop/Chrome no mesmo PC: `http://localhost:8080`
class ApiConfig {
  ApiConfig._();

  /// URL base do backend (sem barra final). Sobrescreva com `--dart-define`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.7.12:8080',
  );

  /// Prefixo das rotas REST.
  static String get apiUrl => '$baseUrl/api';

  /// Endpoint SockJS/STOMP do chat de suporte.
  static String get wsUrl => '$baseUrl/ws';

  /// Client ID OAuth (Web) usado para o login com Google. O backend valida o
  /// idToken contra esse mesmo Client ID (variável `GOOGLE_CLIENT_ID`). Deixe
  /// vazio enquanto o login Google não estiver configurado ponta a ponta.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
