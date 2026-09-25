# Architecture

Smart Class is an Android-first Flutter application with three role-based
experiences (Student, Lecturer, Administrator) built on a layered,
feature-first architecture. The UI never talks to the network directly; it
depends on repository interfaces whose implementations can be swapped from
the FastAPI backend to in-memory test fakes without touching screens.
The app itself ships no sample data: it always uses the API
implementations.

```
┌──────────────────────────────────────────────────────────────┐
│ Presentation  lib/features/**  +  lib/widgets/**              │
│   Screens (StatelessWidget / small StatefulWidget UI state)   │
├──────────────────────────────────────────────────────────────┤
│ State         provider (ChangeNotifier)                       │
│   AuthProvider · SettingsProvider · ClassroomController       │
├──────────────────────────────────────────────────────────────┤
│ Domain        lib/repositories/repositories.dart (interfaces) │
│               lib/models/** (typed JSON models)               │
├──────────────────────────────────────────────────────────────┤
│ Data          lib/repositories/api/**   (REST + WebSocket)    │
│               test/fakes/**  (in-memory fixtures, tests only) │
├──────────────────────────────────────────────────────────────┤
│ Services      ApiService · StorageService · AuthService       │
│               WebSocketService · WebRTCService ·              │
│               NotificationService                             │
└──────────────────────────────────────────────────────────────┘
```

## Folders

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | Bootstraps bindings, global error handlers, portrait lock, and `AppDependencies.create()`. |
| `lib/app.dart` | `SmartClassApp`: registers every dependency/provider and builds the themed `MaterialApp` with `AppRouter`. |
| `lib/core/constants` | Design tokens (`AppColors`, `AppDimensions`), strings, assets, `AppConfig` (dart-define configuration), `ApiEndpoints`, `StorageKeys`. |
| `lib/core/theme` | Material 3 light/dark themes generated from the Stitch palette. |
| `lib/core/routing` | `RouteNames`, tab indexes and the role-guarded `AppRouter`. |
| `lib/core/di` | `AppDependencies` composition root (API graph; tests build a fake graph). |
| `lib/core/utils` | `Validators`, `Formatters`, `AppDateUtils`, `Helpers`. |
| `lib/core/errors` | `AppException` hierarchy and `ErrorHandler`. |
| `lib/models` | Null-safe models with `fromJson`/`toJson`/`copyWith` (snake_case JSON). |
| `lib/repositories` | Interfaces (`repositories.dart`) and `api/` implementations. |
| `lib/services` | API client, storage, auth session, notifications, WebSocket and WebRTC (with the original signaling/peer-connection code in `services/webrtc/`). |
| `lib/providers` | Cross-feature state: `SettingsProvider`, `ClassroomController`, `ClassroomRegistry`/`ClassroomScope`. |
| `lib/widgets` | Reusable UI: scaffold, app bar, states, buttons, cards, inputs, dialogs, loaders, role navigation shells. |
| `lib/features/<feature>` | Screens and feature widgets for onboarding, authentication, student, lecturer and admin. |
| `test/` | Unit and widget tests mirroring `lib/`. |
| `docs/` | This documentation. |

## State management

The app uses [`provider`](https://pub.dev/packages/provider) with
`ChangeNotifier`, the lightest option that keeps state separated:

- **UI state** – local `StatefulWidget` fields (selected tab, filter, form
  controllers).
- **Application state** – `SettingsProvider` (theme, preferences) and
  `ClassroomController` (one per live session, shared by the classroom,
  chat, question, whiteboard and live-attendance screens through
  `ClassroomScope` + `ClassroomRegistry`, reference counted).
- **Authentication state** – `AuthProvider` (status, current user, busy/error
  flags, onboarding and role selection).
- **Repository state** – owned by repositories; screens load it through
  `AsyncView`, which renders loading / error + retry / empty / data states.

## Data flow

```
Screen ──calls──▶ Repository interface ──▶ Api… implementation
  ▲                                              │
  │                                 ApiService (REST, JSON, timeouts,
  │                                 bearer token, error mapping)
  └──── AsyncView / ChangeNotifier ◀── Stream / Future results
```

Real-time data (participants, chat, questions, attendance, notifications)
is exposed as `Stream`s on the repositories. The API implementations
re-fetch or map payloads when `WebSocketService` receives events
(`participant.*`, `chat.message`, `question.*`, `attendance.*`,
`notification.created`). Audio/video goes through `FlutterWebRTCService`,
built on the existing mesh signaling. Tests use the in-memory fakes in
`test/fakes/` (`FakeDependencies`).

Errors are normalized into `AppException` subtypes (`NetworkException`,
`TimeoutAppException`, `AuthException`, `ValidationException`...). Global
Flutter/platform errors are logged by `ErrorHandler.installGlobalHandlers`
instead of crashing the app.

## Authentication flow

```
Splash ─ AuthProvider.bootstrap()
   ├─ session restored ─────────────▶ role home (/student, /lecturer, /admin)
   ├─ onboarding not completed ────▶ Welcome ▶ Attendance ▶ Participation ▶ Role selection
   └─ otherwise ───────────────────▶ Login (student/lecturer) or Admin Login

Login ─ AuthRepository.login(role, identifier, password)
   └─ AuthService.start(session, persist: rememberMe) ─ StorageService
         └─ pushNamedAndRemoveUntil(AppRouter.homeFor(role))

Logout ─ AuthProvider.logout() ─ AuthService.clear() ─ back to login
401 from API ─ ApiService.onUnauthorized ─ AuthProvider.handleSessionExpired ─ login
```

`AppRouter.onGenerateRoute` guards every route: `/student/**` requires a
student, `/lecturer/**` a lecturer and `/admin/**` an administrator.
Unauthenticated users are redirected to the right login screen; signed-in
users opening another role's route get the *Access denied* page.

## Configuration

All environment values live in `AppConfig` and are overridable at build time:

```
flutter run \
  --dart-define=API_BASE_URL=https://smartclass.example.edu \
  --dart-define=WS_BASE_URL=wss://smartclass.example.edu
```

## Decisions

- **Design fidelity** – Stitch HTML/Tailwind was translated into Flutter
  widgets; photographs/illustrations were replaced by gradient + icon
  compositions and initials avatars because the generated artwork is not
  part of the repository. The login and forgot-password Stitch exports
  render with a dark page background around light content; the app uses the
  light surface consistently with the other screens.
- **Typography** – Stitch uses Inter. To avoid a runtime font download
  dependency the app uses the platform font (Roboto on Android) with the
  Stitch size/weight scale. Bundle Inter under `assets/fonts` to match
  exactly.
- **Navigation** – `Navigator` named routes with a guard (no routing
  package). Role homes are bottom-navigation shells (`RoleShell`); the admin
  shell adds a drawer for sections that are not bottom tabs.
- **Dependencies** – only `provider`, `shared_preferences`, `http`,
  `web_socket_channel` and the pre-existing `flutter_webrtc`.
- **Attendance statuses** – present, late, absent plus *excused* (shown in the
  Stitch course details and live attendance designs).
- **Storage** – `shared_preferences` behind `KeyValueStore`; move tokens to a
  secure store (e.g. Android Keystore) before production by adding another
  `KeyValueStore` implementation.
