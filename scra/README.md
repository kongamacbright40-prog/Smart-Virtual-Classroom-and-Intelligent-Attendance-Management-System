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
| Launch | Splash with session restore, then straight to login |
| Authentication | Student / lecturer login, admin gateway, student / lecturer / admin registration (name, email, optional phone, ID; admins also need the admin registration code), password recovery (email → code → new password), remember-me session persistence, logout, role-based routing guards |
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
- Backend: FastAPI (`smart-classroom-api`) · REST · WebRTC signaling socket

## Architecture

Feature-first, layered: **screens → providers/controllers → repository
interfaces → REST/WebSocket implementations → services**. Screens never call
the network directly; tests swap the data layer for in-memory fakes. See [docs/architecture.md](docs/architecture.md).

```
Flutter UI ─▶ Repositories ─▶ ApiService (REST) ─▶ FastAPI ─▶ PostgreSQL
                 │
                 └─▶ WebSocketService (events) · WebRTCService (media + signaling)
```

## Requirements

- Flutter SDK (stable channel) with Dart **3.13** or newer (`flutter --version`)
- Android SDK / Android Studio with an emulator or a device (API 24+)
- The FastAPI backend (`smart-classroom-api`) running on your PC
- Camera + microphone permissions for live classes (declared in
  `AndroidManifest.xml`, requested at runtime)

## Setup

```bash
git clone https://github.com/kongamacbright40-prog/Smart-Virtual-Classroom-and-Intelligent-Attendance-Management-System.git
cd Smart-Virtual-Classroom-and-Intelligent-Attendance-Management-System/scra
flutter pub get
```

## Running

The app always talks to the Smart Class FastAPI backend (`smart-classroom-api`)
— there is no built-in demo or sample data. Data you see comes from the
server; fields the server does not provide are hidden or shown as "—".

### 1. Start the backend

From the `smart-classroom-api` folder:

```bash
venv\Scripts\activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

`--host 0.0.0.0` lets phones on your Wi-Fi reach it (allow Python through the
Windows firewall when asked). Open http://localhost:8000/docs to create data
(faculties, departments, courses). The first admin can register from the app
(Admin login → **Register as admin**) without a code; later admins need the
`ADMIN_REGISTRATION_CODE` set in the backend `.env`.

### 2. Run the app

| Target | Command | VS Code launch configuration |
| --- | --- | --- |
| Android emulator | `flutter run` | **Smart Class (Android emulator)** |
| Android phone (same Wi-Fi) | `flutter run --dart-define=API_BASE_URL=http://<PC-IP>:8000` | **Smart Class (Android phone on Wi-Fi)** (asks for the IP) |
| Chrome | `flutter run -d chrome` | **Smart Class (Chrome)** |

Defaults: `http://10.0.2.2:8000` on Android (the PC as seen from the
emulator) and `http://127.0.0.1:8000` in the browser. Find `<PC-IP>` with
`ipconfig` ("IPv4 Address", e.g. `192.168.1.10`). `WS_BASE_URL` defaults to
the same host (`ws://…`) and `API_PREFIX` to empty; override them with
`--dart-define` if needed. Do a full restart (not hot reload) after changing
`--dart-define` values.

**Web release build for testing on the laptop** (bundles the CanvasKit engine
instead of downloading it from Google each time, and serves it compressed):

```bash
flutter build web --release --no-web-resources-cdn
python tool/serve_web.py --port 8080      # http://localhost:8080
```

**Screen sharing:** from a browser (Chrome / Edge), choose *Entire screen* so
switching windows is shared, and tick *Also share system / tab audio* to let
students hear a video you play. Android phones share the screen picture only
(no sound).

Android notes: the manifest allows plain HTTP (`usesCleartextTraffic`) for the
development server and declares camera/microphone permissions for live
classes (requested at runtime when you join). Exported reports are saved to
the app's downloads folder (`Android/data/com.example.scra/files/Download`).

### 3. Sign in

Sign in with the account's **email** (the backend login is email-based).
Students can create their account from *Activate your account* and lecturers
from *Register as lecturer*. Without a reachable backend, screens show their
connection error state with a retry action.

Every screen is backed by the API: accounts (activation, password change and
reset — the reset code is printed in the backend console), profiles, courses
with lecturer assignment and department-based enrolment, faculties and
departments, scheduled and live classes, WebRTC signaling with automatic
attendance (late after the configured threshold), raised hands, chat, live
questions (drafts, launch, answers, results), attendance history, summaries
and appeals, notifications, academic terms, system settings, the admin
activity feed, dashboards/reports and PDF/Excel/CSV export. Live data is
polled every 3 seconds. Typical first run: register the admin, create a
faculty, department and course, assign a lecturer, and put students in the
department. See [docs/api.md](docs/api.md) for the full mapping.

## Testing

```bash
flutter analyze
flutter test
```

Tests cover model serialization, validators/formatters, the API client and
API repositories (with `MockClient`), storage/auth services, in-memory
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
│   ├── repositories/  interfaces · api/ (backend repositories & mappers)
│   ├── services/      api · auth · storage · notification · websocket · webrtc · file saver
│   ├── providers/     settings · classroom controller & registry
│   ├── widgets/       common · buttons · cards · inputs · dialogs · loading · navigation
│   └── features/      onboarding · authentication · student · lecturer · admin
└── test/              fakes (in-memory test data) · helpers · core · models ·
                       services · onboarding · authentication · student · lecturer · admin
```

## Backend architecture

The client talks to the FastAPI service in `smart-classroom-api`:

- REST contract: [docs/api.md](docs/api.md) (`lib/core/constants/api_endpoints.dart`)
- Entities: [docs/database.md](docs/database.md)
- Real-time: WebRTC mesh signaling (and automatic attendance) over
  `/ws/signal/{class_id}?token=`; other live data is polled until the backend
  adds a classroom event socket

Screen documentation: [docs/screens.md](docs/screens.md).
