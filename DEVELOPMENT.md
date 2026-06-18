# DEVELOPMENT.md

Documentação central do monorepo **La Nona**: o que já foi implementado em cada subprojeto e os padrões de desenvolvimento que devem ser seguidos a partir de agora. Para profundidade total, este arquivo aponta para a documentação específica de cada subprojeto em vez de duplicá-la.

---

## 1. Visão geral

O repositório é um **monorepo** com dois subprojetos independentes:

```
la_nona/
├── app/        App Flutter (cliente) — hoje fala direto com Firebase
├── backend/    API Spring Boot (nova) — implementada e testada, ainda não consumida pelo app
└── DEVELOPMENT.md   este arquivo
```

**Estado atual da migração**: o backend novo está **implementado e testado por completo** (ver seção 3.2), mas o app Flutter **ainda não foi alterado** — continua falando diretamente com Firebase Authentication/Firestore/Storage. Trocar os `services` Dart do app para consumir a API REST/WebSocket nova é o próximo passo do projeto (ver seção 8).

Cada subprojeto mantém sua própria documentação detalhada:

| Onde | O que documenta |
|---|---|
| [`app/CLAUDE.md`](./app/CLAUDE.md) | Arquitetura e convenções do app Flutter |
| [`app/MODELS.md`](./app/MODELS.md) | Modelagem de dados no Firestore |
| [`app/CHAT.md`](./app/CHAT.md) | Sistema de chat de suporte (Firestore) |
| [`backend/SPRINGBOOT.md`](./backend/SPRINGBOOT.md) | Plano de migração completo: mapeamento Firebase → API, modelagem Postgres, decisões e lições aprendidas durante a implementação |
| [`backend/README.md`](./backend/README.md) | Como subir, configurar e testar o backend |

---

## 2. O que foi implementado

### 2.1 App Flutter (`app/`)

Já existia antes da criação do backend; resumo rápido (detalhes em `app/CLAUDE.md`):

- Autenticação por email/senha e Google (Firebase Auth).
- Perfil de usuário com onboarding obrigatório de endereço (Firestore + busca de CEP via ViaCEP).
- Catálogo de cardápio com upload de imagens (Firestore + Firebase Storage).
- Carrinho e favoritos (subcoleções Firestore por usuário).
- Chat de suporte cliente ↔ admin em tempo real (Firestore snapshots).
- Área administrativa: gestão de cardápio e gestão de usuários/cargos.

### 2.2 Backend Spring Boot (`backend/`)

Implementado nesta etapa, em 8 fases (todas concluídas, `mvn clean verify` passando com 27 testes — 0 falhas). Stack: **Java 17, Spring Boot 3.5.x, PostgreSQL, Flyway, Spring Security, JWT**.

| Fase | Entregável |
|---|---|
| Schema | 8 migrations Flyway (`users`, `refresh_tokens`, `menu_items`, `menu_item_images`, `cart_items`, `favorites`, `chat_threads`, `chat_messages`), isoladas no schema dedicado `la_nona_api` |
| Autenticação | Registro/login local (BCrypt) + login Google (`GoogleIdTokenVerifier`), JWT de acesso + refresh token rotativo/revogável, logout |
| Perfil & Admin | `GET/PUT /api/users/me*` (endereço com validação de CEP/UF/número, foto como data URI base64); `GET/PUT /api/admin/users*` (busca, troca de cargo) |
| Cardápio | CRUD completo de `menu_items` com imagens em base64, filtros por categoria/disponibilidade/nome, leitura pública e escrita restrita a `ROLE_ADMIN` |
| Carrinho & Favoritos | Adicionar/atualizar/remover itens, total sempre calculado pelo preço **atual** do item (não snapshot); favoritos idempotentes |
| Chat | REST (threads, histórico paginado, contagem de não lidos, marcar como lido) + WebSocket/STOMP autenticado para envio/recebimento em tempo real, com RBAC cliente/admin |
| Testes | Testes unitários (Mockito) das regras de negócio + testes de integração (Testcontainers, Postgres real) para auth, cardápio, carrinho e chat |

Endpoints, modelagem completa e decisões técnicas (inclusive bugs reais encontrados e corrigidos durante a implementação) estão detalhados em `backend/SPRINGBOOT.md`, seções 2, 3, 6 e 11.

---

## 3. Padrões de desenvolvimento — App Flutter (`app/`)

Resumo das regras a seguir (detalhe completo em `app/CLAUDE.md`):

