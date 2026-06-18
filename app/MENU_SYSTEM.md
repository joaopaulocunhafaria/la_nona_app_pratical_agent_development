# Sistema de Gerenciamento de Cardápio

Este documento descreve a arquitetura e uso do sistema de gerenciamento de itens de cardápio implementado no La Nonna.

## Estrutura de Pastas

```
lib/
├── data/
│   ├── models/
│   │   └── menu_item.dart          # Modelo de dados para itens do cardápio
│   └── services/
│       ├── storage_service.dart     # Serviço de upload/download no Firebase Storage
│       └── menu_item_service.dart   # Serviço de CRUD no Firestore
└── pages/
    ├── menu_page.dart              # Página principal do cardápio (grid de items)
    ├── menu_item_detail_page.dart   # Página de detalhes (com carrosel de imagens)
    └── add_menu_item_page.dart      # Página para adicionar/editar itens
```

## Componentes

### 1. Model: MenuItem

Localização: `lib/data/models/menu_item.dart`

Representa um item do cardápio com os seguintes campos:

- `id`: Identificador único
- `name`: Nome do item
- `description`: Descrição detalhada
- `price`: Preço em reais
- `category`: Categoria (Hamburguer, Pizza, Salada, etc.)
- `available`: Se está disponível para pedidos
- `imageUrls`: Lista de URLs das imagens
- `createdAt`: Data de criação
- `updatedAt`: Data da última atualização

**Métodos principais:**
- `fromMap()`: Converte dados do Firestore para MenuItem
- `toMap()`: Converte MenuItem para Map (para salvar no Firestore)
- `copyWith()`: Cria uma cópia com alguns campos alterados

### 2. Service: StorageService

Localização: `lib/data/services/storage_service.dart`

Gerencia o upload/download de imagens no Firebase Storage.

**Métodos principais:**

```dart
// Upload de uma única imagem
Future<String> uploadMenuItemImage(File file, String itemId)

// Upload de múltiplas imagens
Future<List<String>> uploadMultipleImages(List<File> files, String itemId)

// Delete de uma imagem
Future<void> deleteImage(String imageUrl)

// Delete de múltiplas imagens
Future<void> deleteImages(List<String> imageUrls)
```

**Estrutura no Storage:**
```
menu_items/
└── {itemId}/
    ├── {timestamp1}.jpg
    ├── {timestamp2}.jpg
    └── ...
```

### 3. Service: MenuItemService

Localização: `lib/data/services/menu_item_service.dart`

Gerencia operações CRUD no Firestore.

**Métodos principais:**

```dart
// Criar novo item
Future<void> createMenuItem(MenuItem item)

// Atualizar item existente
Future<void> updateMenuItem(MenuItem item)

// Deletar item (também deleta imagens do Storage)
Future<void> deleteMenuItem(String id)

// Obter um item pelo ID
Future<MenuItem?> getMenuItem(String id)

// Obter todos os itens como Stream
Stream<List<MenuItem>> getMenuItems()

// Obter itens por categoria
Stream<List<MenuItem>> getMenuItemsByCategory(String category)

// Obter apenas itens disponíveis
Stream<List<MenuItem>> getAvailableMenuItems()

// Buscar itens por nome
Future<List<MenuItem>> searchMenuItems(String query)
```

**Collection no Firestore:**
```
menu_items/
└── {documentId}/
    ├── name: string
    ├── description: string
    ├── price: number
    ├── category: string
    ├── available: boolean
    ├── imageUrls: array
    ├── createdAt: timestamp
    └── updatedAt: timestamp
```

### 4. Page: MenuPage

Localização: `lib/pages/menu_page.dart`

Exibe os itens do cardápio em um grid (2 colunas). Cada card mostra:
- Primeira imagem do item
- Nome
- Categoria
- Preço
- Status de disponibilidade

**Recursos:**
- Carregamento em tempo real via Stream
- Botão flutuante para adicionar novo item
- Tratamento de erros
- Tela vazia quando não há itens

