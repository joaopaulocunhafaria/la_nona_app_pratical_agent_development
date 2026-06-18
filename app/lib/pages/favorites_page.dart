import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:la_nona/services/favorites_service.dart';
import 'package:la_nona/theme/app_colors.dart';
import 'package:la_nona/pages/menu_item_detail_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Favoritos'),
        elevation: 0,
      ),
      body: Consumer<FavoritesService>(
        builder: (context, favoritesService, child) {
          if (favoritesService.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Você ainda não tem favoritos',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: favoritesService.favorites.length,
            itemBuilder: (context, index) {
              final item = favoritesService.favorites[index];
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
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                color: Colors.grey[200],
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: item.imageUrls.isNotEmpty
                                    ? Image.network(
                                        item.imageUrls.first,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.image_not_supported, size: 48),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.red),
                                onPressed: () => favoritesService.toggleFavorite(item),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'R\$ ${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.secondaryBase,
                                fontWeight: FontWeight.bold,
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
          );
        },
      ),
    );
  }
}