- **Dois níveis de service**: `lib/services/` para regras de negócio/estado que a UI consome via `Provider`; `lib/data/services/` para chamadas Firestore/Storage de baixo nível. Uma nova feature Firestore segue esse mesmo split.
- **Toda chamada assíncrona ao Firebase tem timeout explícito** e tratamento de erro com mensagem amigável em PT-BR — não existe camada global de tradução de erro.
- **Imagens são sempre compactadas no cliente (qualidade 80%) antes do upload.**
- **`isAdmin` no documento do usuário é o único sinal de autorização na UI** — não criar um novo campo de papel paralelo.
- Roteamento é feito por `Navigator` direto (sem rotas nomeadas); `AuthCheck` é o único ponto de decisão entre `WelcomePage`/`HomePage`.
- Não há cobertura de testes real (`test/widget_test.dart` é o template padrão do Flutter, não reflete a UI do app) — não assumir que ele é uma baseline válida.

---

## 4. Padrões de desenvolvimento — Backend Spring Boot (`backend/`)

Regras estabelecidas durante a implementação e que devem ser mantidas em qualquer código novo neste subprojeto.

### 4.1 Arquitetura em camadas
`controller → service → repository → entity`, sempre.
- Controllers nunca acessam `repository` diretamente, nem recebem/devolvem entidades JPA — sempre via DTO (`dto/request`, `dto/response`).
- Toda regra de negócio (validação, cálculo, RBAC que depende de dados) vive em `service/`, nunca no controller.

### 4.2 Entidades JPA
- Lombok (`@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder`); use `@Builder.Default` em todo campo que tem valor padrão (ex.: `role`, `available`, `revoked`), senão o builder grava `null`/zero-value silenciosamente.
- Chave primária sempre `@GeneratedValue(strategy = GenerationType.UUID)` — nunca depender do `DEFAULT` do banco para gerar o ID.
- Quando o valor salvo no banco não é uma serialização 1:1 do `name()` do enum (ex.: `Role.ADMIN` → `'admin'`, `MenuCategory.HAMBURGUER` → `'Hamburguer'`), criar um `AttributeConverter` dedicado (`RoleConverter`, `AuthProviderConverter`, `MenuCategoryConverter` são os exemplos existentes) em vez de forçar `@Enumerated(EnumType.STRING)`.
- Relacionamento onde a chave primária também é chave estrangeira (ex.: `ChatThread.userId` = `users.id`): usar `@OneToOne` + `@MapsId`, não duplicar a coluna.

### 4.3 DTOs
- Sempre `record` Java (request e response) — não usar classes mutáveis para DTO.
- Validação via Jakarta Bean Validation direto nos componentes do record (`@NotBlank`, `@Email`, `@DecimalMin`, `@NotEmpty` em listas com `List<@Valid X>`).
- DTOs de resposta têm um método estático `from(Entity)` que faz a conversão — a entidade nunca atravessa a fronteira do controller.

### 4.4 Tratamento de erros
- Hierarquia única: `ApiException` (abstrata) com uma subclasse por status HTTP (`BadRequestException` → 400, `ConflictException` → 409, `UnauthorizedException` → 401, `ForbiddenException` → 403, `ResourceNotFoundException` → 404). Nunca lançar `RuntimeException`/`Exception` genérica para um erro de negócio esperado.
- `GlobalExceptionHandler` (`@RestControllerAdvice`) é o único lugar que traduz exceção → resposta HTTP. Ele também trata `ErrorResponseException` (classe-base das exceções nativas do Spring MVC, como rota inexistente) para preservar o status real em vez de cair no 500 genérico — ao adicionar um novo tipo de erro nativo do framework, considere se ele também precisa de um handler dedicado em vez de cair no catch-all.

### 4.5 Segurança
- Estado: `SessionCreationPolicy.STATELESS`, JWT no header `Authorization: Bearer`.
- Autorização por rota grosseira em `SecurityConfig` (`authorizeHttpRequests`) **e** por método fino com `@PreAuthorize("hasRole('ADMIN')")` nos endpoints administrativos — as duas camadas convivem de propósito (defesa em profundidade).
- Quando a autorização depende de **dado**, não só de role (ex.: "só o dono da thread de chat ou um admin pode ler"), a checagem vive no `service`, lançando `ForbiddenException` — não dá para expressar isso só em `@PreAuthorize`.
- Requisição anônima em endpoint `ROLE_ADMIN` devolve **403, não 401** — comportamento padrão do Spring Security (`AnonymousAuthenticationToken` é tratado como "autenticado" para fins de `authenticated()`/`@PreAuthorize`). Não é bug; não "corrigir" para 401.
- Nunca commitar uma senha de admin em seed/migration. Promoção do primeiro admin é manual via SQL (`UPDATE users SET role='admin' WHERE email=...`, ver `backend/README.md`), depois logar de novo para receber um token com a role atualizada.

