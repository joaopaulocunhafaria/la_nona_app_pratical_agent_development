import 'package:flutter/material.dart';
import 'package:la_nona/models/user_profile.dart';
import 'package:la_nona/pages/menu_page.dart';
import 'package:la_nona/pages/cart_page.dart';
import 'package:la_nona/pages/favorites_page.dart';
import 'package:la_nona/pages/admin_chat_list_page.dart';
import 'package:la_nona/pages/admin_user_management_page.dart';
import 'package:la_nona/pages/support_chat_page.dart';
import 'package:la_nona/services/address_form_service.dart';
import 'package:la_nona/services/auth_service.dart';
import 'package:la_nona/services/session_service.dart';
import 'package:la_nona/services/chat_service.dart';
import 'package:la_nona/theme/app_colors.dart';
import 'package:la_nona/services/user_profile_service.dart';
import 'package:provider/provider.dart';

/// Página Principal/Dashboard (HomePage)
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
    final authService = context.watch<AuthService>();
    final userProfileService = context.watch<UserProfileService>();
    final chatService = context.read<ChatService>();
    
    final user = authService.user;
    final profile = userProfileService.profile;
    final isAdmin = profile?.isAdmin ?? false;

    // Check for onboarding
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

    return Scaffold(
      appBar: AppBar(
        leading: _buildChatIcon(context, chatService, user, isAdmin, profile),
        title: Text(
          'La Nonna',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontFamily: 'SignaturaMonoline',
            fontWeight: FontWeight.bold,
            fontSize: 60,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _sessionService.logoutWithConfirmation(context),
            tooltip: 'Sair da conta',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserCard(context, user, profile),
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
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MenuPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                Icons.shopping_cart,
                'Meus Pedidos',
                'Veja e acompanhe seus pedidos',
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CartPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                Icons.favorite,
                'Favoritos',
                'Seus pratos favoritos',
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FavoritesPage(),
                    ),
                  );
                },
              ),
              if (isAdmin) ...[
                const SizedBox(height: 12),
                _buildFeatureCard(
                  context,
                  Icons.people_alt_outlined,
                  'Gestão de Usuários',
                  'Gerenciar permissões e dados dos usuários',
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminUserManagementPage(),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentCream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentGoldSoft,
                    width: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatIcon(BuildContext context, ChatService chatService, dynamic user, bool isAdmin, UserProfile? profile) {
    return StreamBuilder<int>(
      stream: isAdmin ? chatService.getTotalUnreadCountAdmin() : (user != null ? chatService.getUnreadCountForUser(user.uid) : Stream.value(0)),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {
                if (isAdmin) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AdminChatListPage()),
                  );
                } else if (user != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SupportChatPage(
                        userId: user.uid,
                        userName: profile?.name ?? 'Cliente',
                      ),
                    ),
                  );
                }
              },
              tooltip: isAdmin ? 'Inbox de Suporte' : 'Suporte ao Cliente',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUserCard(BuildContext context, dynamic user, UserProfile? profile) {
    final displayName = profile?.name.isNotEmpty == true ? profile!.name : (user?.displayName ?? 'Não definido');
    final displayEmail = profile?.email.isNotEmpty == true ? profile!.email : (user?.email ?? 'Não definido');
    final displayPhoto = profile?.photoUrl.isNotEmpty == true ? profile!.photoUrl : user?.photoURL;

    return Card(
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
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withAlpha(180),
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
                    color: Theme.of(context).colorScheme.onPrimary,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withAlpha(76),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: displayPhoto != null && displayPhoto.isNotEmpty
                      ? Image.network(
                          displayPhoto,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.surfaceSoftGreen,
                              child: const Icon(Icons.person, size: 40),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.surfaceSoftGreen,
                          child: const Icon(Icons.person, size: 40),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Bem-vindo!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.person, 'Nome', displayName, Theme.of(context).colorScheme.onPrimary),
            const SizedBox(height: 12),
            _buildInfoRow(context, Icons.email, 'Email', displayEmail, Theme.of(context).colorScheme.onPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color.withAlpha(178), fontSize: 12)),
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, IconData icon, String title, String description, VoidCallback onTap) {
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
                child: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryLight, size: 16),
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
        color: AppColors.surfaceSoftGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondaryLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.secondaryBase),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Endereço do Usuário', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryBase)),
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
            style: const TextStyle(color: AppColors.secondaryBase),
          ),
        ],
      ),
    );
  }
}
