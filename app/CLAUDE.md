# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

La Nona is a Flutter restaurant-app client (cardápio/menu, cart, favorites, support chat, admin tools) backed entirely by Firebase (Auth, Firestore, Storage). There is no custom backend — all business logic lives in Dart services under `lib/services` and `lib/data/services` that talk directly to Firebase SDKs.

A detailed architecture/feature narrative is kept in `GEMINI.md` (treat it as the long-form equivalent of this file — read it for deep context on a feature before touching it). Firestore schema is documented in `MODELS.md`; the support chat system specifically in `CHAT.md`.

## Commands

```bash
flutter pub get          # install dependencies
flutter run               # run on a connected device/emulator
flutter analyze           # static analysis — run before considering work done
flutter test               # run tests (currently only test/widget_test.dart)
flutter test test/widget_test.dart   # run a single test file
```

There is no lint/format CI script beyond `flutter analyze` (rules come from `flutter_lints` via `analysis_options.yaml`, no custom rule overrides).

`test/widget_test.dart` is still the unmodified Flutter counter-app template (`pumpWidget(MyApp())` then looks for `find.text('0')`/`'1'`) — it does not match this app's actual UI (which boots into `AuthCheck` → `WelcomePage`/`HomePage`, no counter) and will fail if run. There is no other test coverage. Be aware of this when asked to "run the tests" or add new ones — don't assume the existing test is a meaningful baseline.

## Architecture

### Data flow
`main.dart` wires up a `MultiProvider` at the app root: `UserProfileService` → `AuthService` (via `ChangeNotifierProxyProvider`, since auth needs to sync into the user profile) → `UserProvider`, `CartService`, `FavoritesService`, `ChatService`. `AuthCheck` (`lib/widgets/auth_check.dart`) is the single routing decision point: it consumes `AuthService` and renders `WelcomePage` (unauthenticated), a loading spinner, or `HomePage` (authenticated) — there is no named-route navigator, screens push/pop via `Navigator` directly.

`AuthService._authCheck()` listens to `FirebaseAuth.authStateChanges()` for the life of the app and, on every change, calls `UserProfileService.syncCurrentUser()` (creates/updates `users/{uid}`) or `.clear()` on sign-out. Anything that needs the current user's Firestore profile should go through `UserProfileService`, not re-read Firebase Auth directly.

### Two service layers
- `lib/services/` — app-level/business services: `auth_service.dart`, `user_profile_service.dart`, `cart_service.dart`, `favorites_service.dart`, `chat_service.dart`, `session_service.dart`, `address_form_service.dart`.
- `lib/data/services/` — lower-level Firestore/Storage CRUD: `menu_item_service.dart` (menu catalog CRUD/filtering/search), `storage_service.dart` (image upload/download/delete with explicit timeouts: 60s upload, 30s download, 30s delete; singleton; logs with emoji CHECKPOINT markers, e.g. `🔵`/`🟢`/`🔴`/`🟡`).

When adding a new Firestore-backed feature, follow this split: keep raw Firestore/Storage calls in `data/services`, and put cross-cutting state/business rules that the UI consumes via Provider in `services/`.

### Firestore schema (see `MODELS.md` for full field tables)
- `users/{uid}` — profile, `isAdmin` flag (source of truth for RBAC in the UI), nested `address` map, `onboardingCompleted`.
  - `users/{uid}/cart/{itemId}` and `users/{uid}/favorites/{itemId}` subcollections.
- `menu_items/{itemId}` — catalog items with `imageUrls` (Storage download URLs, never raw image data) and `available`/`category` fields used for filtering.
- `chats/{userId}` + `chats/{userId}/messages/{messageId}` — support chat threads, doc ID is the client's `uid`. Regular users only ever see their own thread; admins (`isAdmin == true`) see all threads. `ChatService.sendMessage` uses a Firestore `WriteBatch` to append the message and update the parent thread's `lastMessage`/`updatedAt`/`unreadCount` atomically — replicate that pattern for any new chat-like write.

### Address/CEP onboarding
First login blocks navigation with a modal (driven by `address_form_service.dart`) until a Brazilian address is captured, looked up via the ViaCEP API (`https://viacep.com.br/ws/{cep}/json/`). `onboardingCompleted` on the user doc gates this.

### Conventions specific to this codebase
- All async Firebase calls should have explicit timeouts (mirror `storage_service.dart`'s pattern) and try/catch with user-facing error messages — there's no global error-translation layer.
- Auth/validation error messages are Portuguese-language and user-facing (see `AuthService._handleFirebaseAuthException`); match that tone/language for new user-visible strings in this part of the app.
- Images are compressed client-side (quality 80%) before upload; never upload uncompressed.
- `isAdmin` on `users/{uid}` is the only authorization signal in the UI — mirror it in Firestore/Storage security rules rather than inventing a new role field.

## Firebase configuration caveats

- `firebase.json` and `android/app/google-services.json` are gitignored (see the `firebase.json` removal commit in history) but currently exist locally and are required for the app to build/run — don't assume a fresh checkout has them, and never re-add them to git.
- `lib/firebase_options.dart` is the real, auto-generated (FlutterFire CLI) config and is also expected to exist locally only; `lib/firebase_options.dart.example` is the committed placeholder/template — keep both in sync structurally if you change platforms, but only edit the `.example` file in commits.