### 4.6 Hibernate: `saveAndFlush` quando a resposta lê um campo gerado
`@CreationTimestamp`/`@UpdateTimestamp` só populam o valor no **flush**, não no `save()`. Sempre que o método do `service` lê esse campo de volta na mesma transação para montar a resposta (`UserResponse.from(...)`, `MenuItemResponse.from(...)`, etc.), use `repository.saveAndFlush(...)` em vez de `save(...)` — senão o campo volta `null` (criação) ou desatualizado (edição) na resposta do próprio request que gerou o dado. Mesmo cuidado vale para qualquer FK not-null que aponte para uma entidade recém-criada: persista a entidade pai com `saveAndFlush` antes de construir a entidade filha que a referencia.

### 4.7 Migrations Flyway
- Nomenclatura `V{timestamp}__description.sql` (ex.: `V20260618120001__create_users_table.sql`).
- **Nunca editar uma migration já aplicada** em qualquer ambiente compartilhado — criar uma nova migration. (Durante o desenvolvimento inicial, sem dados reais, foi aceitável corrigir uma migration in-place e recriar o schema; isso não vale mais a partir do momento em que existirem dados reais.)
- Todas as tabelas deste backend vivem no schema dedicado `la_nona_api`, nunca em `public` — o Postgres de desenvolvimento é compartilhado com outros projetos.

### 4.8 Testes
- Testes unitários de regra de negócio pura: JUnit5 + Mockito (`@ExtendWith(MockitoExtension.class)`, `@Mock`/`@InjectMocks`), sem subir contexto Spring.
- Testes de integração: sempre contra um **Postgres real** via Testcontainers, nunca mockando o banco. Usar o padrão "singleton container" (campo `static`, iniciado uma vez em bloco `static { POSTGRES.start(); }`, com `@ServiceConnection` cuidando da configuração do datasource) — **não** usar `@Testcontainers`/`@Container` puro quando o container precisa ser compartilhado entre várias classes de teste, porque o JUnit para e reinicia o container (em outra porta) a cada classe, invalidando o `ApplicationContext` que o Spring já cacheou.
- Cada teste de integração roda dentro de uma transação revertida ao final (`@Transactional` na classe base) — não depender de dados fixos entre testes nem criar emails/IDs únicos manualmente para evitar colisão.

---

## 5. Convenções compartilhadas do monorepo

- **Idioma de mensagens visíveis ao usuário final**: português, em ambos os subprojetos (mensagens de erro do Flutter e do backend devem ter o mesmo tom).
- **`.gitignore`**: cada subprojeto tem o seu (`app/.gitignore`, `backend/.gitignore`) com os padrões específicos de Flutter/Maven; o `.gitignore` da raiz só tem regras genéricas (IDE, OS) que se aplicam a qualquer subprojeto.
- **Commits**: mensagens curtas no padrão `tipo(escopo): descrição` (`feat(backend): ...`, `fix: ...`, `chore(backend): ...`, `test(backend): ...`, `docs(backend): ...`), um commit por mudança logicamente coesa.

---

## 6. Como rodar tudo localmente

```bash
# Backend (Spring Boot) — ver backend/README.md para detalhes e variáveis de ambiente
cd backend
./mvnw spring-boot:run

# App Flutter — ver app/CLAUDE.md para detalhes
cd app
flutter pub get
flutter run
```

O app **ainda não está configurado para falar com o backend** — continua usando Firebase. Rodar os dois ao mesmo tempo hoje não os conecta entre si.

---

## 7. Próximos passos

1. **Integrar o app Flutter com a API nova**: trocar `auth_service.dart`, `user_profile_service.dart`, `menu_item_service.dart`, `cart_service.dart`, `favorites_service.dart`, `chat_service.dart` (hoje Firebase) para consumir os endpoints REST/WebSocket do backend. Ver `backend/SPRINGBOOT.md` seção 9 ("Fora de escopo") para o detalhamento desse próximo passo.
2. **Object storage para imagens**: migrar de base64-em-coluna para S3/MinIO quando o volume de dados justificar (decisão consciente de não fazer isso agora, ver `backend/SPRINGBOOT.md` seção 1, item 8).
3. **Conceito de Pedido/Checkout**: não existe ainda em nenhum dos dois subprojetos (o botão "Finalizar Pedido" no carrinho é só um placeholder) — vai exigir planejamento próprio quando for priorizado.
