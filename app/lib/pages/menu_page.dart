import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:la_nona/data/api/app_image.dart';
import 'package:la_nona/data/models/menu_item.dart';
import 'package:la_nona/data/services/menu_item_service.dart';
import 'package:la_nona/services/user_profile_service.dart';
import 'package:la_nona/services/cart_service.dart';
import 'package:la_nona/services/favorites_service.dart';
import 'package:la_nona/pages/menu_item_detail_page.dart';
import 'package:la_nona/pages/add_menu_item_page.dart';
import 'package:la_nona/theme/app_colors.dart';

/// Página que exibe o cardápio (menu) da aplicação
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final MenuItemService _menuItemService = MenuItemService();
  late Future<List<MenuItem>> _menuFuture;

  @override
  void initState() {
    super.initState();
    _menuFuture = _menuItemService.getMenuItems();
  }

  void _reload() {
    setState(() {
      _menuFuture = _menuItemService.getMenuItems();
    });
  }

  void _openAddItem({MenuItem? editingItem}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddMenuItemPage(editingItem: editingItem),
          ),
        )
        .then((_) => _reload());
  }

  Future<void> _addToCart(BuildContext context, MenuItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<CartService>().addToCart(item);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${item.name} adicionado ao carrinho'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao adicionar ao carrinho: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<UserProfileService>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cardápio'),
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _openAddItem(),
              tooltip: 'Adicionar item',
            ),
        ],
      ),
      body: FutureBuilder<List<MenuItem>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text('Erro ao carregar cardápio: ${snapshot.error}'),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    color: AppColors.secondaryLight,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text('Nenhum item no cardápio ainda'),
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openAddItem(),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Primeiro Item'),
                    ),
                  ],
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.70, // Ajustado para dar mais espaço para os botões admin
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildMenuItemCard(context, item, isAdmin);
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuItemCard(BuildContext context, MenuItem item, bool isAdmin) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MenuItemDetailPage(item: item),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Imagem do item
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: SizedBox.expand(
                        child: AppImage(
                          item.imageUrls.isNotEmpty ? item.imageUrls.first : null,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // Botão de Favorito
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Consumer<FavoritesService>(
                      builder: (context, favoritesService, _) {
                        final isFavorite = favoritesService.isFavorite(item.id);
                        return GestureDetector(
                          onTap: () => favoritesService.toggleFavorite(item),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: isFavorite ? Colors.red : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (isAdmin)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Row(
                        children: [
                          _buildAdminActionButton(
                            icon: Icons.edit,
                            color: Colors.blue,
                            onTap: () => _openAddItem(editingItem: item),
                          ),
                          const SizedBox(width: 4),
                          _buildAdminActionButton(
                            icon: Icons.delete,
                            color: Colors.red,
                            onTap: () => _confirmDelete(context, item),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            /// Informações do item
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Nome
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  /// Preço e Botão Adicionar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'R\$ ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryBase,
                        ),
                      ),
                      if (item.available)
                        GestureDetector(
                          onTap: () => _addToCart(context, item),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.secondaryBase,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        const Text(
                          'Falta',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: color,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Item'),
        content: Text('Tem certeza que deseja excluir "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _menuItemService.deleteMenuItem(item.id);
                _reload();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item excluído com sucesso')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir item: $e')),
                  );
                }
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