### 5. Page: MenuItemDetailPage

Localização: `lib/pages/menu_item_detail_page.dart`

Exibe detalhes completos do item com um carrosel de imagens arrastável.

**Recursos:**
- Carrosel de imagens (PageView) arrastável
- Indicadores de página mostrando qual imagem está sendo visualizada
- Descrição completa
- Informações de preço e disponibilidade
- Botão "Adicionar ao Carrinho" (ativo apenas se disponível)
- Scroll para visualizar todo o conteúdo

### 6. Page: AddMenuItemPage

Localização: `lib/pages/add_menu_item_page.dart`

Página para adicionar ou editar itens do cardápio.

**Recursos:**
- Formulário com validação de campos
- Upload de múltiplas imagens (galeria ou câmera)
- Visualização das imagens selecionadas
- Possibilidade de remover imagens antes de salvar
- Categorias predefinidas (Hamburguer, Pizza, Salada, Bebida, Sobremesa, Acompanhamento, Outro)
- Switch para ativar/desativar disponibilidade
- Upload progressivo e feedback ao usuário

**Funcionalidades:**
- Modo de criação: novo item
- Modo de edição: editar item existente (preserva imagens antigas)
- Validação de preço (> 0)
- Validação de obrigatoriedade de campos
- Tratamento de erros

## Uso

### Adicionar um novo item

```dart
// A página AddMenuItemPage já lidar com tudo
Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMenuItemPage()));
```

### Obter todos os itens em tempo real

```dart
final menuItemService = MenuItemService();

StreamBuilder<List<MenuItem>>(
  stream: menuItemService.getMenuItems(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final items = snapshot.data ?? [];
      // Usar items
    }
  },
);
```

### Obter um item específico

```dart
final item = await MenuItemService().getMenuItem('item_id');
```

### Deletar um item

```dart
// Deleta o item também deleta suas imagens
await MenuItemService().deleteMenuItem('item_id');
```

## Boas Práticas Implementadas

✅ **Separação de Responsabilidades**
- Models possuem apenas dados
- Services lidam com lógica de negócio
- Pages lidam com UI

✅ **Tipagem Forte**
- Uso de tipos específicos (MenuItem, List<String>, etc.)
- Validação de tipos no parse de dados

✅ **Async/Await**
- Operações assíncronas bem definidas
- Streams para dados em tempo real

✅ **Tratamento de Exceções**
- Try-catch em operações críticas
- Mensagens de erro claras ao usuário

✅ **Singleton Pattern**
- Services são singletons para evitar múltiplas instâncias

✅ **Validação de Dados**
- Formulário com validação
- Verificação de campos obrigatórios
- Validação de preço

## Configuração do Firebase

### Firestore
1. Criar collection `menu_items`
2. Adicionar regras de segurança

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /menu_items/{document=**} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null;
    }
  }
}
```

### Storage
1. Habilitar Firebase Storage
2. Configurar regras de segurança

```storage
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /menu_items/{itemId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
      allow delete: if request.auth != null;
    }
  }
}
```

## Dependências Adicionadas

```yaml
firebase_storage: ^11.1.0  # Para upload/download de imagens
image_picker: ^1.0.0       # Para selecionar imagens da câmera/galeria
```

## Próximas Melhorias

- [ ] Implementar carrinho de compras
- [ ] Adicionar avaliações/comentários para itens
- [ ] Filtrar por categoria
- [ ] Busca/pesquisa de itens
- [ ] Favoritos
- [ ] Editar itens existentes
- [ ] Soft delete para itens (ao invés de deletar permanentemente)

## Troubleshooting

### Erro: "Permissão negada no Firebase Storage"
- Verificar regras de segurança do Storage
- Confirmar que o usuário está autenticado

### Erro: "Imagem não carrega"
- Verificar se a URL está correta
- Verificar permissões no Storage
- Testar URL no navegador

### Erro: "Collection não encontrada"
- Confirmar que collection `menu_items` existe no Firestore
- Verificar nome da collection (case-sensitive)

