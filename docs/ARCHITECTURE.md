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

## 16. Real-Time Battle Communication Subsystem

Focus Battles are powered by a dedicated, low-latency Node.js WebSocket service:
- **Server Component**: Located in `server/server.js` using native `ws`.
- **Cloud Hosting**: Deployed on Render with automated `/health` checks.
- **Data Source**: `WebSocketBattleDataSource` in `lib/services/websocket_battle_data_source.dart`.
- **Matchmaking & State**: Completely authoritatively managed in-memory via 6-character room codes. No account or database persistence required for battles.
- **Heartbeats**: Automatic 30-second ping/pong cycles preventing mobile OS socket sleep.

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

---

## 27. Cloud Backup & Authentication Subsystem (Supabase)

### 27.1 Architectural Overview
The cloud backup subsystem adheres strictly to the **Local-First, Cloud-Optional** philosophy. All focus tracking, streaks, and settings operate entirely offline. When a user optionally links a Google account via Supabase:
- Local data is never overwritten destructively; it merges symmetrically with remote data.
- Sync operations are non-blocking and happen asynchronously in the background.

```text
Local Storage (SharedPrefs) 
       ▲
       │  (Bi-directional Merge)
       ▼
SupabaseService (Client)
       ▲
       │  (HTTPS / TLS / PKCE)
       ▼
Supabase Cloud (Auth + Postgres RLS)
  ├── auth.users (Google OAuth 2.0)
  ├── profiles (Streaks, Goals, Preferences)
  └── focus_sessions (Permanent Focus Log)
```

### 27.2 Authentication Flow (Google OAuth with PKCE)
1. **Flow Initiation**: User taps **Continue with Google** in `CloudSyncModal`.
2. **PKCE Authorization**: `Supabase.instance.client.auth.signInWithOAuth` requests authorization with redirect URI `io.supabase.lockin://login-callback`.
3. **Deep Link Callback**: Upon successful browser authentication, Android routes the redirect through `io.supabase.lockin://login-callback` to `MainActivity`.
4. **Session Exchange**: The Supabase SDK intercepts the PKCE `code` and exchanges it for a secure JWT session token.

### 27.3 Automatic Synchronization Triggers
Data synchronization occurs automatically across key application lifecycles without requiring manual user intervention:
- **On Sign-In**: Initial bi-directional sync merges cloud history with local records and uploads local profile data.
- **On App Startup**: If an active auth session exists, a background sync runs to refresh data silently.
- **On Session Completion**: Winning or forfeiting any focus block triggers an immediate background push of the new `FocusSession` and updated streak.
- **On Settings Update**: Modifying nickname, daily target, avatar, or strict anti-distraction mode immediately upserts the changes to the `profiles` table.
- **Manual "Sync Now"**: Accessible within `CloudSyncModal` for manual verification.

### 27.4 Database Schema & Security
```sql
-- Profiles table
create table public.profiles (
  id uuid references auth.users not null primary key,
  display_name text,
  avatar_path text,
  streak integer default 0,
  daily_goal_minutes integer default 240,
  is_strict_anti_distraction boolean default true,
  updated_at timestamp with time zone default now()
);

-- Focus Sessions table
create table public.focus_sessions (
  id uuid primary key,
  user_id uuid references auth.users not null,
  duration_minutes integer not null,
  target_duration_minutes integer,
  date_time timestamp with time zone not null,
  is_win boolean default true,
  session_type text default 'solo',
  opponent_name text,
  opponent_score text
);

-- Row Level Security (RLS)
alter table public.profiles enable row level security;
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

alter table public.focus_sessions enable row level security;
create policy "Users can view own sessions" on public.focus_sessions for select using (auth.uid() = user_id);
create policy "Users can insert own sessions" on public.focus_sessions for insert with check (auth.uid() = user_id);
create policy "Users can update own sessions" on public.focus_sessions for update using (auth.uid() = user_id);
```

---

## 28. Display Keep-Awake Subsystem (Strict Anti-Distraction)

### 28.1 Architectural Problem & Rationale
In strict anti-distraction mode, leaving the application or locking the device causes an `AppLifecycleState.paused` transition that forfeits the session after a brief debounce period. However, standard mobile operating systems automatically dim and turn off the display after 30–60 seconds of inactivity. Without active screen management, sitting at a desk and focusing without touching the screen would cause the OS to sleep the display, inadvertently triggering a session forfeit.

