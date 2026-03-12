import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:la_nona/services/auth_service.dart';
import 'package:la_nona/services/user_profile_service.dart';
import 'package:la_nona/widgets/auth_check.dart';
import 'firebase_options.dart';

void main() async {
  // Garante que as bindings do Flutter estejam inicializadas
  // necessário para operações assíncronas antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as opções da plataforma atual
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider global para leitura/escrita de usuários no Firestore
        ChangeNotifierProvider(create: (_) => UserProfileService()),
        // Provider para AuthService (gerencia autenticação)
        ChangeNotifierProxyProvider<UserProfileService, AuthService>(
          create: (context) => AuthService(
            userProfileService: context.read<UserProfileService>(),
          ),
          update: (context, userProfileService, authService) {
            return authService ??
                AuthService(userProfileService: userProfileService);
          },
        ),
        // Provider para UserProvider (gerencia dados do usuário)
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'La Nona',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Tema com seed color roxo
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          // Customização adicional do tema
          appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        // Home widget é o AuthCheck, que faz roteamento condicional
        home: const AuthCheck(),
      ),
    );
  }
}
