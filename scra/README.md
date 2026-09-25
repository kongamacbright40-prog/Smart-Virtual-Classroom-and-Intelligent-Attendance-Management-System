# Smart Class

**Smart Virtual Classroom & Intelligent Attendance Management System** — an
Android-first Flutter application for universities with dedicated
experiences for **students**, **lecturers** and **administrators**.

Students join live lectures, chat, answer live questions and track their
attendance. Lecturers schedule and run live classes, launch participation
questions, manage attendance in real time and review reports.
Administrators manage users, academic structure, terms, courses, policies
and institution-wide analytics.

The UI is a Flutter/Material 3 recreation of the approved Google Stitch
designs (screens 01–40; the design package has no screen 37).

## Features

| Area | Highlights |
| --- | --- |
| Onboarding | Splash with session restore, 3-step introduction, portal (role) selection |
| Authentication | Student / lecturer login, admin gateway, student activation, lecturer registration, password recovery (email → code → new password), remember-me session persistence, logout, role-based routing guards |
| Student | Home dashboard, courses & course details, weekly schedule, live classroom (participants, media controls, raise hand), classroom chat, live questions, attendance history & appeals, notifications, profile, settings (theme, notifications, classroom defaults) |
| Lecturer | Teaching dashboard, courses & student roster, schedule class, live classroom controls, whiteboard / screen share, create & monitor live questions, live attendance management, attendance reports, profile |
| Admin | Campus dashboard, user management, departments & faculties, academic terms, course management & lecturer assignment, reports & analytics with export, system policies, admin profile |
| Platform | REST-ready repositories, WebSocket event layer, WebRTC abstraction (built on the existing mesh signaling), notification service, centralized validation, loading/empty/error states, responsive layouts |

## Technology stack

- Flutter (stable) · Dart 3.13+ · Material 3
- State management: `provider` (`ChangeNotifier`)
- Networking: `http` (REST), `web_socket_channel` (WebSocket)
- Real-time media: `flutter_webrtc`
- Persistence: `shared_preferences` behind a storage abstraction
- Future backend: FastAPI · PostgreSQL · WebSockets · WebRTC signaling

## Architecture

Feature-first, layered: **screens → providers/controllers → repository
interfaces → mock or API implementations → services**. Screens never call
the network directly, so the mock data layer can be replaced by the FastAPI
backend by flipping one flag. See [docs/architecture.md](docs/architecture.md).

```
Flutter UI ─▶ Repositories ─▶ ApiService (REST) ─▶ FastAPI ─▶ PostgreSQL
                 │
                 └─▶ WebSocketService (events) · WebRTCService (media + signaling)
```

## Requirements

- Flutter SDK (stable channel) with Dart **3.13** or newer (`flutter --version`)
- Android SDK / Android Studio with an emulator or a device (API 24+)
- For the optional real media mode: camera + microphone permissions (already
  declared in `AndroidManifest.xml`)

## Setup

```bash
git clone https://github.com/kongamacbright40-prog/Smart-Virtual-Classroom-and-Intelligent-Attendance-Management-System.git
cd Smart-Virtual-Classroom-and-Intelligent-Attendance-Management-System/scra
flutter pub get
```

## Running

```bash
# Mock data (default) — no backend required
flutter run

# Against a FastAPI backend
flutter run \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=WS_BASE_URL=ws://10.0.2.2:8000

# Real camera/microphone through the existing WebRTC signaling server
flutter run --dart-define=ENABLE_REALTIME_MEDIA=true --dart-define=WS_BASE_URL=ws://<server>:8000
```

### Demo accounts (mock mode)

| Role | Identifier | Password |
| --- | --- | --- |
| Student | `ICT20251181` or `konga.macbright@student.univ.edu` | `Password123!` |
| Lecturer | `FAC-2024-8192` or `k.mensah@smartclass.edu.ac` | `Password123!` |
| Admin | `ADM-001` or `admin.root@smartclass.edu` | `Password123!` |

Password recovery code in mock mode: `8429`. A CS-301 lecture is always
"live now" in the mock data so the classroom flows can be tried immediately.

## Testing

```bash
flutter analyze
flutter test
```

Tests cover model serialization, validators/formatters, the API client and
API repositories (with `MockClient`), storage/auth services, mock
repositories, the classroom controller, onboarding and authentication flows,
role-based routing, and the student, lecturer and admin navigation paths
(including small-phone overflow checks). GitHub Actions runs analyze + test on
every push and pull request (`.github/workflows/flutter.yml`).

## Project structure

```
scra/
├── assets/            logos, images, icons, animations
├── docs/              architecture.md · api.md · database.md · screens.md
├── lib/
│   ├── main.dart · app.dart
│   ├── core/          constants · theme · routing · di · utils · errors
│   ├── models/        typed JSON models
│   ├── repositories/  interfaces · mock/ · api/
│   ├── services/      api · auth · storage · notification · websocket · webrtc
│   ├── providers/     settings · classroom controller & registry
│   ├── widgets/       common · buttons · cards · inputs · dialogs · loading · navigation
│   └── features/      onboarding · authentication · student · lecturer · admin
└── test/              core · models · services · onboarding · authentication · student · lecturer · admin
```

## Future backend architecture

The client is prepared for a FastAPI service backed by PostgreSQL:

- REST contract: [docs/api.md](docs/api.md) (`lib/core/constants/api_endpoints.dart`)
- Entities: [docs/database.md](docs/database.md)
- Real-time: classroom events over `/ws/sessions/{id}/events`; WebRTC mesh
  signaling over the existing `/ws/classroom/{room}/{user}` endpoint
- Switch from mocks to the API with `--dart-define=USE_MOCK_DATA=false`

Screen documentation: [docs/screens.md](docs/screens.md).
