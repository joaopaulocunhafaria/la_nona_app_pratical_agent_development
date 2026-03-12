# La Nona

Aplicativo Flutter com autenticação Firebase, login por Google, persistência de perfil no Firestore e onboarding de endereço com consulta de CEP via ViaCEP.

## Visão Geral

O app foi estruturado para separar autenticação, sessão e dados do usuário em serviços distintos, com estado compartilhado via Provider.

Principais objetivos:

- autenticação com email e senha
- login com Google Sign-In
- sincronização automática do usuário autenticado no Firestore
- onboarding obrigatório de endereço no primeiro acesso
- atualização de endereço com busca por CEP
- base multiplataforma Flutter

## Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Provider
- Google Sign-In
- ViaCEP

## Funcionalidades

### Autenticação

- cadastro com email e senha
- login com email e senha
- login com conta Google
- logout com confirmação
- tratamento de erros com mensagens amigáveis
- persistência de sessão entre execuções

### Perfil do usuário

- criação automática de documento em `users/{uid}` no primeiro login
- sincronização de nome, email e foto do provider
- escuta reativa do perfil com Firestore `snapshots()`
- armazenamento de endereço completo
- controle por `onboardingCompleted`

### Endereço e CEP

- modal de endereço no primeiro acesso
- validação de campos obrigatórios
- normalização e formatação de CEP
- busca automática de endereço via ViaCEP
- atualização posterior do endereço pelo usuário

## Estrutura Principal

```text
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   └── user_profile.dart
├── pages/
│   ├── auth_page.dart
│   ├── home_page.dart
│   └── welcome_page.dart
├── services/
│   ├── address_form_service.dart
│   ├── auth_service.dart
│   ├── session_service.dart
│   └── user_profile_service.dart
└── widgets/
	└── auth_check.dart
```

## Fluxo da Aplicação

```text
App inicia
-> Firebase é inicializado
-> AuthCheck verifica sessão
-> usuário não autenticado: WelcomePage
-> usuário autenticado: HomePage

No login:
-> AuthService observa authStateChanges
-> UserProfileService cria ou atualiza users/{uid}
-> HomePage consome profile em tempo real
-> se onboardingCompleted == false, abre modal de endereço
```

## Modelo de Dados

Coleção principal no Firestore:

```text
users/{uid}
```

Campos principais:

- `uid`
- `email`
- `name`
- `photoUrl`
- `provider`
- `address.cep`
- `address.rua`
- `address.bairro`
- `address.numero`
- `address.cidade`
- `address.estado`
- `address.complemento`
- `onboardingCompleted`
- `createdAt`
- `updatedAt`

## Pré-requisitos

- Flutter SDK compatível com o projeto
- Dart SDK `^3.11.1`
- conta e projeto no Firebase
- Android Studio, VS Code ou equivalente

## Configuração Firebase

### Android

1. Crie o projeto no Firebase.
2. Cadastre o app Android com o package name do projeto.
3. Coloque o arquivo `android/app/google-services.json` no projeto.
4. Ative no Firebase Authentication:
   - Email/Password
   - Google
5. Configure SHA-1 e SHA-256 no console do Firebase quando necessário.

### Firestore

Crie a coleção `users` e permita leitura e escrita de acordo com suas regras de segurança.

## Dependências Principais

```yaml
firebase_core: ^2.16.0
firebase_auth: ^4.10.1
cloud_firestore: ^4.13.1
provider: ^6.0.5
google_sign_in: ^6.1.5
http: ^1.2.2
flutter_svg: ^2.2.1
sign_in_button: ^3.2.0
```

## Como Executar

```bash
flutter clean
flutter pub get
flutter run
```

## Pontos de Arquitetura

- `AuthService`: autenticação e monitoramento de sessão
- `UserProfileService`: perfil no Firestore, CEP e endereço
- `AddressFormService`: fluxo e validação do modal de endereço
- `SessionService`: logout com confirmação
- `AuthCheck`: roteamento condicional entre áreas autenticada e pública

## Documentação Interna

- `IMPLEMENTATION.md`: visão detalhada da implementação da autenticação
- `LOGIN.md`: resumo do fluxo de login e configuração Android/Firebase
- `USERS_FIRESTORE.md`: gestão de usuários e persistência no Firestore
- `COLORS.md`: paleta visual definida para o app

## Observações

- o tema atual do app ainda pode ser refinado para alinhar totalmente com a paleta documentada em `COLORS.md`
- `firebase_options.dart` e `google-services.json` precisam refletir o projeto Firebase correto do ambiente
- o app já possui base para Android, iOS, Web, Linux, macOS e Windows
