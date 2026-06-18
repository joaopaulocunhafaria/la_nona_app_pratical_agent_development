import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:la_nona/data/models/menu_item.dart';
import 'package:la_nona/services/cart_service.dart';
import 'package:la_nona/services/favorites_service.dart';
import 'package:la_nona/theme/app_colors.dart';

/// Página que exibe os detalhes completos de um item do cardápio
class MenuItemDetailPage extends StatefulWidget {
  final MenuItem item;

  const MenuItemDetailPage({
    super.key,
    required this.item,
  });

  @override
  State<MenuItemDetailPage> createState() => _MenuItemDetailPageState();
}

class _MenuItemDetailPageState extends State<MenuItemDetailPage> {
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Item'),
        elevation: 0,
        actions: [
          Consumer<FavoritesService>(
            builder: (context, favoritesService, _) {
              final isFavorite = favoritesService.isFavorite(widget.item.id);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                onPressed: () => favoritesService.toggleFavorite(widget.item),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Carrosel de imagens
            _buildImageCarousel(),
            const SizedBox(height: 24),

            /// Informações do item
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Nome
                  Text(
                    widget.item.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  /// Categoria e disponibilidade
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoftGreen,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.secondaryLight,
                          ),
                        ),
                        child: Text(
                          widget.item.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryBase,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!widget.item.available)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.red,
                            ),
                          ),
                          child: const Text(
                            'Indisponível',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green,
                            ),
                          ),
                          child: const Text(
                            'Disponível',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  /// Descrição
                  Text(
                    'Descrição',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// Preço
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoftGreen,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preço',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryBase,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${widget.item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryBase,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Espaço extra para não ficar atrás do botão fixo
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.item.available
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<CartService>().addToCart(widget.item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.item.name} adicionado ao carrinho'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Adicionar ao Carrinho'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  /// Abre a imagem em tela cheia
  void _openFullScreenImage(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: widget.item.imageUrls.length,
            itemBuilder: (context, index) {
              return Center(
                child: Hero(
                  tag: 'image_$index',
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      widget.item.imageUrls[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Constrói o carrosel de imagens arrastável
  Widget _buildImageCarousel() {
    if (widget.item.imageUrls.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            color: Colors.grey,
            size: 64,
          ),
        ),
      );
    }

    return Column(
      children: [
        /// PageView para o carrosel
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: widget.item.imageUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openFullScreenImage(index),
                child: Container(
                  color: Colors.grey[200],
                  child: Hero(
                    tag: 'image_$index',
                    child: Image.network(
                      widget.item.imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 64,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        /// Indicadores de página
        if (widget.item.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.item.imageUrls.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? AppColors.secondaryBase
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

        /// Texto mostrando índice da imagem
        if (widget.item.imageUrls.length > 1)
          Text(
            '${_currentImageIndex + 1} de ${widget.item.imageUrls.length}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}