### 28.2 Design & Lifecycle Integration
- **`ScreenWakeService` Wrapper**: Encapsulates `wakelock_plus` using `FLAG_KEEP_SCREEN_ON` on Android and `isIdleTimerDisabled` on iOS.
- **Window-Level Scope**: Does not require dangerous CPU background `WAKE_LOCK` permissions; applies purely to the active foreground activity window.
- **Strict Mode Coupled**: Keep-awake is active exclusively during running strict sessions (`isStrictAntiDistraction == true`).
- **Guaranteed Cleanup**:
  - Immediately released upon session win, loss, forfeit, timer reset, or screen disposal (`FocusScreen` and `BattleFocusScreen`).
  - Releases upon `AppLifecycleState.paused` and re-engages upon `AppLifecycleState.resumed` if the session remains valid.

---

## 29. Finish Cue & Sensory Feedback Subsystem

### 29.1 Product Philosophy
> **LockIn should never behave like an alarm clock. Completion feedback is an acknowledgment, not an alert.**

Standard productivity apps often use harsh, high-frequency alarm tones or celebratory fanfares that startle users out of flow state. LockIn treats completion as a gentle, calming transition back to awareness.

### 29.2 Sensory Architecture
```text
Session Outcome (TimerProvider / BattleProvider)
               │
               ▼
   CompletionFeedbackService
               │
       ┌───────┴────────┐
       ▼                ▼
  AudioPlayer      HapticFeedback
  (Low Latency)    (Subtle Pulses)
```

- **`CompletionFeedbackService` Abstraction**: An abstract contract decoupling state providers from platform audio and haptic drivers, enabling frictionless mocking in unit test suites.
- **Curated Acoustic Tones**:
  - **`Soft Bell`** (Default tone when sound is on): 523.25 Hz warm harmonic bell with soft cosine attack and 2.4s natural exponential decay.
  - **`Warm Tone`**: 392 Hz deep acoustic resonance with soft 2.0s decay.
  - **`Gentle Chime`**: 659.25 Hz delicate acoustic chime with 1.9s decay.
  - *No Sharp Transients*: Gentle 40–60ms cosine attack ramps eliminate transient pop/click artifacts and avoid startling the user.
- **Relative Volume Scaling**: Audio volume is set to `0.5` relative to user media volume; it never overrides system volume levels.
- **Tactile Modes**:
  1. **Silent (Off — Default)**: Pure visual transition; no audio or haptic trigger.
  2. **Vibration Only (Library Mode)**: Completely silent; subtle double-pulse (`• •`) haptic designed for quiet study halls, libraries, and open offices.
  3. **Sound + Haptics**: Soft acoustic tone paired with the subtle double-pulse haptic.
- **Non-Punitive Forfeits**: Forfeiting triggers a gentle single tactile click (`•`) with zero audio, reinforcing accountability without punitive buzzer sounds.
- **Single Source of Truth & Deduplication**: Built-in 1.5-second suppression guard ensures multiplayer battle synchronization and local timers never produce duplicate completion audio.

---

## 30. Flow-State Session Extension Subsystem

### 30.1 Philosophy & State Mechanics
When a user completes an intense focus block (e.g. 25 minutes) and is in deep flow, breaking concentration to configure a new timer creates friction. The **Session Extension** subsystem allows users to directly extend their current session from the completion screen while protecting completed work.

```text
[Completed 25m Session (Won)]
           │
           ▼
[ResultScreen: Extend Card (+5m default, stepper, chips)]
           │
           ├── Taps Extend (+5m)
           │          │
           │          ▼
           │  [FocusScreen: Extending (+25m saved)]
           │          │
           │     ┌────┴────────────────────────┐
           │     ▼                             ▼
           │  [Completes Extension]     [Interrupted / Lockout / Exit]
           │     │                             │
           │     ▼                             ▼
           │  Update Session to 30m       Preserve Base 25m Win
           │  - Local storage & history   - Keep isWin: true
           │  - Supabase upsert (same id) - Protect streak from penalty
           │  - Additional battle score   - Display reassurance banner
```

### 30.2 Core Components & State Machine
1. **`FocusSession.copyWith`**: Enables creating updated session instances with new `durationMinutes` and `targetDurationMinutes` while preserving immutable ID, timestamps, and battle metadata.
2. **`StorageService.updateSession`**: Replaces the matching session in persistent storage (`focus_history`) without re-incrementing or resetting the streak.
3. **`TimerProvider.extendSession(int extensionMinutes)`**:
   - Captures `_extendingSessionId` and `_baseCompletedMinutes`.
   - Transitions state to `SessionStatus.running` for the extended duration.
   - Activates notification and screen wake safeguards.
4. **Resilient Failure Recovery**:
   - If an extension is forfeited or strictly locked out, `TimerProvider` preserves `SessionStatus.won`, sets `_totalSeconds = baseCompletedMinutes * 60`, flags `_extensionInterrupted = true`, and avoids any streak penalty.
   - The user returns to `ResultScreen` with a prominent reassurance banner: *"Extension ended early. Your 25m session was safely recorded!"*.
