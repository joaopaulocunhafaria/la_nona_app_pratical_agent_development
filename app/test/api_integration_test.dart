// Testes de INTEGRAÇÃO do app Flutter com a API La Nona (backend Spring Boot).
//
// Exercitam a camada de cliente real do app (ApiClient + SessionStore + models
// + services) contra um backend de verdade rodando, validando a migração
// ponta a ponta (auth, perfil, cardápio, carrinho, favoritos, chat REST).
//
// Pré-requisitos:
//   1. Backend no ar (ex.: `cd backend && ./mvnw spring-boot:run`).
//   2. Rodar apontando para o backend:
//        flutter test test/api_integration_test.dart \
//          --dart-define=API_BASE_URL=http://localhost:8080
//
// Se o backend estiver offline, os testes são marcados como "skipped" (não
// falham), para não quebrar uma rodada de `flutter test` sem o servidor.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:la_nona/data/api/api_client.dart';
import 'package:la_nona/data/api/api_config.dart';
import 'package:la_nona/data/api/api_exception.dart';
import 'package:la_nona/data/models/menu_item.dart';
import 'package:la_nona/data/services/menu_item_service.dart';
import 'package:la_nona/services/cart_service.dart';
import 'package:la_nona/services/favorites_service.dart';
import 'package:la_nona/services/session_store.dart';
import 'package:la_nona/services/user_profile_service.dart';

void main() {
  final api = ApiClient.instance;
  bool backendUp = false;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SessionStore.ensureInitialized();

    try {
      await api.get('/menu-items', auth: false);
      backendUp = true;
      // ignore: avoid_print
      print('Backend acessível em ${ApiConfig.apiUrl}');
    } catch (e) {
      backendUp = false;
      // ignore: avoid_print
      print('Backend OFFLINE em ${ApiConfig.apiUrl} ($e) — testes de integração serão pulados.');
    }
  });

  Future<Map<String, dynamic>> registerNewUser() async {
    final email = 'flutter.test.${DateTime.now().microsecondsSinceEpoch}@lanona.local';
    final response = await api.post('/auth/register', auth: false, body: {
      'email': email,
      'password': 'SenhaForte123',
      'name': 'Flutter Integração',
    }) as Map<String, dynamic>;
    await SessionStore.instance.saveSession(
      accessToken: response['accessToken'] as String,
      refreshToken: response['refreshToken'] as String,
      user: response['user'] as Map<String, dynamic>,
    );
    return response;
  }

  test('auth: registro emite JWT + GET /users/me confirma o perfil', () async {
    if (!backendUp) return markTestSkipped('Backend offline');

    final auth = await registerNewUser();
    final email = (auth['user'] as Map<String, dynamic>)['email'] as String;

    expect((auth['accessToken'] as String).isNotEmpty, isTrue);
    expect((auth['refreshToken'] as String).isNotEmpty, isTrue);

    final profileService = UserProfileService();
    await profileService.refreshMe();
    expect(profileService.profile, isNotNull);
    expect(profileService.profile!.email, email);
    expect(profileService.profile!.role, 'cliente');

    // logout revoga a sessão: chamada autenticada subsequente deve falhar.
    await api.post('/auth/logout', body: {'refreshToken': SessionStore.instance.refreshToken});
    await SessionStore.instance.clear();
    expect(
      () => api.get('/users/me'),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
    );
  });

  test('cardápio: GET /api/menu-items público retorna lista', () async {
    if (!backendUp) return markTestSkipped('Backend offline');

    final items = await MenuItemService().getMenuItems();
    expect(items, isA<List<MenuItem>>());
  });

  test('carrinho + favoritos: fluxo completo (se houver itens no cardápio)', () async {
    if (!backendUp) return markTestSkipped('Backend offline');

    await registerNewUser();
    final items = await MenuItemService().getMenuItems();
    if (items.isEmpty) {
      return markTestSkipped('Cardápio vazio — crie itens como admin para cobrir este fluxo.');
    }
    final item = items.first;

    final cart = CartService();
    await cart.addToCart(item);
    await cart.load();
    expect(cart.items.any((i) => i.menuItem.id == item.id), isTrue);
    expect(cart.total, greaterThan(0));

    await cart.updateQuantity(item.id, 3);
    expect(cart.items.firstWhere((i) => i.menuItem.id == item.id).quantity, 3);

    await cart.clearCart();
    expect(cart.items, isEmpty);

    final favorites = FavoritesService();
    await favorites.load();
    await favorites.toggleFavorite(item);
    expect(favorites.isFavorite(item.id), isTrue);
    await favorites.toggleFavorite(item);
    expect(favorites.isFavorite(item.id), isFalse);

    await SessionStore.instance.clear();
  });

  test('chat: GET /api/chat/my-thread/unread-count responde para o dono', () async {
    if (!backendUp) return markTestSkipped('Backend offline');

    await registerNewUser();
    final response = await api.get('/chat/my-thread/unread-count') as Map<String, dynamic>;
    expect(response.containsKey('count'), isTrue);
    expect(response['count'], isA<int>());

    await SessionStore.instance.clear();
  });
}
