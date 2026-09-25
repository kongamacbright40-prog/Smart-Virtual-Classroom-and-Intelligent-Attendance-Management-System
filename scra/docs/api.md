# API (proposed contract)

The Flutter client targets a FastAPI backend:

```
Flutter ─▶ REST (JSON) ─▶ FastAPI ─▶ PostgreSQL
   └────▶ WebSocket (events, WebRTC signaling)
```

> This document describes the contract the client is **prepared** for. It is
> the single place (together with `lib/core/constants/api_endpoints.dart`)
> to update once the backend team finalizes routes. Only the WebRTC
> signaling socket already exists in the project.

## Conventions

- Base URL: `AppConfig.apiBaseUrl` + `AppConfig.apiPrefix` (default
  `http://10.0.2.2:8000/api/v1`).
- JSON bodies with `snake_case` keys, ISO-8601 timestamps, string enums
  (see the `value` of each Dart enum, e.g. `pending_lecturer`).
- Auth: `Authorization: Bearer <access_token>` on every request except the
  public auth endpoints.
- Lists may be returned as a bare array or as `{"items": [...], "total": n}`.
- Errors follow FastAPI: `{"detail": "message"}` or
  `{"detail": [{"loc": [...], "msg": "..."}]}` (422). The client maps
  400/409/422 → `ValidationException`, 401 → `AuthException` (session is
  cleared), 403 → `ForbiddenException`, 404 → `NotFoundException`,
  5xx → `ServerException`, timeouts/network → `TimeoutAppException` /
  `NetworkException`.

## Authentication

| Method | Path | Body | Response |
| --- | --- | --- | --- |
| POST | `/auth/login` | `{role, identifier, password}` | `AuthSession` |
| POST | `/auth/activate-student` | `{matricule, email, password}` | `AuthSession` |
| POST | `/auth/register-lecturer` | `{staff_id, email, password}` | `AuthSession` |
| POST | `/auth/password-reset/request` | `{email}` | `204` |
| POST | `/auth/password-reset/verify` | `{email, code}` | `204` |
| POST | `/auth/password-reset/confirm` | `{email, code, new_password}` | `204` |
| POST | `/auth/change-password` | `{current_password, new_password}` | `204` |
| POST | `/auth/logout` | – | `204` |

`AuthSession` = `{access_token, refresh_token?, expires_at?, user: User}`.

## Users & profiles

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/students/{id}` | `Student` (`user`, `matricule`, `programme`, `level`, `overall_attendance`...) |
| GET | `/lecturers/{id}` | `Lecturer` |
| GET | `/admins/{id}` | `Admin` |
| PATCH | `/users/{id}` | Profile update → `User` |
| GET | `/users?role=&q=` | Admin user search |
| POST | `/users` · PUT `/users/{id}` · DELETE `/users/{id}` | Admin CRUD |
| PATCH | `/users/{id}/status` | `{is_active}` |

## Courses

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/students/{id}/courses` | Enrolled courses |
| GET | `/lecturers/{id}/courses` | Assigned courses |
| GET | `/courses?status=&department_id=&q=` | Catalogue |
| GET/PUT | `/courses/{id}` | |
| POST | `/courses` | Create |
| POST | `/courses/{id}/assign-lecturer` | `{lecturer_id}` |
| POST | `/courses/{id}/archive` | |
| GET | `/courses/{id}/roster` | `Student[]` |
| GET | `/courses/{id}/sessions` | `ClassSession[]` |
| GET | `/courses/{id}/attendance/summaries` | `Attendance[]` per student |

## Sessions, scheduling & live classroom

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/students/{id}/sessions?from=&to=` | Timetable |
| GET | `/lecturers/{id}/sessions?from=&to=` | Teaching schedule |
| GET | `/sessions/{id}` | `ClassSession` |
| POST | `/schedules` | `Schedule` request → `Schedule` with `room_code`, `session_id` |
| POST | `/sessions/{id}/start` · `/end` | Lecturer |
| POST | `/sessions/{id}/join` · `/leave` | Participant presence |
| GET | `/sessions/{id}/participants` | `Participant[]` |
| PATCH | `/sessions/{id}/participants/{user_id}` | `{is_muted?, is_video_on?, is_screen_sharing?, is_hand_raised?}` |
| GET/POST | `/sessions/{id}/messages` | Chat history / send `{message, is_question}` |

## Attendance

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/students/{id}/attendance?course_id=` | `AttendanceRecord[]` |
| GET | `/students/{id}/attendance/summary?course_id=` | `Attendance` |
| GET | `/sessions/{id}/attendance` | Session records |
| POST | `/sessions/{id}/attendance/start` · `/end` | Capture window → `ClassSession` |
| POST | `/sessions/{id}/attendance/check-in` | `{student_id}` → record (server decides present/late) |
| PUT | `/sessions/{id}/attendance/{student_id}` | `{status}` manual adjustment |
| POST | `/attendance/{record_id}/appeals` | `{reason, document_name}` |

## Live questions

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/sessions/{id}/questions` | |
| POST | `/questions` | Save draft |
| POST | `/questions/{id}/launch` · `/close` · `/broadcast` | Lifecycle |
| POST | `/questions/{id}/responses` | `{selected_option_id}` |
| GET | `/questions/{id}/responses/{student_id}` | Own response |

## Notifications

| Method | Path |
| --- | --- |
| GET | `/users/{id}/notifications` |
| POST | `/notifications/{id}/read` |
| POST | `/users/{id}/notifications/read-all` |

## Administration & reports

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/faculties` | |
| GET | `/departments?faculty_id=` · POST `/departments` · PUT `/departments/{id}` · POST `/departments/{id}/archive` | |
| GET | `/academic-terms` · POST · PUT `/academic-terms/{id}` | |
| GET/PUT | `/settings/system` | `SystemSettings` |
| GET | `/admin/activity?limit=` | `ActivityLog[]` |
| GET | `/reports/admin-dashboard` | `Report` with metrics |
| GET | `/reports/lecturers/{id}?course_id=` | `Report` |
| GET | `/reports/institution?department_id=&term_id=` | `Report` |
| POST | `/reports/{id}/export` | `{format: pdf, xlsx or csv, include_matricule, include_geolocation}` → `{url}` or `{file_name}` |

## WebSockets

Base: `AppConfig.wsBaseUrl`. Token passed as `?token=` query parameter.

| Path | Purpose |
| --- | --- |
| `/ws/sessions/{session_id}/events` | Classroom events (`ClassroomController`). |
| `/ws/users/{user_id}/events` | Per-user notifications (reserved). |
| `/ws/classroom/{room_id}/{user_id}` | **Existing** WebRTC mesh signaling (`SignalingService`). |

Event envelope: `{"type": "...", "payload": {...}}`.

| Type | Payload |
| --- | --- |
| `participant.joined` / `participant.left` / `participant.updated` | `Participant` |
| `chat.message` | `ChatMessage` |
| `question.launched` / `question.updated` / `question.closed` | `Question` (with option counts) |
| `attendance.updated` | `AttendanceRecord` |
| `session.started` / `session.ended` | `ClassSession` |
| `notification.created` | `Notification` |

Signaling messages (existing server): `offer`, `answer`, `ice-candidate`
(`{type, target, payload}` sent; `{type, from, payload}` received) plus
`peer-joined` / `peer-left`.

Model field names for every payload are defined by the `toJson()` methods in
`lib/models/`.
