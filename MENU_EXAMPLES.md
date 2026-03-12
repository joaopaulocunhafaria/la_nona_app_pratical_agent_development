# Exemplos de Uso - Sistema de Cardápio

## 1. Começar

Certifique-se de ter atualizado as dependências:

```bash
flutter pub get
```

## 2. Acessar o Cardápio

Na `home_page.dart`, ao clicar no card "Cardápio", você será levado para a `MenuPage`:

```dart
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
)
```

## 3. Adicionar um Novo Item

Na `MenuPage`, clique no botão "+" no AppBar para adicionar um novo item.

### Passo 1: Selecionar Imagens

Clique em "Galeria" ou "Câmera" para adicionar uma ou mais imagens:

```
[Galeria] [Câmera]
    ↓
Selecione uma ou mais imagens
    ↓
Imagens aparecem como thumbnails
    ↓
Clique no X para remover uma imagem
```

### Passo 2: Preencher Informações

- **Nome**: Ex: "Hamburguer Artesanal"
- **Descrição**: Detalhes do prato
- **Preço**: Apenas números com ponto (ex: 29.90)
- **Categoria**: Selecione na lista
- **Disponível**: Toggle on/off

### Passo 3: Salvar

Clique em "Adicionar Item" para salvar.

O sistema irá:
1. Fazer upload das imagens para Firebase Storage
2. Salvar os dados no Firestore
3. Retornar para a MenuPage

## 4. Ver Detalhes de um Item

Na `MenuPage`, clique em qualquer card para abrir `MenuItemDetailPage`.

### Funcionalidades:

**Carrosel de Imagens:**
```
← [Imagem 1 de 3] →
   (arrastável)
```

- Arraste para a esquerda/direita para ver outras imagens
- Indicadores mostram qual imagem você está vendo

**Informações:**
- Nome do item
- Categoria
- Status de disponibilidade
- Descrição completa
- Preço destacado

**Adicionar ao Carrinho:**
- Botão ativo apenas se o item está disponível

## 5. Exemplos de Código

### Usando MenuItemService Diretamente

#### Obter todos os itens em tempo real:

```dart
final menuItemService = MenuItemService();

@override
Widget build(BuildContext context) {
  return StreamBuilder<List<MenuItem>>(
    stream: menuItemService.getMenuItems(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      }

      if (snapshot.hasError) {
        return Text('Erro: ${snapshot.error}');
      }

      final items = snapshot.data ?? [];
      return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text('R\$ ${item.price}'),
          );
        },
      );
    },
  );
}
```

#### Obter itens de uma categoria específica:

```dart
final menuItemService = MenuItemService();

Stream<List<MenuItem>> hamburguesStream = 
  menuItemService.getMenuItemsByCategory('Hamburguer');
```

#### Buscar um item pelo ID:

```dart
final menuItemService = MenuItemService();

MenuItem? item = await menuItemService.getMenuItem('item123');
if (item != null) {
  print('Encontrado: ${item.name}');
}
```

#### Buscar itens disponíveis:

```dart
final menuItemService = MenuItemService();

Stream<List<MenuItem>> availableItems = 
  menuItemService.getAvailableMenuItems();
```

### Usando StorageService Diretamente

#### Upload de uma imagem:

```dart
import 'dart:io';
import 'package:la_nona/data/services/storage_service.dart';

final storageService = StorageService();
final File imageFile = File('/path/to/image.jpg');

try {
  final url = await storageService.uploadMenuItemImage(
    imageFile,
    'item_123',
  );
  print('URL da imagem: $url');
} catch (e) {
  print('Erro ao fazer upload: $e');
}
```

#### Upload de múltiplas imagens:

```dart
final List<File> images = [
  File('/path/to/image1.jpg'),
  File('/path/to/image2.jpg'),
  File('/path/to/image3.jpg'),
];

try {
  final urls = await storageService.uploadMultipleImages(images, 'item_123');
  print('URLs: $urls');
} catch (e) {
  print('Erro: $e');
}
```

#### Deletar uma imagem:

```dart
final imageUrl = 'https://storage.googleapis.com/...';

try {
  await storageService.deleteImage(imageUrl);
  print('Imagem deletada');
} catch (e) {
  print('Erro ao deletar: $e');
}
```

## 6. Estrutura de Dados no Firestore

### Exemplo de Documento

Collection: `menu_items`
Document ID: `1234567890`

```json
{
  "name": "Hamburguer Artesanal",
  "description": "Pão brioche, carne grass-fed 180g, queijo cheddar, alface e tomate",
  "price": 29.90,
  "category": "Hamburguer",
  "available": true,
  "imageUrls": [
    "https://storage.googleapis.com/project.appspot.com/menu_items/1234567890/1704067200000.jpg",
    "https://storage.googleapis.com/project.appspot.com/menu_items/1234567890/1704067201000.jpg"
  ],
  "createdAt": {
    "seconds": 1704067200,
    "nanoseconds": 0
  },
  "updatedAt": {
    "seconds": 1704067200,
    "nanoseconds": 0
  }
}
```

## 7. Fluxo de Dados

### Adicionar Item

```
User clica "+"
    ↓
AddMenuItemPage abre
    ↓
User seleciona imagens
    ↓
User preenche formulário
    ↓
User clica "Salvar"
    ↓
StorageService.uploadMultipleImages()
    ├─ Upload 1 de cada imagem para: menu_items/{itemId}/{timestamp}.jpg
    └─ Retorna lista de URLs
    ↓
MenuItemService.createMenuItem()
    ├─ Cria novo MenuItem com URLs
    └─ Salva em Firestore
    ↓
Voltar para MenuPage
    ↓
MenuPage atualiza via Stream (novo item aparece)
```

### Ver Detalhes

```
User clica em um card
    ↓
MenuItemDetailPage abre
    ↓
Carrosel carrega URLs das imagens
    ↓
User arrasta para ver outras imagens
    ↓
User clica "Adicionar ao Carrinho"
    ↓
SnackBar mostra confirmação
```

## 8. Tratamento de Erros

O sistema trata os seguintes erros:

- ❌ Arquivo muito grande → Reescala antes de upload
- ❌ Sem conexão → Exception tratada
- ❌ Permissões negadas → Exception tratada
- ❌ Formulário inválido → Validação mostra erro
- ❌ Imagem não carrega → Mostra ícone de erro

## 9. Performance

**Otimizações implementadas:**

✅ **Compressão de imagem**
- Qualidade reduzida para 80% antes do upload

✅ **Lazy loading**
- Imagens carregam sob demanda
- Indicador de progresso enquanto carrega

✅ **Singleton Services**
- Apenas uma instância de cada service

✅ **Streams**
- Atualizações em tempo real sem polling

## 10. Próximos Passos

Depois de testar o sistema:

1. **Edição de itens**: Adaptar `AddMenuItemPage` para modo de edição
2. **Deletar itens**: Adicionar botão de delete na detail page
3. **Filtros**: Adicionar tabs/filtros na MenuPage por categoria
4. **Busca**: Implementar SearchBar para buscar itens
5. **Carrinho**: Implementar sistema de carrinho de compras
6. **Pedidos**: Criar sistema de pedidos

