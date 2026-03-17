# La Nona - Project Context & Memory

## 📱 Project Overview

**La Nona** is a comprehensive Flutter mobile application for restaurant management with a complete authentication system, user profiles, address management, and menu item catalog with image uploads.

- **Project Name:** La Nona
- **Type:** Flutter Mobile Application
- **Status:** Active Development
- **Supported Platforms:** iOS, Android, Web, macOS, Windows, Linux
- **Language:** Dart
- **Minimum Flutter SDK:** ^3.11.1

---

## 🔧 Core Stack & Framework

### Primary Technologies
- **Framework:** Flutter (declarative UI framework)
- **Language:** Dart (^3.11.1)
- **State Management:** Provider (^6.0.5) - Multi-provider architecture for shared state
- **Backend:** Firebase Suite (Authentication, Firestore, Storage)
- **UI Design System:** Material 3 Design

### Build System
- **Android:** Kotlin + Gradle KTS (Java 17 target)
- **iOS:** Swift
- **Web:** Dart (no platform-specific code)
- **Desktop (macOS/Windows/Linux):** Native integrations via Flutter

---

## 📦 Key Dependencies & Their Purposes

### Firebase Dependencies (Backend & Services)
| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^2.16.0 | Firebase initialization and configuration |
| `firebase_auth` | ^4.10.1 | User authentication (Email/Password, Google Sign-In) |
| `cloud_firestore` | ^4.13.1 | NoSQL database for user profiles, menu items, addresses |
| `firebase_storage` | ^11.1.0 | Image storage and media management |

### UI & Design
| Package | Version | Purpose |
|---------|---------|---------|
| `cupertino_icons` | ^1.0.8 | iOS-style icon library |
| `flutter_svg` | ^2.2.1 | SVG image rendering (logo assets) |
| `sign_in_button` | ^3.2.0 | Pre-styled Google Sign-In button UI |

### State Management & Services
| Package | Version | Purpose |
|---------|---------|---------|
| `provider` | ^6.0.5 | Reactive state management with ChangeNotifier pattern |
| `http` | ^1.2.2 | HTTP client for external APIs (ViaCEP address lookup) |

### Authentication Integration
| Package | Version | Purpose |
|---------|---------|---------|
| `google_sign_in` | ^6.1.5 | Google OAuth 2.0 authentication |

### Image Handling
| Package | Version | Purpose |
|---------|---------|---------|
| `image_picker` | ^1.0.0 | Gallery + camera image selection for menu item photos |

