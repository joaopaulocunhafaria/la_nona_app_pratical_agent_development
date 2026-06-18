# Gestão de Usuários com Firestore

Este documento descreve como o app gerencia usuários autenticados com Google/Firebase Auth e como mantém o perfil de cada usuário no Firestore.

## Objetivo da arquitetura

- Separar autenticação de gerenciamento de dados do usuário.
- Garantir que todo usuário autenticado tenha um documento em `users/{uid}`.
- Centralizar leitura/escrita de perfil em um serviço global.
- Controlar onboarding de endereço no primeiro acesso.

## Estrutura de dados

Collection: `users`

Documento: `users/{uid}`

Campos principais:
- `uid`: id do usuário no Firebase Auth
- `email`: email atual vindo do provider
- `name`: nome exibido do provider
- `photoUrl`: avatar do provider
- `provider`: provider de login (atualmente `google`)
- `address`: objeto com:
  - `cep`, `rua`, `bairro`, `numero`, `cidade`, `estado`, `complemento`
- `onboardingCompleted`: controla se o endereço inicial foi concluído
- `createdAt`, `updatedAt`: timestamps de criação/atualização

Modelos:
- `lib/models/user_profile.dart`
  - `UserProfile`: representa o documento de usuário
  - `UserAddress`: representa o bloco de endereço

## Serviços e responsabilidades

### 1) `AuthService`

Arquivo: `lib/services/auth_service.dart`

Responsável por:
- autenticar via Google/Firebase Auth
- observar mudanças de sessão (`authStateChanges`)
- acionar sincronização do perfil no Firestore
- limpar estado de sessão/perfil no logout

Comportamento:
- Usuário autenticou:
  - chama `UserProfileService.syncCurrentUser(user)`
- Usuário saiu:
  - chama `UserProfileService.clear()`

### 2) `UserProfileService` (serviço global de usuários)

Arquivo: `lib/services/user_profile_service.dart`

Responsável por:
- criar documento de usuário no primeiro login
- atualizar dados básicos em logins seguintes
- escutar perfil em tempo real com `snapshots()`
- salvar/atualizar endereço
- validar, normalizar e formatar CEP
- buscar endereço por CEP (ViaCEP)

Métodos principais:
- `syncCurrentUser(User user)`:
  - se não existe documento, cria com endereço vazio e `onboardingCompleted=false`
  - se já existe, atualiza nome/email/foto/provider
  - inicia listener com `watchCurrentUser(uid)`
- `watchCurrentUser(String uid)`:
  - mantém `profile` atualizado para toda a aplicação
- `saveAddress(...)`:
  - valida dados obrigatórios
  - normaliza `CEP` e `UF`
  - persiste endereço e marca `onboardingCompleted=true`
- `fetchAddressByCep(String cep)`:
  - consulta ViaCEP e preenche rua/bairro/cidade/UF
- `clear()`:
  - cancela listener e limpa estado local

### 3) `AddressFormService`

Arquivo: `lib/services/address_form_service.dart`

Responsável por:
- encapsular o modal/formulário de endereço
- aplicar validações de formulário
- executar busca de CEP
- chamar `UserProfileService.saveAddress` no submit

Isso remove regra de formulário da `HomePage` e mantém a tela mais focada em UI.

### 4) `SessionService`

Arquivo: `lib/services/session_service.dart`

Responsável por:
- encapsular fluxo de logout com confirmação
- chamar `AuthService.logout()`
- tratar feedback de erro para o usuário

## Fluxo de gerenciamento do usuário

1. Usuário faz login com Google.
2. `AuthService` recebe a sessão ativa.
3. `AuthService` chama `UserProfileService.syncCurrentUser(user)`.
4. O serviço cria/atualiza `users/{uid}` e inicia listener de perfil.
5. A UI consome `UserProfileService.profile` via Provider.
6. Se `onboardingCompleted == false`, abre modal de endereço.
7. Usuário salva endereço e o serviço persiste no Firestore.
8. `onboardingCompleted` vira `true` e a UI passa a mostrar o endereço salvo.

## Como a HomePage consome isso

Arquivo: `lib/pages/home_page.dart`

- Continua consumindo `AuthService` e `UserProfileService` para dados de exibição.
- Delega comportamento para serviços:
  - endereço: `AddressFormService`
  - sessão/logout: `SessionService`

Resultado:
- menor acoplamento da tela
- regras de negócio concentradas em serviços
- melhor manutenção e evolução futura

## Benefícios práticos

- Estado de usuário unificado e reativo (listener em tempo real).
- Persistência consistente entre sessões.
- Onboarding de endereço controlado por regra de negócio.
- Facilidade para adicionar novos campos de perfil no futuro.
- Código de tela mais limpo, com responsabilidades bem separadas.
