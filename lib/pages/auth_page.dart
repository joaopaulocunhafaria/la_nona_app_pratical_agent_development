import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:la_nona/services/auth_service.dart';

/// Página de Login/Registro (AuthPage)
///
/// Exibida quando o usuário clica em "Entrar com Email".
/// Oferece campos para:
/// - Email
/// - Senha
/// - Toggle entre modo login e modo registro
/// - Tratamento de erros
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Controllers
  late TextEditingController _emailController;
  late TextEditingController _senhaController;

  // Estado
  bool _isLoginMode = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _senhaController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Login' : 'Criar Conta'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withAlpha(180),
              Theme.of(context).primaryColor.withAlpha(100),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Título
                  Text(
                    _isLoginMode ? 'Bem-vindo de volta!' : 'Crie sua conta',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Subtítulo
                  Text(
                    _isLoginMode
                        ? 'Entre com suas credenciais'
                        : 'Preencha os dados abaixo',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 40),

                  // Card com formulário
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Campo Email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'seu.email@example.com',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Campo Senha
                          TextField(
                            controller: _senhaController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              hintText: _isLoginMode
                                  ? 'Sua senha'
                                  : 'Mínimo 8 caracteres',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Botão Principal (Login/Registrar)
                          Consumer<AuthService>(
                            builder: (context, authService, _) {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: authService.isLoading
                                      ? null
                                      : () => _handleAuthentication(context),
                                  style: ElevatedButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    disabledBackgroundColor:
                                        Theme.of(context).primaryColor.withAlpha(
                                            128),
                                  ),
                                  child: authService.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child:
                                              CircularProgressIndicator.adaptive(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          _isLoginMode ? 'Entrar' : 'Criar Conta',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                )
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Link para alternar entre Login e Registro
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                      });
                    },
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _isLoginMode
                                ? 'Não tem conta? '
                                : 'Já tem conta? ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: _isLoginMode ? 'Crie uma' : 'Faça login',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Processa login ou registro
  Future<void> _handleAuthentication(BuildContext context) async {
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    // Validações básicas na UI
    if (email.isEmpty) {
      _showErrorSnackBar(context, 'Email não pode estar vazio');
      return;
    }
    if (!email.contains('@')) {
      _showErrorSnackBar(context, 'Email inválido');
      return;
    }
    if (senha.isEmpty) {
      _showErrorSnackBar(context, 'Senha não pode estar vazia');
      return;
    }
    if (senha.length < 6) {
      _showErrorSnackBar(context, 'Senha deve ter no mínimo 6 caracteres');
      return;
    }

    try {
      if (_isLoginMode) {
        await authService.login(email: email, senha: senha);
      } else {
        await authService.registrar(email: email, senha: senha);
      }

      if (!mounted) return;
      // Desconecta de volta à tela anterior se tudo correr bem
      // AuthCheck widget vai redirecionar para HomePage automaticamente
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(context, e.toString());
    }
  }

  /// Mostra SnackBar com mensagem de erro
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Fechar',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
