# LockIn — Architecture

## 1. Overview

LockIn is designed as a **local-first, offline-capable focus application** with optional cloud functionality.

The core philosophy is:

> **LockIn should be completely useful without an account. Cloud features should enhance the experience, not gate it.**

A user should be able to install LockIn and immediately:

- Start focus sessions
- Use Lock-In Mode
- Set daily goals
- Maintain streaks
- View session history
- View statistics
- Configure preferences

All of these features should work **without an internet connection and without creating an account**.

Users who want social and cross-device functionality can optionally create an account. Once authenticated, their locally stored data can be synchronized with the cloud and additional features become available.

---

## 2. Core Architectural Principles

### 2.1 Local First

Local storage is the primary source of truth for the basic LockIn experience.

The application should not require a network request to:

- Start a focus session
- Complete a focus session
- View history
- Calculate daily progress
- Maintain streaks
- Read settings

The user should be able to use LockIn with:

```text
No account
No internet
No backend
```

---

### 2.2 Cloud Is Optional

Cloud functionality exists primarily for features that inherently require multiple devices or multiple users.

Examples:

- User accounts
- Friend relationships
- Focus Battles
- Cloud history
- Cross-device synchronization
- Leaderboards
- Social statistics

The absence of an account should **never make the core timer experience feel incomplete**.

---

### 2.3 Offline Capability

The application should remain functional when the device is offline.

If a user completes a session while offline:

```text
Complete Session
       ↓
Save Locally
       ↓
Session becomes part of local history
       ↓
Internet becomes available
       ↓
Sync with Cloud (if authenticated)
```

The user should not have to manually retry or recreate the session.

---

### 2.4 Progressive Enhancement

Authentication should be introduced as an **upgrade**, rather than a requirement.

Example:

```text
Install LockIn
      ↓
Use anonymously
      ↓
Build history and streak
      ↓
Discover Focus Battles
      ↓
"Create an account to compete with friends"
      ↓
Create account
      ↓
Existing local data is preserved
      ↓
Local data is synchronized with cloud
```

---

### 2.5 Separation of Concerns

The UI should never directly interact with storage implementations.

Bad:

```text
Screen
  ↓
SharedPreferences
```

Preferred:

```text
Screen
  ↓
Provider
  ↓
Repository
  ↓
Local / Remote Data Source
```

This allows the storage implementation to evolve without requiring large changes to the UI.

---

## 3. High-Level Architecture

The long-term architecture is:

```text
┌──────────────────────────────────────────────────────┐
│                    Flutter UI                        │
│                                                      │
│ Home │ Focus │ History │ Battles │ Profile │ Result  │
└─────────────────────────┬────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────┐
│                  Application State                   │
│                                                      │
│ TimerProvider │ HistoryProvider │ BattleProvider     │
└─────────────────────────┬────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────┐
│                    Repositories                      │
│                                                      │
│ SessionRepository                                    │
│ UserRepository                                       │
│ BattleRepository                                     │
│ SettingsRepository                                   │
└───────────────┬──────────────────────────┬───────────┘
                │                          │
                ▼                          ▼
┌──────────────────────────┐    ┌──────────────────────┐
│     Local Data Layer     │    │    Remote Data Layer │
│                          │    │                      │
│ Local Database           │    │ REST / WebSocket API │
│ SharedPreferences        │    │ Authentication       │
│ Local Sync Queue         │    │ Cloud Database       │
└──────────────────────────┘    └──────────────────────┘
```

The local layer is always available.

The remote layer is optional and only becomes active when the user has an authenticated account.

---

## 4. Current Architecture

The current LockIn implementation uses:

- **Framework**: Flutter (Dart 3+)
- **State Management**: Provider
- **Persistence**: `shared_preferences` (offline-first key-value storage)
- **Background & Notifications**: `flutter_local_notifications` with Java 8+ Core Library Desugaring
- **Design & Animation**: `flutter_animate`, `percent_indicator`, `flutter_svg`, Google Fonts

Current project structure:

