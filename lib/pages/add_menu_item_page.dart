import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:la_nona/data/models/menu_item.dart';
import 'package:la_nona/data/services/menu_item_service.dart';
import 'package:la_nona/data/services/storage_service.dart';
import 'package:la_nona/theme/app_colors.dart';

/// Página para adicionar novos itens ao cardápio
class AddMenuItemPage extends StatefulWidget {
  final MenuItem? editingItem;

  const AddMenuItemPage({
    super.key,
    this.editingItem,
  });

  @override
  State<AddMenuItemPage> createState() => _AddMenuItemPageState();
}

class _AddMenuItemPageState extends State<AddMenuItemPage> {
  final _formKey = GlobalKey<FormState>();
  final MenuItemService _menuItemService = MenuItemService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;

  bool _available = true;
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = false;

  // Categorias predefinidas
  static const List<String> _categories = [
    'Hamburguer',
    'Pizza',
    'Salada',
    'Bebida',
    'Sobremesa',
    'Acompanhamento',
    'Outro',
  ];

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.editingItem?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.editingItem?.description ?? '');
    _priceController =
        TextEditingController(text: widget.editingItem?.price.toString() ?? '');
    _categoryController =
        TextEditingController(text: widget.editingItem?.category ?? '');
    _selectedCategory = widget.editingItem?.category;
    _available = widget.editingItem?.available ?? true;
    _existingImageUrls = widget.editingItem?.imageUrls ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  /// Abre o seletor de imagens da galeria
  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 70,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var xFile in pickedFiles) {
            _selectedImages.add(File(xFile.path));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagens: $e')),
        );
      }
    }
  }

  /// Abre o seletor de imagens da câmera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao capturar imagem: $e')),
        );
      }
    }
  }

  /// Remove uma imagem selecionada
  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Remove uma imagem existente (apenas para edição)
  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  /// Salva o item do cardápio
  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adicione pelo menos uma imagem')),
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Validar inputs básicos
      final nameText = _nameController.text.trim();
      final descriptionText = _descriptionController.text.trim();
      final priceText = _priceController.text.trim();

      if (nameText.isEmpty) {
        throw Exception('Nome do item é obrigatório');
      }

      if (descriptionText.isEmpty) {
        throw Exception('Descrição do item é obrigatória');
      }

      // Validar e converter preço
      final price = double.tryParse(priceText);
      if (price == null || price <= 0) {
        throw Exception('Preço inválido: deve ser um número maior que 0');
      }

      final String itemId = widget.editingItem?.id ?? 
          DateTime.now().millisecondsSinceEpoch.toString();

      List<String> allImageUrls = [..._existingImageUrls];

      // Upload de novas imagens usando o serviço centralizado
      if (_selectedImages.isNotEmpty) {
        try {
          final newUrls = await _storageService.uploadMultipleImages(_selectedImages, itemId);
          allImageUrls.addAll(newUrls);
        } catch (_) {
          rethrow;
        }
      }

      // Cria ou atualiza o item
      final menuItem = MenuItem(
        id: itemId,
        name: nameText,
        description: descriptionText,
        price: price,
        category: _selectedCategory ?? 'Outro',
        available: _available,
        imageUrls: allImageUrls,
        createdAt: widget.editingItem?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.editingItem == null) {
        await _menuItemService.createMenuItem(menuItem);
      } else {
        await _menuItemService.updateMenuItem(menuItem);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.editingItem == null
                ? 'Item adicionado com sucesso!'
                : 'Item atualizado com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Pequeno delay antes de navegar de volta
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao salvar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 7),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editingItem == null ? 'Adicionar Item' : 'Editar Item',
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Imagens
                _buildImageSection(),
                const SizedBox(height: 24),

                /// Nome
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome do Item',
                    hintText: 'Ex: Hamburguer Artesanal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.restaurant),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                /// Descrição
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    hintText:
                        'Ex: Pão brioche, carne 180g, queijo cheddar...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Descrição é obrigatória';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                /// Preço
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Preço (R\$)',
                    hintText: 'Ex: 29.90',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.money),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Preço é obrigatório';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Preço deve ser um número válido maior que 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                /// Categoria
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione uma categoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                /// Disponibilidade
                SwitchListTile(
                  title: const Text('Disponível'),
                  value: _available,
                  onChanged: (value) {
                    setState(() {
                      _available = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                /// Botão de salvar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveMenuItem,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      widget.editingItem == null
                          ? 'Adicionar Item'
                          : 'Atualizar Item',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói a seção de imagens
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagens',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        /// Imagens existentes (para edição)
        if (_existingImageUrls.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Imagens atuais',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingImageUrls.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _existingImageUrls[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeExistingImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

        /// Imagens selecionadas (novas)
        if (_selectedImages.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Novas imagens',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImages[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeSelectedImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

        /// Botões de adicionar imagens
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImagesFromGallery,
                icon: const Icon(Icons.image),
                label: const Text('Galeria'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryLight,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Câmera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryLight,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}