### Development Tools
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_lints` | ^6.0.0 | Linting rules enforcing Flutter best practices |
| `flutter_launcher_icons` | ^0.14.4 | App icon generation for all platforms |

---

## 🏗️ Project Architecture

### Core Architecture Pattern
- **Type:** Multi-provider reactive architecture
- **State Management:** Provider with ChangeNotifier pattern
- **Data Flow:** Services → Provider → UI Widgets
- **Database:** Firestore with real-time snapshots (StreamProvider pattern)

### Directory Structure
```
la_nona/
├── lib/
│   ├── main.dart                             # App entry point, Firebase init, Provider setup
│   ├── firebase_options.dart                 # Platform-specific Firebase configuration
│   ├── models/                               # User profile, menu item models
│   │   └── user_profile.dart
│   ├── pages/                                # Screen widgets (NavigatorStack)
│   │   ├── welcome_page.dart                 # Onboarding/auth selection screen
│   │   ├── auth_page.dart                    # Login/Signup form
│   │   ├── home_page.dart                    # Main app home with menu & profile tabs
│   │   ├── menu_page.dart                    # 2-column grid menu items
│   │   ├── menu_item_detail_page.dart        # Item details with image carousel
│   │   └── add_menu_item_page.dart           # Form to create/edit menu items
│   ├── services/                             # Business logic & Firebase operations
│   │   ├── auth_service.dart                 # Firebase Auth + session management
│   │   ├── session_service.dart              # Persistent session tracking
│   │   ├── user_profile_service.dart         # Firestore users/{uid} CRUD + streaming
│   │   └── address_form_service.dart         # Address validation & CEP lookup
│   ├── data/
│   │   ├── models/                           # Data models
│   │   │   └── menu_item.dart                # MenuItem model with copyWith()
│   │   └── services/                         # Low-level data operations
│   │       ├── storage_service.dart          # Firebase Storage image operations
│   │       └── menu_item_service.dart        # Firestore menu items CRUD + filtering
│   ├── widgets/                              # Reusable components
│   │   └── auth_check.dart                   # Conditional routing based on auth state
│   ├── theme/                                # UI styling
│   │   └── app_theme.dart                    # Material 3 theme definitions
│   └── firebase_options.dart                 # Auto-generated platform configs
├── android/                                  # Android native code (Kotlin)
├── ios/                                      # iOS native code (Swift)
├── web/                                      # Web deployment files
├── windows/                                  # Windows desktop app
├── macos/                                    # macOS desktop app
├── linux/                                    # Linux desktop app
├── assets/                                   # Images, fonts, SVG files
│   ├── la-nona-logo.svg
│   ├── la-nona-logo-splash.svg
│   └── fonts/SignaturaMonoline.ttf
├── pubspec.yaml                              # Dependency declarations & assets
├── analysis_options.yaml                     # Linting configuration
└── GEMINI.md                                 # This file - Project context
```

---

## 🔐 Firebase Configuration

Detailed information about the data modeling and Firestore structure can be found in the [MODELS.md](./MODELS.md) file.

### Firebase Storage Structure
```
menu_items/{itemId}/{timestamp}.jpg
```

---

## 🎯 Core Features & Services

### 1. Authentication Service (`auth_service.dart`)
- Email/Password sign-up and login
- Google OAuth 2.0 integration via `google_sign_in`
- Firebase Auth state changes monitoring
- Auto-user creation in Firestore on first login
- Logout with confirmation
- Session persistence between app launches
- Error handling with user-friendly messages

### 2. User Profile Service (`user_profile_service.dart`)
- Real-time Firestore snapshot streaming
- Profile data synchronization from AuthService
- ChangeNotifier pattern for reactive updates
- Firestore listeners cleanup

### 3. Address & CEP Lookup (`address_form_service.dart`)
- ViaCEP API integration for postal code lookup
- Address field validation (required fields: street, number, neighborhood, city, state, ZIP)
- Address normalization and formatting
- CEP format validation (8 digits with optional hyphen)
- Modal dialog for address onboarding on first login

### 4. Menu Item Management (`menu_item_service.dart`)
- **Create:** Add new menu items with images
- **Read:** Fetch single items or all items via Firestore streams
- **Update:** Edit menu item details and images
- **Delete:** Remove items and associated images from Storage
- **Filter:** Get items by category or availability status
- **Search:** Find items by name
- Real-time updates via StreamProvider

### 5. Storage Service (`storage_service.dart`)
- Image upload with timeout (60s)
- Multiple image uploads with error handling
- Image deletion with timeout (30s)
- Download URL retrieval with timeout (30s)
- Firebase Storage connectivity test
- File size validation (empty file detection)
- Singleton pattern for performance
- Comprehensive logging with CHECKPOINT system
- Stack trace error reporting

### 6. Image Picker Integration
- Gallery selection
- Camera capture
- Multiple image selection for menu items
- Image compression (quality 80%)
- Preview before upload
- Remove images before save (edit mode support)

---

## 🎨 UI/UX Patterns

### Navigation Architecture
- **Auth Check Widget:** Conditional routing (authenticated → HomePage, unauthenticated → WelcomePage)
- **Bottom Navigation:** Home, Profile, Settings tabs on HomePage
- **Modal Dialogs:** Address onboarding on first login
- **Page Transitions:** Material transitions between screens

### Widget Hierarchy
- **Home Page:** Multi-tab layout (Cardápio/Menu tab, Profile tab, Settings tab)
- **Menu Page:** 2-column responsive grid with card items
- **Menu Item Detail:** PageView carousel for images, ArrowBack navigation
- **Add Menu Item:** Form validation with loading indicators
- **Auth Pages:** Welcome page routing, Login form, Signup form

### Key UI Components
- **Image Carousel:** Horizontal swipe with page indicators
- **Grid Layout:** Responsive 2-column menu grid
- **Status Badges:** Visual indicators for available/unavailable items
- **Form Validation:** Real-time feedback on required fields
- **Loading States:** Spinners during image uploads and data fetching
- **Error Messages:** User-friendly error dialogs and snackbars

---

## ⚙️ Development Standards

### Code Organization
- **Services:** Encapsulate business logic, Firebase operations, external API calls
- **Models:** Data structures with `toMap()`, `fromMap()`, `copyWith()` methods
- **Pages:** Screen-level widgets (full-screen layouts)
- **Widgets:** Reusable UI components, stateless when possible
- **Theme:** Centralized color, typography, and styling definitions

### Naming Conventions
- **Classes:** PascalCase (e.g., `MenuItemService`, `UserProfile`)
- **Functions/Methods:** camelCase (e.g., `uploadMenuItemImage()`)
- **Constants:** camelCase with leading underscore for private (e.g., `_defaultTimeout`)
- **Files:** snake_case (e.g., `menu_item_service.dart`)
- **Prefixes:** Use `_` for private class members

### Dart/Flutter Best Practices
- **Type Safety:** Always use explicit types, avoid `dynamic`
- **Null Safety:** Use `?` and `!` operators appropriately, nullable types
- **Async/Await:** Prefer async/await over `.then()` chains
- **Streaming:** Use `StreamProvider` for real-time updates from Firestore
- **Error Handling:** Always wrap Firebase operations in try-catch
- **Documentation:** JSDoc comments on public methods and classes
- **Linting:** Follow `flutter_lints` rules (enabled in analysis_options.yaml)

### Provider Pattern Rules
- **ChangeNotifier:** For single-notifier state (avoid excessive rebuilds with set/get)
- **MultiProvider:** Compose multiple providers at app root
- **ChangeNotifierProxyProvider:** When one provider depends on another
- **Consumer:** Use in UI to listen to provider changes
- **watch() vs read():** Use `watch()` for reactive updates, `read()` for one-time access

### Async Operations
- **Timeouts:** Apply timeouts to Firebase operations to prevent indefinite hangs
  - Upload: 60s
  - Download: 30s
  - Delete: 30s
- **Error Recovery:** Always provide fallback UI or retry mechanisms
- **Logging:** Use `debugPrint()` for development logging with CHECKPOINT markers

### Image Handling Standards
- **Compression:** Compress images to quality 80% before upload (reduce storage/transfer)
- **Multiple Uploads:** Handle partial failures gracefully in batch operations
- **Storage Cleanup:** Delete orphaned images when menu items are removed
- **Preview:** Show image preview before confirming uploads

---

## 🚀 Build & Deployment Configurations

### Android Configuration
- **Min SDK:** Determined by Flutter dependencies (typically API 21+)
- **Target SDK:** Latest stable (set in gradle)
- **Java Version:** 17 (Kotlin target compatibility)
- **Namespace:** `com.example.la_nona`
- **Google Services:** Added via `build.gradle.kts` with `com.google.gms.google-services` plugin
- **Version:** 1.0.0 (build +1)

### iOS Configuration
- **Minimum Deployment Target:** Determined by Flutter (typically 11.0+)
- **Build Language:** Swift
- **CocoaPods Integration:** All Flutter plugins via CocoaPods
- **Google Services:** Configured via GoogleService-Info.plist

### Platform-Specific Firebase Init
- Handled by `firebase_options.dart` (auto-generated by FlutterFire CLI)
- Platform detection via `DefaultFirebaseOptions.currentPlatform`
- Supports: Android, iOS, Web, macOS, Windows, Linux

### App Icons & Splash
- **Icon Source:** `assets/logo1.png`
- **Tool:** `flutter_launcher_icons` package
- **Platforms:** Auto-generate for iOS and Android
- **iOS:** Alpha channel removed for iOS compatibility

---

## 📚 Assets & Resources

### Image Assets
- **SVG Logos:** `assets/la-nona-logo.svg`, `assets/la-nona-logo-splash.svg`
- **App Icon:** `assets/logo1.png` (launcher icon source)

### Fonts
- **Custom Font:** SignaturaMonoline (family: `SignaturaMonoline`)
- **Path:** `assets/fonts/SignaturaMonoline.ttf`
- **Usage:** For branding/headers in UI

### Material Design
- **Icons:** Flutter's Material Icons (included via Material Design)
- **Cupertino Icons:** iOS-style icons (via `cupertino_icons`)

---

## 🔌 External APIs & Integrations

### ViaCEP API
- **Purpose:** Brazilian postal code (CEP) lookup for address autocomplete
- **Endpoint:** `https://viacep.com.br/ws/{cep}/json/`
- **Used In:** Address form service during address onboarding
- **Response:** Street, neighborhood, city, state population from CEP