```text
lib/
├── models/
│   ├── FocusSession
│   └── BattleModel
│
├── providers/
│   ├── TimerProvider
│   └── lifecycle-related state
│
├── screens/
│   ├── Home
│   ├── Focus
│   ├── Battles
│   ├── History
│   ├── Profile
│   └── Result
│
├── services/
│   ├── persistent storage (StorageService)
│   └── notification handlers (NotificationService)
│
├── utils/
│   ├── AppTheme
│   ├── typography
│   └── constants
│
└── widgets/
    └── reusable UI components & hand-drawn doodle decorations
```

This architecture is intentionally lightweight during the initial development phase.

---

## 5. Local Persistence

### 5.1 SharedPreferences

`shared_preferences` is currently used for lightweight persistent data.

It is appropriate for things such as:

```text
dailyGoal
themePreference
soundEnabled
hapticsEnabled
onboardingCompleted
userPreferences
```

It can also temporarily support serialized session history during the early development stage.

However, `SharedPreferences` should **not become the long-term database for LockIn's entire history system**.

---

### 5.2 Local Database

As session history becomes more sophisticated, LockIn should migrate structured data to a local database such as:

- SQLite / Drift / Floor
- another suitable embedded database

Potential entities:

```text
FocusSession
DailyStats
Battle
UserProfile
SyncOperation
```

Example Schema:

```text
FocusSession
────────────────────────
id: String (UUID)
startedAt: DateTime
completedAt: DateTime
duration: Int
targetDuration: Int
status: Enum (completed, forfeited)
isLocked: Boolean
forfeitReason: String?
battleId: String?
createdAt: DateTime
updatedAt: DateTime
syncStatus: Enum (synced, pending, failed)
```

This makes queries such as:

```text
- Get today's focus sessions
- Get this week's focus time
- Get completed sessions
- Get forfeited sessions
- Calculate longest streak
- Get sessions for a specific date range
```

much easier and more efficient.

---

## 6. Repository Pattern

Repositories provide the boundary between application logic and data storage.

For example:

```text
TimerProvider
      ↓
SessionRepository
      ↓
┌──────────────────────┐
│ LocalSessionDataSource│
└──────────────────────┘
```

When cloud functionality is enabled:

```text
                    SessionRepository
                           │
              ┌────────────┴────────────┐
              ↓                         ↓
    LocalSessionDataSource     RemoteSessionDataSource
              │                         │
        Local Database              Backend API
```

The application does not need to know which storage mechanism is being used.

---

## 7. Anonymous User Architecture

Every LockIn installation initially operates as an **anonymous local user**.

An anonymous user can:

- Start sessions
- Complete sessions
- Forfeit sessions
- Maintain streaks
- View history
- Set goals
- Use Lock-In Mode
- Use the application offline

No authentication is required.

Conceptually:

```text
                    LockIn
                      │
                Anonymous User
                      │
              ┌───────┴────────┐
              ↓                ↓
        Local Settings    Local History
```

No cloud account is necessary.

---

## 8. Authenticated User Architecture

When the user creates an account:

```text
Anonymous Local User
        ↓
   Create Account
        ↓
Authenticated User
        ↓
Cloud synchronization enabled
```

The local data remains intact. The user's account becomes associated with the existing local data.

---

## 9. Anonymous → Authenticated Migration

This is a critical part of the architecture.

A user may use LockIn for weeks or months before creating an account.

For example:

```text
Local Device State:
- 87 sessions
- 42 hours focused
- 14-day longest streak
- 23 completed days
```

The user then creates an account:

```text
Local Data
    ↓
Create Account
    ↓
Associate local identity with account
    ↓
Upload local history
    ↓
Resolve synchronization conflicts
    ↓
Mark local records as synchronized
```

The user's existing history must **not disappear**.

### Migration Principle

> Creating an account should feel like unlocking additional functionality, not starting the application over.

---

## 10. Cloud Synchronization

Cloud synchronization should be **asynchronous**.

The user should not have to wait for a server response before their local session appears in history.

Preferred flow:

```text
User completes session
        ↓
Save locally
        ↓
Update UI immediately
        ↓
Add synchronization operation to Sync Queue
        ↓
Attempt cloud synchronization
        ↓
Success → Mark synchronized
        │
        └── Failure → Retry later (exponential backoff)
```

This keeps the application responsive and offline-friendly.

---

## 11. Sync Queue

Authenticated users should have a local queue of operations that still need to be synchronized.

Example Operations:

```text
Sync Queue
──────────────────────────
CREATE_SESSION
UPDATE_SESSION
CREATE_BATTLE_RESULT
UPDATE_PROFILE
UPDATE_GOALS
```

Example Flow:

```text
Complete Session
      ↓
Local Database
      ↓
Sync Queue
      ↓
Internet available?
   ├── Yes → Sync to Cloud → Dequeue
   └── No  → Keep queued → Retry when online
```

This prevents network failures from affecting the user's local experience.

---

## 12. Source of Truth

For the core application:

> **Local state is the immediate source of truth.**

Cloud state is used for:

- Backup
- Synchronization
- Social features
- Cross-device access

This means:

```text
Local Store
  ↓
Immediate UI State
  ↓
Cloud Synchronization (Background)
```

rather than:

```text
Cloud Request
  ↓
Wait for Response
  ↓
Update UI
```

---

## 13. Focus Session Lifecycle

A focus session follows a predictable lifecycle:

```text
                    ┌──────────────┐
                    │    Created   │
                    └──────┬───────┘
                           ↓
                    ┌──────────────┐
                    │    Active    │
                    └──────┬───────┘
                           │
             ┌─────────────┴─────────────┐
             ↓                           ↓
       Timer finishes               User exits
             ↓                           ↓
       ┌───────────┐              ┌───────────┐
       │ Completed │              │  Forfeit  │
       └─────┬─────┘              └─────┬─────┘
             │                          │
             └────────────┬─────────────┘
                          ↓
                    Save Locally
                          ↓
                    Update History
                          ↓
                 Sync if authenticated
```

A session should be persisted as soon as its important state changes. This is especially important for Lock-In Mode.

---

## 14. Lock-In Mode

Lock-In Mode introduces lifecycle and system-level considerations.

The timer cannot depend solely on an in-memory Dart variable.

For example, this is fragile:

```dart
int remainingSeconds = 2700;
```

If the application is backgrounded or terminated, this state may no longer represent reality.

Instead, the application persists timestamp boundaries:

```text
startedAt = 10:00:00
duration  = 45 minutes
targetEnd = 10:45:00
```

Then calculates remaining dynamically:

```text
remaining = targetEnd - currentTime
```

This allows the application to recover the timer state after lifecycle changes, interruptions, or orientation updates.

---

## 15. Focus Battles

Focus Battles are fundamentally different from solo sessions because they require multiple users.

**Solo:**

```text
User
 ↓
Local Timer
 ↓
Local History
```

**Battle:**

```text
User A
   │
   ├──────────┐
   │          │
   ▼          ▼
Backend ←→ Battle State
   ▲          ▲
   │          │
   └──────────┘
              │
           User B
```

Cloud connectivity is therefore required for real-time competitive functionality.

The app clearly distinguishes **Offline Features** from **Online Features** without compromising the offline experience.

---

## 16. Real-Time Battle Communication

Focus Battles will eventually require real-time communication.

Possible technologies include:

- WebSockets
- Server-Sent Events (SSE)
- Realtime backend services (e.g. Supabase Realtime, Firebase, custom socket server)

The exact technology can be selected when the backend is implemented. The architecture exposes this behind a repository/service interface so that the Flutter UI does not depend directly on the networking implementation.

---

## 17. Data Categories

LockIn data is categorized into three tiers:

### 17.1 Local-only
Data that does not need cloud synchronization:
```text
App preferences
Theme selection
Notification preferences
Haptic settings
Device-specific configuration
```

### 17.2 Local + Cloud
Data that exists offline but synchronizes when authenticated:
```text
Focus sessions
Daily statistics
Streaks
Goals
Profile preferences
```

### 17.3 Cloud-first
Data that inherently requires multiple users / online network:
```text
Friends
Focus Battles
Battle invitations
Leaderboards
Social relationships
```

---

## 18. Offline vs. Online Capability Matrix

| Feature | Offline | Account Required |
|:---|:---:|:---:|
| Focus Timer | ✅ | ❌ |
| Lock-In Mode | ✅ | ❌ |
| Custom Sessions | ✅ | ❌ |
| Daily Goals | ✅ | ❌ |
| Streaks | ✅ | ❌ |
| Session History | ✅ | ❌ |
| Local Statistics | ✅ | ❌ |
| Cloud Backup | ❌ | ✅ |
| Cross-device History | ❌ | ✅ |
| Friends | ❌ | ✅ |
| Focus Battles | ❌ | ✅ |
| Leaderboards | ❌ | ✅ |

