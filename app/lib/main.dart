import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:la_nona/services/auth_service.dart';
import 'package:la_nona/services/user_profile_service.dart';
import 'package:la_nona/services/cart_service.dart';
import 'package:la_nona/services/favorites_service.dart';
import 'package:la_nona/services/chat_service.dart';
import 'package:la_nona/services/session_store.dart';
import 'package:la_nona/theme/app_theme.dart';
import 'package:la_nona/widgets/auth_check.dart';

void main() async {
  // Garante que as bindings do Flutter estejam inicializadas
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar handler para erros globais não capturados
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };

  runZonedGuarded(
    () async {
      // Carrega a sessão persistida (JWT/refresh token) antes de subir o app.
      await SessionStore.ensureInitialized();
      runApp(const MyApp());
    },
    (error, stackTrace) {
      debugPrint('Erro não capturado: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Perfil do usuário (GET /api/users/me, endereço, foto, admin)
        ChangeNotifierProvider(create: (_) => UserProfileService()),
        // Autenticação (login/registro/Google + restauração de sessão)
        ChangeNotifierProxyProvider<UserProfileService, AuthService>(
          create: (context) => AuthService(
            userProfileService: context.read<UserProfileService>(),
          ),
          update: (context, userProfileService, authService) {
            return authService ??
                AuthService(userProfileService: userProfileService);
          },
        ),
        // Carrinho: carrega/limpa conforme o estado de autenticação
        ChangeNotifierProxyProvider<AuthService, CartService>(
          create: (_) => CartService(),
          update: (context, authService, cartService) {
            final service = cartService ?? CartService();
            service.onAuthChanged(authService.isAuthenticated);
            return service;
          },
        ),
        // Favoritos: idem
        ChangeNotifierProxyProvider<AuthService, FavoritesService>(
          create: (_) => FavoritesService(),
          update: (context, authService, favoritesService) {
            final service = favoritesService ?? FavoritesService();
            service.onAuthChanged(authService.isAuthenticated);
            return service;
          },
        ),
        // Chat de suporte (singleton com conexão STOMP compartilhada)
        Provider(create: (_) => ChatService()),
      ],
      child: MaterialApp(
        title: 'La Nonna',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, widget) {
          Widget error = widget ?? const SizedBox();
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            debugPrint('Widget Error: ${errorDetails.exception}');
            debugPrintStack(stackTrace: errorDetails.stack);
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Erro na Aplicação',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${errorDetails.exception}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          };
          return error;
        },
        // Home widget é o AuthCheck, que faz roteamento condicional
        home: const AuthCheck(),
      ),
    );
  }
}
