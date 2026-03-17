import 'package:flutter/material.dart';
import 'package:la_nona/models/user_profile.dart';
import 'package:la_nona/services/user_profile_service.dart';
import 'package:la_nona/theme/app_colors.dart';
import 'package:provider/provider.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final userProfileService = context.watch<UserProfileService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Usuários'),
        backgroundColor: AppColors.primaryBase,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.surfaceSoftGreen,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: userProfileService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                final users = snapshot.data ?? [];
                final filteredUsers = users.where((user) {
                  return user.name.toLowerCase().contains(_searchQuery) ||
                      user.email.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('Nenhum usuário encontrado.'));
                }

                return ListView.separated(
                  itemCount: filteredUsers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserTile(context, user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, UserProfile user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
        child: user.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
      ),
      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          _buildRoleChip(user.role),
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showUserDetailDialog(context, user),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    String label;

    switch (role) {
      case 'admin':
        color = Colors.red.shade700;
        label = 'Admin';
        break;
      case 'entregador':
        color = Colors.blue.shade700;
        label = 'Entregador';
        break;
      case 'cliente':
      default:
        color = Colors.green.shade700;
        label = 'Cliente';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showUserDetailDialog(BuildContext context, UserProfile user) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedRole = user.role;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Detalhes do Usuário'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                        child: user.photoUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem('Nome', user.name),
                    _buildDetailItem('Email', user.email),
                    _buildDetailItem('Provedor', user.provider),
                    const Divider(),
                    const Text('Endereço:', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (user.onboardingCompleted)
                      Text(
                        '${user.address.rua}, ${user.address.numero}\n'
                        '${user.address.bairro}\n'
                        '${user.address.cidade}/${user.address.estado}\n'
                        'CEP: ${user.address.cep}'
                        '${user.address.complemento.isNotEmpty ? '\nComp: ${user.address.complemento}' : ''}',
                        style: const TextStyle(fontSize: 14),
                      )
                    else
                      const Text('Endereço não cadastrado', style: TextStyle(fontStyle: FontStyle.italic)),
                    const Divider(),
                    const Text('Cargo/Função:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                        DropdownMenuItem(value: 'entregador', child: Text('Entregador')),
                        DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedRole = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBase,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (selectedRole != user.role) {
                      try {
                        await context.read<UserProfileService>().updateUserRole(user.uid, selectedRole);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cargo atualizado com sucesso!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao atualizar: $e')),
                          );
                        }
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Salvar Alterações'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