The goal is to maximize the number of features available without an account.

---

## 19. Suggested Future Project Structure

As the application grows, the current structure can evolve toward:

```text
lib/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   └── utils/
│
├── models/
│   ├── focus_session.dart
│   ├── battle.dart
│   ├── user.dart
│   └── daily_stats.dart
│
├── data/
│   ├── local/
│   │   ├── database/
│   │   └── data_sources/
│   │
│   ├── remote/
│   │   ├── api/
│   │   └── data_sources/
│   │
│   └── repositories/
│
├── providers/
│
├── screens/
│   ├── home/
│   ├── focus/
│   ├── history/
│   ├── battles/
│   ├── profile/
│   └── result/
│
├── services/
│   ├── notifications/
│   ├── synchronization/
│   └── lifecycle/
│
└── widgets/
```

Architecture will evolve alongside actual requirements rather than being forced prematurely.

---

## 20. Technology Evolution Roadmap

```text
┌───────────────────────────────────────────────────────────┐
│ Phase 1: Lightweight Local App (Current)                  │
│ Flutter + Provider + SharedPreferences (Offline-First)     │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────┐
│ Phase 2: Embedded Database & Repositories                │
│ Structured SQLite / Drift persistence & sync status flags  │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────┐
│ Phase 3: Optional Authentication                          │
│ Seamless anonymous-to-authenticated account migration     │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────┐
│ Phase 4: Async Cloud Sync Engine                          │
│ Offline sync queue & cross-device backup                  │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────┐
│ Phase 5: Realtime Focus Battles                           │
│ WebSockets / Live 1v1 battle matchmaking                  │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────┐
│ Phase 6: Social & Competitive Layer                       │
│ Leaderboards, friends, streaks & weekly challenges         │
└───────────────────────────────────────────────────────────┘
```

---

## 21. Security Considerations

The local-first architecture does **not** mean that all client-submitted data is implicitly trusted by the backend.

For competitive features, the backend must validate important events:

- Clients cannot unilaterally declare arbitrary focus times without server validation.
- Focus Battle outcomes are finalized and authorized by the backend battle coordinator.
- Rate limiting and session verification prevent fabricated stats on public leaderboards.

---

## 22. Scalability Philosophy

LockIn avoids premature complexity:

- The initial application does not need microservices, complex distributed event buses, or multi-region clusters.
- Start simple with a robust local foundation and repository abstractions.
- Introduce distributed services and realtime socket servers when user scale demands it.

---

## 23. Key Architectural Decision

### Decision
**LockIn is built as a local-first application with progressive, optional cloud synchronization.**

### Reason
Productivity tools must have zero friction. Requiring network connectivity or account sign-up before allowing a user to focus undermines the app's core utility. The app is immediately functional out of the box, with cloud features serving as an additive upgrade.

---

## 24. Non-Goals

The following are explicitly **non-goals** of the core architecture:

- Forcing network dependencies onto the basic timer.
- Mandating sign-in or collecting unnecessary personal data.
- Introducing distributed microservice architecture prematurely.
- Sacrificing offline speed and privacy for cloud features.

---

---

## 26. Guest Focus Battle Subsystem

### 26.1 Principles
- **No Login Required:** Two users can create, share (via 6-character room codes), join, and complete live focus battles anonymously.
- **Anonymous Identity vs. Account:**
  - `anonymousId`: Random installation UUIDv4 stored locally.
  - `participantToken`: Ephemeral, scoped bearer token issued per battle room.
- **Authoritative Server Time:** Clocks are derived strictly from `serverStartTime + durationSeconds - currentTimestamp`. No per-second WebSocket tick spam.
- **Lock-In Coordination:** App lifecycle transitions (pause/hide) trigger forfeit after debounce, while network socket drops enter a 30s reconnect grace period before forfeit.
- **Non-Destructive Local Persistence:** Completed battles are saved locally in guest mode, ready for future non-destructive sync when an optional cloud account is registered.

