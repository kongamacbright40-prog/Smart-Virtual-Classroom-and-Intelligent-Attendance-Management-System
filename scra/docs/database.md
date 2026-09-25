# Database (proposed PostgreSQL entities)

These entities mirror the Flutter models in `lib/models/`. They describe what
the client expects the backend to persist; column names match the JSON keys.
Final schema, constraints and migrations belong to the FastAPI backend.

```
faculties 1─* departments 1─* courses *─1 academic_terms
users 1─1 students | lecturers | admins
courses *─* students (enrollments)
courses 1─* class_sessions 1─* attendance_records *─1 students
class_sessions 1─* questions 1─* question_options
questions 1─* question_responses *─1 students
class_sessions 1─* chat_messages *─1 users
users 1─* notifications
attendance_records 1─* attendance_appeals
```

## Identity

| Table | Key columns |
| --- | --- |
| `users` | `id` PK, `full_name`, `email` UNIQUE, `password_hash`, `role` (`student`/`lecturer`/`admin`), `phone`, `avatar_url`, `department_id` FK, `is_active`, `created_at`, `last_active_at` |
| `students` | `user_id` PK/FK, `matricule` UNIQUE, `programme`, `level`, `semester`, `faculty_id` FK, `gpa`, `campus_pass_valid` |
| `lecturers` | `user_id` PK/FK, `staff_id` UNIQUE, `title`, `specialization`, `office_location`, `office_hours` |
| `admins` | `user_id` PK/FK, `admin_id` UNIQUE, `access_level` (`departmental`/`faculty`/`system`), `job_title`, `permissions` (text[]), `two_factor_enabled`, `last_login_at` |
| `refresh_tokens` | `id`, `user_id` FK, `token_hash`, `expires_at`, `revoked_at` |
| `password_resets` | `id`, `user_id` FK, `code_hash`, `expires_at`, `used_at` |

## Academic structure

| Table | Key columns |
| --- | --- |
| `faculties` | `id`, `name`, `code` UNIQUE, `dean_name`, `category`, `is_active` |
| `departments` | `id`, `faculty_id` FK, `name`, `code` UNIQUE, `description`, `head_name`, `is_active` |
| `academic_terms` | `id`, `name`, `code` UNIQUE, `academic_year`, `start_date`, `end_date`, `status` (`planned`/`active`/`archived`), `term_type`, `teaching_days`, `enrollment_open`, `add_drop_deadline`, `notes` |
| `courses` | `id`, `code` UNIQUE per term, `title`, `description`, `category`, `credits`, `credit_note`, `lecturer_id` FK NULL, `department_id` FK, `term_id` FK, `status` (`active`/`pending_lecturer`/`draft`/`archived`), `capacity`, `total_sessions`, `schedule_summary`, `room`, `virtual_room_url`, `topics` (text[]) |
| `enrollments` | `course_id` FK, `student_id` FK, `enrolled_at`; PK (`course_id`, `student_id`) |

Counts shown in the UI (`enrolled_count`, `course_count`, `student_count`,
`average_attendance`...) are derived (views or aggregate queries), not stored.

## Classes & attendance

| Table | Key columns |
| --- | --- |
| `class_sessions` | `id`, `course_id` FK, `title`, `session_number`, `start_time`, `end_time`, `room`, `mode` (`in_person`/`virtual`/`hybrid`), `status` (`scheduled`/`live`/`completed`/`cancelled`), `attendance_active`, `late_threshold_minutes`, `enable_questions`, `room_code` |
| `schedules` | `id`, `course_id` FK, `session_id` FK, `topic`, `start_time`, `duration_minutes`, `late_threshold_minutes`, `enable_questions`, `room`, `mode`, `room_code`, `created_by` FK, `created_at` |
| `session_materials` | `id`, `session_id` FK, `file_name`, `url` |
| `session_participants` | `session_id` FK, `user_id` FK, `joined_at`, `left_at`, `is_muted`, `is_video_on`, `is_hand_raised`, `is_screen_sharing` |
| `attendance_records` | `id`, `session_id` FK, `student_id` FK, `status` (`present`/`late`/`absent`/`excused`), `checked_in_at`, `left_at`, `minutes_logged`, `verification_method`, `note`; UNIQUE (`session_id`, `student_id`) |
| `attendance_appeals` | `id`, `record_id` FK, `reason`, `document_name`, `status`, `submitted_at`, `reviewed_by` FK, `reviewed_at` |

## Participation

| Table | Key columns |
| --- | --- |
| `questions` | `id`, `session_id` FK, `text`, `topic`, `correct_option_id` FK NULL, `duration_seconds` NULL, `status` (`draft`/`active`/`closed`), `counts_toward_grade`, `created_at`, `launched_at` |
| `question_options` | `id`, `question_id` FK, `label`, `text`, `position` |
| `question_responses` | `id`, `question_id` FK, `student_id` FK, `selected_option_id` FK, `submitted_at`, `is_correct`; UNIQUE (`question_id`, `student_id`) |
| `chat_messages` | `id`, `session_id` FK (`classroom_id` in JSON), `sender_id` FK, `message`, `is_question`, `is_pinned`, `created_at` |

## Communication & administration

| Table | Key columns |
| --- | --- |
| `notifications` | `id`, `user_id` FK, `type` (`class_reminder`/`new_course`/`attendance_update`/`live_question`/`announcement`), `title`, `body`, `reference_id`, `action_label`, `is_read`, `created_at` |
| `activity_logs` | `id`, `title`, `description`, `actor_id` FK NULL, `severity`, `category`, `created_at` (append-only) |
| `system_settings` | singleton row: `late_threshold_minutes`, `auto_join_leave_recording`, `participation_weight`, `strict_geofencing`, `session_timeout_minutes`, `enforce_sso`, `minimum_attendance`, `updated_at`, `updated_by` |
| `user_settings` | optional server copy of `AppSettingsModel` per user |
| `report_exports` | `id`, `report_type`, `scope_id`, `format`, `file_url`, `requested_by`, `created_at` |

## Suggested indexes

- `attendance_records (student_id, session_id)`, `(session_id, status)`
- `class_sessions (course_id, start_time)`, `(status)`
- `enrollments (student_id)`
- `notifications (user_id, is_read, created_at DESC)`
- `chat_messages (session_id, created_at)`
- `question_responses (question_id)`
