import 'package:flutter/material.dart';
import 'package:la_nona/models/user_profile.dart';
import 'package:la_nona/services/address_form_service.dart';
import 'package:la_nona/services/auth_service.dart';
import 'package:la_nona/services/session_service.dart';
import 'package:la_nona/services/user_profile_service.dart';
import 'package:provider/provider.dart';

/// Página Principal/Dashboard (HomePage)
///
/// Exibida quando o usuário está autenticado.
/// Mostra:
/// - Informações do usuário autenticado
/// - Conteúdo principal da aplicação
/// - Botão de Logout
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _addressModalShown = false;
  final AddressFormService _addressFormService = const AddressFormService();
  final SessionService _sessionService = const SessionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('La Nona'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _sessionService.logoutWithConfirmation(context),
            tooltip: 'Sair da conta',
          ),
        ],
      ),
      body: Consumer2<AuthService, UserProfileService>(
        builder: (context, authService, userProfileService, _) {
          final user = authService.user;
          final profile = userProfileService.profile;

          if (authService.isAuthenticated &&
              profile != null &&
              !profile.onboardingCompleted &&
              !_addressModalShown) {
            _addressModalShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _addressFormService.showAddressModal(
                context,
                userProfileService: userProfileService,
                initialAddress: profile.address,
                isFirstAccess: true,
              );
            });
          }

          final displayName = profile?.name.isNotEmpty == true
              ? profile!.name
              : (user?.displayName ?? 'Não definido');
          final displayEmail = profile?.email.isNotEmpty == true
              ? profile!.email
              : (user?.email ?? 'Não definido');
          final displayPhoto = profile?.photoUrl.isNotEmpty == true
              ? profile!.photoUrl
              : user?.photoURL;
          final shortUid = user?.uid != null && user!.uid.length > 8
              ? '${user.uid.substring(0, 8)}...'
              : (user?.uid ?? 'Não definido');

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withAlpha(180),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(76),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child:
                                    displayPhoto != null &&
                                        displayPhoto.isNotEmpty
                                    ? Image.network(
                                        displayPhoto,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                      )
                                    : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.person,
                                          size: 40,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              'Bem-vindo!',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            context,
                            Icons.person,
                            'Nome',
                            displayName,
                            Colors.white,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            Icons.email,
                            'Email',
                            displayEmail,
                            Colors.white,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            Icons.verified_user,
                            'ID do Usuário',
                            shortUid,
                            Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (profile != null) _buildAddressCard(context, profile),
                  const SizedBox(height: 32),
                  Text(
                    'Conteúdo Principal',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    Icons.restaurant_menu,
                    'Cardápio',
                    'Explore nosso cardápio completo',
                    () {},
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    context,
                    Icons.shopping_cart,
                    'Meus Pedidos',
                    'Veja e acompanhe seus pedidos',
                    () {},
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    context,
                    Icons.favorite,
                    'Favoritos',
                    'Seus pratos favoritos',
                    () {},
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Text(
                              'Informações de Autenticação',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Você está conectado com segurança usando Firebase Authentication. '
                          'Sua sessão é automaticamente sincronizada em todos os seus dispositivos.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: color.withAlpha(178), fontSize: 12),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, UserProfile profile) {
    final address = profile.address;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.green[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Endereço do Usuário',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final userProfileService = context.read<UserProfileService>();
                  _addressFormService.showAddressModal(
                    context,
                    userProfileService: userProfileService,
                    initialAddress: profile.address,
                    isFirstAccess: false,
                  );
                },
                icon: const Icon(Icons.edit_location_alt, size: 18),
                label: const Text('Atualizar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile.onboardingCompleted
                ? '${address.rua}, ${address.numero} - ${address.bairro}, ${address.cidade}/${address.estado}. CEP: ${address.cep}${address.complemento.isNotEmpty ? ' (${address.complemento})' : ''}'
                : 'Endereço ainda não cadastrado.',
            style: TextStyle(color: Colors.green[700]),
          ),
        ],
      ),
    );
  }
}
