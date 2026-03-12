# Implementação de Autenticação Firebase com Google Sign-In

## Visão Geral

Implementação de autenticação com Firebase e Google Sign-In em Flutter no Android. A solução inclui registro por email/senha, login com Google, persistência de sessão e gerenciamento de estado com Provider.

---

## Dependências

```yaml
firebase_core: ^2.16.0
firebase_auth: ^4.10.1
provider: ^6.0.5
sign_in_button: ^3.2.0
google_sign_in: ^6.1.5
```

---

## Configuração Android

### android/build.gradle
Na seção buildscript dependencies, adicione:
```
classpath 'com.google.gms:google-services:4.3.14'
```

### android/app/build.gradle
Na seção plugins, adicione:
```
id "com.google.gms.google-services"
```

### android/app/src/main/AndroidManifest.xml
Adicione permissões obrigatórias:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Arquivo google-services.json
Coloque em: android/app/google-services.json

---

## Arquitetura da Solução

### 1. AuthService (lib/services/auth_service.dart)

Classe ChangeNotifier que gerencia autenticação com Firebase. Responsabilidades:
- Registrar usuários com email/senha
- Login com email/senha
- Login com Google Sign-In
- Logout
- Monitorar mudanças de autenticação automaticamente

Métodos principais:
- registrar(email, senha): Cria nova conta
- login(email, senha): Autentica usuário existente
- loginComGoogle(): Google Sign-In via Firebase
- logout(): Desconecta e limpa estado
- _authCheck(): Monitora authStateChanges do Firebase

### 2. UserProvider (lib/services/auth_service.dart)

ChangeNotifier que armazena dados do usuário autenticado:
- user: User? (objeto do Firebase)
- userEmail, userName, userPhotoUrl, userId: Getters convenientes

### 3. AuthException (lib/services/auth_service.dart)

Exceção personalizada para erros de autenticação com tratamento de erros Firebase traduzidos para português.

### 4. AuthCheck (lib/widgets/auth_check.dart)

Widget de roteamento condicional que:
- Durante carregamento: exibe CircularProgressIndicator
- Usuário não autenticado: redireciona para WelcomePage
- Usuário autenticado: redireciona para HomePage

### 5. Páginas de Autenticação

WelcomePage: Tela inicial com botões para login por email e Google
AuthPage: Formulário de login/registro com validação
HomePage: Dashboard principal com informações do usuário

### 6. Inicialização (lib/main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

MultiProvider com AuthService e UserProvider envolve a aplicação.
AuthCheck é home do MaterialApp.

### 7. Firebase Options (lib/firebase_options.dart)

Arquivo gerado com credenciais do projeto Firebase:
- apiKey
- appId
- messagingSenderId
- projectId
- storageBucket

---

## Fluxo de Autenticação

```
App inicia
├─ Firebase inicializa
├─ AuthCheck verifica estado
│
├─ Não autenticado
│  ├─ WelcomePage
│  ├─ Clica "Email" → AuthPage
│  │  ├─ Login → AuthService.login()
│  │  └─ Registro → AuthService.registrar()
│  └─ Clica "Google" → AuthService.loginComGoogle()
│
└─ Autenticado
   └─ HomePage com dados do usuário
```

---

## Configuração Firebase Console

1. Criar projeto Firebase
2. Adicionar app Android com package name: com.example.la_nona
3. Baixar google-services.json
4. Ativar Authentication: Email/Password e Google
5. Adicionar SHA-1: ./gradlew signingReport
6. Adicionar SHA-1 em Firebase Console em Certificate Fingerprints

---

## Execução

```
flutter clean
flutter pub get
flutter run
```

---

## Testes Essenciais

1. Registro por email: Cadastra usuário com email/senha
2. Login por email: Autentica usuário existente
3. Login com Google: Autentica via conta Google
4. Persistência: App mantém autenticação após reinício

---

## Estrutura de Arquivos

```
lib/
├── main.dart
├── firebase_options.dart
├── services/
│   └── auth_service.dart
├── widgets/
│   └── auth_check.dart
└── pages/
    ├── welcome_page.dart
    ├── auth_page.dart
    └── home_page.dart
```
