# La Nona - Firestore Data Models

This document describes the data structure and modeling used in the Firebase Firestore database for the La Nona application.

## 🗄️ Collections Overview

The database is structured into two main root collections:
1. `users`: Stores user profile information, including roles and addresses.
2. `menu_items`: Stores the restaurant's catalog items.

---

## 👤 Users Collection (`users`)

Each document is identified by the Firebase Authentication UID (`uid`).

### Document Structure: `users/{uid}`

| Field | Type | Description |
|-------|------|-------------|
| `uid` | String | Unique identifier from Firebase Auth |
| `email` | String | User's email address |
| `name` | String | User's full display name |
| `photoUrl` | String | URL to the user's profile picture |
| `provider` | String | Auth provider (e.g., 'google', 'password') |
| `isAdmin` | Boolean | Whether the user has administrative privileges |
| `onboardingCompleted` | Boolean | Whether the user has finished the initial setup (e.g., address) |
| `address` | Map | Nested object containing address details |
| `createdAt` | Timestamp | When the profile was first created |
| `updatedAt` | Timestamp | When the profile was last updated |

### Address Map (`address`)

| Field | Type | Description |
|-------|------|-------------|
| `cep` | String | Brazilian ZIP code (format: 00000-000) |
| `rua` | String | Street name |
| `bairro` | String | Neighborhood |
| `numero` | String | Building/House number |
| `cidade` | String | City |
| `estado` | String | State (UF - 2 characters) |
| `complemento` | String | Additional address info (optional) |

---

## 🛒 Cart Subcollection (`users/{uid}/cart`)

Stores the items the user has added to their shopping cart.

### Document Structure: `users/{uid}/cart/{itemId}`

| Field | Type | Description |
|-------|------|-------------|
| `menuItem` | Map | Snapshot of the MenuItem data |
| `quantity` | Number (Integer) | Number of units of this item |
| `addedAt` | Timestamp | When the item was added to the cart |

---

## ❤️ Favorites Subcollection (`users/{uid}/favorites`)

Stores the user's favorite menu items.

### Document Structure: `users/{uid}/favorites/{itemId}`

The document fields are a mirror of the `menu_items` structure to allow quick display without extra fetches.

---

## 🍴 Menu Items Collection (`menu_items`)

Stores the catalog of available food and drinks.

### Document Structure: `menu_items/{itemId}`

| Field | Type | Description |
|-------|------|-------------|
| `name` | String | Name of the item |
| `description` | String | Detailed description of the item |
| `category` | String | Predefined category (Hamburguer, Pizza, Salada, Bebida, Sobremesa, Acompanhamento, Outro) |
| `price` | Number (Double) | Price of the item in R$ |
| `available` | Boolean | Whether the item is currently available for order |
| `imageUrls` | List<String> | List of Firebase Storage URLs for the item's images |
| `createdAt` | Timestamp | When the item was added |
| `updatedAt` | Timestamp | When the item was last modified |

---

## 📐 Modeling Principles

### 1. Denormalization vs. Normalization
- We use **Nested Objects** for addresses within the user profile to reduce the number of reads needed to display a complete user profile.
- Menu items are kept in a separate collection to allow for efficient streaming of the entire catalog.

### 2. Timestamps
- Every document includes `createdAt` and `updatedAt` for auditing and sorting purposes.
- We use `FieldValue.serverTimestamp()` during writes to ensure consistency across different clients.

### 3. Image Handling
- Images are **not stored in Firestore**. Instead, Firestore stores the **Download URLs** provided by Firebase Storage.
- This keeps document sizes small and improves performance.

### 4. Role-Based Access Control (RBAC)
- The `isAdmin` flag in the user document is the primary source of truth for administrative permissions in the UI.
- Security rules should mirror this logic to protect the data at the database level.