### Google OAuth 2.0
- **Provider:** Google Sign-In (via `google_sign_in` package)
- **Scope:** Basic profile (email, name, profile picture)
- **Integration:** FirebaseAuth integration for seamless login

### Firebase Services
- **Authentication:** Email/Password, Google OAuth, session management
- **Database:** Firestore for user profiles and menu data
- **Storage:** Firebase Storage for image uploads/downloads
- **Realtime Updates:** Firestore snapshots for reactive data binding

---

## 🧪 Testing & Debugging

### Logging Strategy
- **CHECKPOINT System:** Use `print('🔵 [COMPONENT] Message')` with emoji prefixes
  - 🔵 Blue: INFO/initialization
  - 🟢 Green: SUCCESS
  - 🔴 Red: ERROR
  - 🟡 Yellow: WARNING
- **Debug Mode:** Flutter verbose logging with `-v` flag

### Firebase Storage Testing
- Verify connectivity at app startup (done in `main.dart`)
- Monitor upload/download timeouts in logs
- Test error scenarios: network timeout, invalid files, permissions

### Address Lookup Testing
- Verify ViaCEP API responses with various CEP formats
- Test invalid/non-existent CEP codes
- Test network timeout scenarios

---

## 📋 Development Workflow

### Before Starting Work
1. Read this GEMINI.md for architecture understanding
2. Review relevant service files for feature context
3. Check existing implementation patterns in similar features
4. Run `flutter analyze` to check code quality

