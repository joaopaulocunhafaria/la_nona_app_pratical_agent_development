# Support Chat System - Technical Documentation

This document describes the architecture, data modeling, and security logic for the Admin-to-User support chat system.

## 🌎 Feature Definition
**Admin-to-User Support Chat**
> "A real-time messaging system where standard users can communicate exclusively with the restaurant administration. Regular users have access only to their private support channel, while administrators have a centralized dashboard to view and respond to all active customer inquiries."

---

## 🗄️ Data Modeling (Firestore)

The chat system uses a root collection for "Threads" and a nested subcollection for individual "Messages".

### 1. Root Collection: `chats`
Each document in this collection represents a unique conversation between a Client and the Support Team.

**Document ID**: The `uid` of the regular user (Client).

| Field | Type | Description |
|-------|------|-------------|
| `userId` | String | The client's unique identifier. |
| `userName` | String | Client's name (denormalized for the admin inbox list). |
| `lastMessage` | String | Preview of the last message sent in the thread. |
| `updatedAt` | Timestamp | Used for sorting the admin's inbox (most recent first). |
| `unreadCount` | Integer | Number of messages sent by the user that the admin hasn't seen yet. |

### 2. Subcollection: `chats/{userId}/messages`
Contains the actual message history for a specific thread.

| Field | Type | Description |
|-------|------|-------------|
| `senderId` | String | UID of the person who sent the message. |
| `text` | String | The message content. |
| `isAdmin` | Boolean | Flag to distinguish between support responses and user messages (used for UI styling). |
| `sentAt` | Timestamp | When the message was sent (server-side timestamp). |

---

## 🔐 Access Logic & RBAC

The system enforces strict Role-Based Access Control (RBAC) to ensure privacy and security.

### Client View
- **Constraint**: Standard users are "locked" to their own document.
- **Path**: `chats/{myUid}` and `chats/{myUid}/messages/*`.
- **Permission**: Can only read/write messages in their own thread.

### Admin View
- **Constraint**: Global visibility.
- **Path**: `chats/*` and `chats/*/messages/*`.
- **Permission**: Can see the list of all active chat documents and participate in any thread to provide support.

---

## 🛡️ Security Rules Logic

```javascript
service firebase.storage {
  match /b/{bucket}/o {
    match /chats/{userId} {
      // Allow user to see their own chat OR admin to see all
      allow read, write: if request.auth.uid == userId || get(/databases/(default)/documents/users/$(request.auth.uid)).data.isAdmin == true;
      
      match /messages/{messageId} {
        allow read, write: if request.auth.uid == userId || get(/databases/(default)/documents/users/$(request.auth.uid)).data.isAdmin == true;
      }
    }
  }
}
```

---

## 🚀 Technical Implementation

### ChatService Logic
- **`sendMessage`**: Uses a Firestore `WriteBatch` to atomically:
    1. Add the new message to `chats/{userId}/messages`.
    2. Update the parent `chats/{userId}` document with `lastMessage`, `updatedAt`, and increment `unreadCount` (if sent by user).
- **`markAsRead`**: Called by admins when opening a thread to reset the `unreadCount` to zero.

### UI Components
- **`SupportChatPage`**: A bidirectional chat screen. It uses `reverse: true` in the `ListView` for a standard messaging feel. It automatically detects the sender's role based on the `isAdminView` flag.
- **`AdminChatListPage`**: A dashboard for administrators that streams all active threads, showing a red badge for conversations with unread messages.

### Navigation
- Users access their chat via the "Suporte ao Cliente" card on the Home Page.
- Admins see an "Inbox de Suporte (Admin)" card instead, which leads to the thread list.
