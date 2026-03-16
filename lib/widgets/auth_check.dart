import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:la_nona/services/auth_service.dart';
import 'package:la_nona/pages/welcome_page.dart';
import 'package:la_nona/pages/home_page.dart';

/// Widget responsável pelo roteamento condicional baseado em autenticação
///
/// Decisões de roteamento:
/// - Se loading: exibe spinner
/// - Se usuário é null: exibe WelcomePage (tela de boas-vindas)
/// - Se usuário existe: exibe HomePage (tela principal)
///
/// Este widget é o ponto central de decisão de roteamento em toda a aplicação
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        try {
          // Mostra indicador de carregamento enquanto valida autenticação
          if (authService.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Se usuário está autenticado, exibe página principal
          if (authService.isAuthenticated) {
            return const HomePage();
          }

          // Se usuário não está autenticado, exibe página de boas-vindas
          return const WelcomePage();
        } catch (e, stackTrace) {
          debugPrint('Erro em AuthCheck: $e\n$stackTrace');
          return Scaffold(
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
                      Text(
                        'Ocorreu um erro',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Erro: $e',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Tenta recarregar
                          setState(() {});
                        },
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
