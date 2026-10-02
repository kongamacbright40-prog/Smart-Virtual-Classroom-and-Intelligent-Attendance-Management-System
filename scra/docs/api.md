# API (Smart Class FastAPI backend)

The Flutter client talks to the FastAPI service in `smart-classroom-api`:

```
Flutter ─▶ REST (JSON) ─▶ FastAPI ─▶ SQLite / PostgreSQL
   └────▶ WebSocket /ws/signal/{class_id} (WebRTC signaling + attendance)
```

Paths live in `lib/core/constants/api_endpoints.dart`; backend JSON is converted
by `lib/repositories/api/backend_mappers.dart`. Keep all three in sync with the
routers in `smart-classroom-api/app/*/router.py` (interactive docs at
`http://<host>:8000/docs`).

## Conventions

- Base URL: `AppConfig.apiBaseUrl` + `AppConfig.apiPrefix` (prefix is empty;
  defaults: `http://10.0.2.2:8000` on the Android emulator, `http://127.0.0.1:8000`
  in Chrome; phones use the PC's LAN IP). The backend allows CORS from any
  `localhost` port (web only; Android needs no CORS).
- JSON bodies with `snake_case` keys. IDs are integers (the app keeps them as
  strings). Timestamps are UTC (`2026-09-28T10:00:00Z`; older payloads may omit
  the `Z` and are still read as UTC).
- Lists are pages: `{"items": [...], "total", "page", "page_size"}`; the client
  requests `page_size=100` (the backend maximum). A few endpoints return bare
  arrays (roster, messages, participants, attendance history, terms, activity).
- Auth: `Authorization: Bearer <access_token>`. On a 401 the client calls
  `/auth/refresh` once and retries; if that fails the session is cleared.
  Deactivated accounts get 401/403.
- Errors follow FastAPI: `{"detail": "message"}` or 422 `{"detail": [...]}`.
  400/409/422 → `ValidationException`, 401 → `AuthException`, 403 →
  `ForbiddenException`, 404 → `NotFoundException`, 5xx → `ServerException`.
- Live data is polled every 3 s (participants, chat, questions, attendance);
  notifications every 15 s. There is no classroom event socket.

## Authentication & profile

| Method | Path | Body / notes |
| --- | --- | --- |
| POST | `/auth/register` | `{full_name, email, password, role, matricule_number, phone_number?, department_id?, admin_code?}`. `admin_code` (= backend `ADMIN_REGISTRATION_CODE`) is required for `role: admin` once an admin exists. Also **activates** an account an admin created without a password (same email + role; no code needed). |
| POST | `/auth/login` | `{email, password}` → `{access_token, refresh_token}`; the app then loads `/auth/me` and checks the role matches the portal |
| GET / PATCH | `/auth/me` | Profile (`department`, `is_active`, `created_at`, `last_login_at`); PATCH `{full_name?, phone_number?}` |
| POST | `/auth/refresh` | `{refresh_token}` |
| POST | `/auth/change-password` | `{current_password, new_password}` |
| POST | `/auth/password-reset/request` · `/verify` · `/confirm` | `{email}` · `{email, code}` · `{email, code, new_password}`. The 4-digit code is printed in the **backend console** (no e-mail service yet). |

## Catalogue

| Method | Path | Notes |
| --- | --- | --- |
| GET / POST | `/faculties` | With department/course/student/staff counts |
| GET / POST | `/departments?faculty_id=` | With counts and `is_active` |
| PATCH | `/departments/{id}` | `{name?, faculty_id?}` |
| POST | `/departments/{id}/archive` | |
| GET | `/courses?department_id=&q=&include_archived=` | Catalogue |
| GET | `/courses/mine` | Students: enrolled courses; lecturers: assigned courses |
| GET / PATCH | `/courses/{id}` | PATCH `{code?, title?, department_id?, description?, credits?}` |
| POST | `/courses` | `{code, title, department_id, description?, credits?, lecturer_id?}` |
| POST | `/courses/{id}/assign-lecturer` | `{lecturer_id}` (notifies the lecturer) |
| POST | `/courses/{id}/archive` | |
| GET | `/courses/{id}/roster` | Students of the course |
| POST / DELETE | `/courses/{id}/enrollments` · `/courses/{id}/enrollments/{profile_id}` | Admin adds / removes a student (Admin → Courses → course → Enrolled Students) |
| POST / DELETE | `/courses/{id}/enroll` | Student joins / leaves a course outside their department (Courses tab → *Enroll in a course*). Department courses can't be dropped (400) |
| GET | `/departments/public` | No login: active departments for the registration forms |

`CourseOut` includes `lecturer`, `credits`, `description`, `is_archived`,
`enrolled_count` and `sessions_held`. For students it also has `enrollment`:
`"department"`, `"explicit"` or `null`. A course without lecturer shows as
*Pending Lecturer* in the app.

**Enrolment rule:** a student takes every active course of their department
(chosen at registration, or set by an admin in user details) plus any course
they enrolled in themselves or an admin added them to.

## Classes

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/classes?course_id=&live_only=&from=&to=` | Admins: all; lecturers: their classes; students: classes of their courses |
| GET | `/classes/{id}` | `ClassSessionOut` |
| POST | `/classes/schedule` | `{course_id, title?, scheduled_start, duration_minutes}` (future classes; students are notified) |
| POST | `/classes` | `{course_id, title?, duration_minutes?}` — start a class now |
| POST | `/classes/{id}/start` · `/end` | Lecturer; starting notifies students ("Join Now"). Admins may also end any class |

Classes left running long after their expected end (duration, or 2 h when
unset, plus 1 h grace) with nobody connected are closed automatically, so they
stop counting as "Active Classes".
| GET | `/classes/{id}/participants` | People connected to the signaling socket, with raised hands |
| PUT | `/classes/{id}/hand` | `{raised}` |
| GET / POST | `/classes/{id}/messages?after_id=` | Chat: `{message, is_question}` |

`ClassSessionOut` = `{id, course_id, lecturer_id, title, scheduled_start,
duration_minutes, started_at, ended_at, status (scheduled|live|completed),
course, lecturer, participant_count, expected_count}`. Lecturers may run
classes for their assigned courses (or unassigned ones).

## Attendance

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/attendance/sessions/{id}` | `AttendanceOut[]` for a class |
| POST | `/attendance/sessions/{id}/mark` | Lecturer: `{profile_id, status}` (notifies the student) |
| GET | `/attendance/me?course_id=` | Student history: every finished class of their courses (absent when never joined) |
| GET | `/attendance/courses/{id}/summary` | Per-student present/late/absent/excused counts |
| POST | `/attendance/sessions/{id}/appeals` | Student: `{reason, document_name?}` (notifies the lecturer) |

Statuses map `present ↔ present`, `partial ↔ late`, `absent ↔ absent`,
`excused ↔ excused`. Check-in is automatic: connecting to the signaling socket
marks the student present, or late (`partial`) after the late-arrival
threshold from system settings. Student history ids are `session-<class id>`.

## Live questions

| Method | Path | Notes |
| --- | --- | --- |
| POST | `/participation/sessions/{id}/questions` | `{question_type: mcq, prompt, options: [{text, is_correct}], launch}`; `launch: false` saves a draft |
| POST | `/participation/questions/{id}/launch` · `/close` | Only one live question per class |
| GET | `/participation/sessions/{id}/questions` | Lecturer: all questions with answers and per-option `response_count` |
| GET | `/participation/sessions/{id}/questions/open` | Students: open questions |
| POST | `/participation/questions/{id}/respond` | `{selected_option_id}`; 409 if already answered |
| GET | `/participation/questions/{id}/responses/me` | The student's answer or `null` |

"Broadcast results" closes the question (students see correctness as soon as
they answer).

## Notifications, terms, settings, activity

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/notifications?unread_only=` | Newest first |
| POST | `/notifications/{id}/read` · `/notifications/read-all` | |
| GET / POST / PUT | `/academic-terms` · `/academic-terms/{id}` | Only one active term |
| GET / PUT | `/settings/system` | Minimum attendance, late threshold, … (PUT admin) |
| GET | `/admin/activity?limit=` | Admin audit feed |

Notification types: `class_reminder`, `new_course`, `attendance_update`,
`live_question`, `announcement`.

## Administration

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/admin/users?role=&q=` | |
| POST | `/admin/users` | `{full_name, email, role, phone_number?, matricule_number?, department_id?, password?}` — without a password the account is **pending activation** |
| PATCH | `/admin/users/{id}` | `{full_name?, email?, phone_number?, matricule_number?, department_id?}` |
| PATCH | `/admin/users/{id}/status` | `{is_active}` |
| DELETE | `/admin/users/{id}` | 409 when the user has class history (deactivate instead) |
| GET | `/admin/sessions?live_only=` | |

## Reports

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/reports/overview` | Admin dashboard metrics |
| GET | `/reports/lecturer?course_id=&lecturer_id=` | Lecturer rates, weekly trend and per-course breakdown |
| GET | `/reports/institution?department_id=` | Faculty + course breakdown |
| GET | `/reports/attendance.{pdf,xlsx,csv}` | One of `session_id`, `course_id`, `lecturer_id`, `department_id` (none = institution, admins) |

Reports use the app's `ReportModel` JSON shape. Rates only count finished
classes; metrics are omitted (not zero) when there is no data yet. Report ids
(`course-3`, `lecturer-5`, `session-11`, …) select the export scope.

## WebSocket signaling

`/ws/signal/{class_id}?token=<access_token>` (base `AppConfig.wsBaseUrl`).
Students may connect once the class has started and only for their courses.

| Direction | Message |
| --- | --- |
| client → server | `{type: offer \| answer \| ice_candidate, target_peer_id: <int>, payload}` |
| server → client | same message plus `from_peer_id` |
| server → client | `room_state {peers}`, `peer_joined {peer_id, full_name, role}`, `peer_left {peer_id}`, `session_ended`, `error {detail}` |
| lecturer → server → others | `{type: board, op: show \| hide \| clear \| undo}`, `{type: board, op: begin, id, color (ARGB int), width, points}`, `{type: board, op: extend, id, points}`; points are `[[x, y], ...]` and width a fraction of the board size (0..1). Messages from students are ignored |
| server → client (on join) | `board_state {active, strokes}`: the current whiteboard, so late joiners see it |

`SignalingService` normalizes incoming messages to `{type, from, payload}`.
Existing participants send the offer to each newcomer.

**Screen sharing** replaces the outgoing video track (no renegotiation); every
peer connection has a video channel even without a camera. On Android the app
first asks for capture consent, then runs `ScreenCaptureService` (a
`mediaProjection` foreground service) while sharing.