### During Development
1. Follow naming conventions and code organization rules
2. Apply timeouts to all async Firebase operations
3. Add CHECKPOINT logging at critical points
4. Use StreamProvider for real-time Firestore data
5. Implement proper error handling with user-friendly messages
6. Test on multiple platforms (Android, iOS, Web)

### Before Submitting
1. Run `flutter analyze` - no warnings
2. Run `flutter test` if applicable
3. Test on Android, iOS, and Web emulators/devices
4. Verify images compress and upload correctly
5. Check Firestore rules allow operations

---

## ❌ Things NOT To Do

- **Do NOT** use class components in Flutter (use functional/stateless widgets)
- **Do NOT** write custom CSS or styling—use Material 3 theme definitions
- **Do NOT** use `dynamic` types—always specify explicit types
- **Do NOT** make Firebase async operations without timeouts
- **Do NOT** create global Provider instances outside Providers—use ChangeNotifier
- **Do NOT** skip error handling on database operations
- **Do NOT** upload uncompressed images
- **Do NOT** expose Firebase configuration keys in code (use firebase_options.dart)
- **Do NOT** use nested navigation without proper state management
- **Do NOT** ignore Firestore query limits and pagination

---

## 💾 Key Files to Know

| File | Purpose |
|------|---------|
| `main.dart` | App entry point, Firebase init Firebase Storage test, Provider setup |
| `firebase_options.dart` | Platform-specific Firebase configuration (auto-generated) |
| `MODELS.md` | Detailed documentation of Firestore data modeling |
| `auth_service.dart` | Authentication logic, session management |
| `user_profile_service.dart` | Firestore user profile streaming and updates |
| `menu_item_service.dart` | Menu CRUD operations, Firestore queries, filtering |
| `storage_service.dart` | Image uploads, downloads, deletions with timeouts |
| `menu_page.dart` | 2-column menu grid layout |
| `menu_item_detail_page.dart` | Item details with image carousel |
| `add_menu_item_page.dart` | Form to create/edit menu items with image picker |
| `app_theme.dart` | Material 3 theme configuration |

---

## 📝 Important Notes

### Firestore Security
- Rules configured for development (permissive)
- Must be updated for production security
- See `FIREBASE_STORAGE_RULES.md` for rule examples

### Image Upload Performance
- All uploads include 60-second timeout
- Failure recovery logic is implemented
- Monitor `storage_service.dart` logs for issues

### Address Onboarding
- Mandatory on first login (blocked until completed)
- Modal dialog prevents page navigation until address provided
- Can be updated later from profile page

### Multi-Platform Support
- App targets iOS, Android, Web, macOS, Windows, Linux
- Firebase configuration auto-detects platform
- Test on actual devices, not just emulators

---

**Last Updated:** 2026-03-16  
**Project Version:** 1.0.0
