# Screens

Every screen maps to an approved Google Stitch design (`screen_XX_*`). The
design package has **no screen 37**. Routes are declared in
`lib/core/routing/route_names.dart`; role routes are guarded by
`AppRouter`. Tab screens live inside the role bottom-navigation shells in
`lib/widgets/navigation/`.

## Onboarding & authentication (public)

| # | Screen | Route | File | Purpose |
| --- | --- | --- | --- | --- |
| 01 | Splash | `/` | `features/onboarding/presentation/splash_screen.dart` | Brand splash; restores the session and routes to the role home, login or onboarding. |
| 02 | Welcome | `/onboarding` | `welcome_screen.dart` | Introduces Smart Class (HD video, auto-log, realtime Q&A). |
| 03 | Attendance introduction | `/onboarding/attendance` | `attendance_intro_screen.dart` | Explains automatic join/leave/duration tracking. |
| 04 | Participation introduction | `/onboarding/participation` | `participation_intro_screen.dart` | Explains live polls and engagement tracking; completes onboarding. |
| 05 | Role selection | `/role-selection` | `role_selection_screen.dart` | Choose Student, Lecturer or Admin portal. |
| 06 | Login | `/login` | `features/authentication/presentation/login_screen.dart` | Student/lecturer sign-in with role toggle, remember me, forgot password, SSO/biometric placeholders and first-time setup links. |
| 07 | Student account activation | `/activate-student` | `student_activation_screen.dart` | Matricule + institutional email + password with strength meter and integrity acknowledgement. |
| 08 | Lecturer registration | `/register-lecturer` | `lecturer_registration_screen.dart` | Staff ID + institutional email + password setup. |
| 09 | Admin login | `/admin-login` | `admin_login_screen.dart` | Institutional administration gateway with compliance notice. |
| 10 | Forgot password | `/forgot-password` | `forgot_password_screen.dart` | Email → 4-digit code (resend countdown) → new password → success. |

## Student (`/student/**`, role: student)

Bottom navigation: **Home · Schedule · Attendance · Profile**.

| # | Screen | Route / tab | File | Purpose |
| --- | --- | --- | --- | --- |
| 11 | Student home | `/student` (tab 0) | `features/student/home/student_home_screen.dart` | Live/upcoming class card with *Join Live Session*, attendance/credits/pass stats, enrolled courses, notifications badge. |
| 12 | My courses | `/student/courses` | `features/student/courses/student_courses_screen.dart` | Enrolled courses with search, filters, attendance, credits and sessions held. |
| 13 | Course details | `/student/course-details` (arg: course id) | `course_details_screen.dart` | Overview, sessions and attendance tabs; live banner; schedule & venue. |
| 14 | Student schedule | `/student` (tab 1) | `features/student/schedule/student_schedule_screen.dart` | Week day selector and the day's classes; join live sessions. |
| 15 | Student live classroom | `/student/classroom` (arg: session id) | `features/student/classroom/student_live_classroom_screen.dart` | Lecturer stage, participants, attendance-logged banner, mic/camera/hand/chat/leave controls, live question prompt, connection state. |
| 16 | Classroom chat | `/student/classroom/chat`, `/lecturer/classroom/chat` | `classroom_chat_screen.dart` | Real-time class chat (shared by students and lecturers) with delivery status and retry. |
| 17 | Live question | `/student/classroom/question` | `live_question_screen.dart` | Answer the active multiple-choice question before the timer ends; synced/correctness state. |
| 18 | Student attendance | `/student` (tab 2) | `features/student/attendance/student_attendance_screen.dart` | Aggregate %, standing, present/late/absent counts, participation, filterable log, absence appeal sheet. |
| 19 | Notifications | `/notifications` (any signed-in role) | `features/student/notifications/student_notifications_screen.dart` | Class reminders, new courses, attendance updates, live questions, announcements; mark read. |
| 20 | Student profile | `/student` (tab 3) | `features/student/profile/student_profile_screen.dart` | Digital ID, academic and contact info, edit profile, links to courses/settings, logout. |
| 21 | Student settings | `/student/settings` | `features/student/settings/student_settings_screen.dart` | Notification toggles, classroom defaults (mic/camera), theme, change password, biometric lock, sign out. |

## Lecturer (`/lecturer/**`, role: lecturer)

Bottom navigation: **Dashboard · Courses · Attendance · Reports**.

| # | Screen | Route / tab | File | Purpose |
| --- | --- | --- | --- | --- |
| 22 | Lecturer dashboard | `/lecturer` (tab 0) | `features/lecturer/dashboard/lecturer_dashboard_screen.dart` | Quick actions, teaching stats, live/upcoming class with Start/Open class, recent sessions with attendance, create class. |
| 23 | Lecturer courses | `/lecturer` (tab 1) | `features/lecturer/courses/lecturer_courses_screen.dart` | Assigned courses with enrolment and attendance; open roster or schedule a class. |
| 24 | Course details / roster | `/lecturer/course-roster` (arg: course id) | `course_roster_screen.dart` | Course stats, searchable/filterable roster (present, absent, at risk), per-student actions, CSV export. |
| 25 | Schedule class | `/lecturer/schedule-class` (arg: optional course id) | `features/lecturer/schedule/schedule_class_screen.dart` | Course, topic, date, start time, duration, late threshold, questions toggle, room; success panel with room code. |
| 26 | Lecturer live classroom | `/lecturer/classroom` (arg: session id) | `features/lecturer/classroom/lecturer_live_classroom_screen.dart` | Run the class: media controls, participants and raised hands, question results, links to chat/whiteboard/questions/attendance, end class. |
| 27 | Screen share / whiteboard | `/lecturer/classroom/whiteboard` | `whiteboard_screen.dart` | Drawing canvas (colors, width, undo, clear) and screen-share toggle. |
| 28 | Create live question | `/lecturer/classroom/question` | `features/lecturer/questions/create_question_screen.dart` | Prompt, 2–6 options, correct answer, timer; launch, live distribution, end early, broadcast results. |
| 29 | Live attendance | `/lecturer/live-attendance` (arg: optional session id), tab 2 | `features/lecturer/attendance/live_attendance_screen.dart` | Real-time cohort/present/late/absent, filters, search, manual adjustments, lock session, export. |
| 30 | Attendance reports | `/lecturer/reports` (arg: optional course id), tab 3 | `features/lecturer/reports/attendance_reports_screen.dart` | Course filter, KPIs, weekly trend chart, per-course breakdown, export. |
| 31 | Lecturer profile | `/lecturer/profile` | `features/lecturer/profile/lecturer_profile_screen.dart` | Faculty info, stats, assigned courses, preferences, edit, logout. |

## Admin (`/admin/**`, role: admin)

Bottom navigation: **Dashboard · Users · Courses · Settings**, plus a drawer
(Departments & Faculties, Academic Terms, Reports, Profile, Logout).

| # | Screen | Route / tab | File | Purpose |
| --- | --- | --- | --- | --- |
| 32 | Admin dashboard | `/admin` (tab 0) | `features/admin/dashboard/admin_dashboard_screen.dart` | Campus overview KPIs, administrative quick actions, recent activity. |
| 33 | User management | `/admin` (tab 1) | `features/admin/users/user_management_screen.dart` | Search, role filters, active-only, account actions, add user. |
| – | User details | `/admin/user-details` (arg: optional user id) | `user_details_screen.dart` | Create or edit an account; activate/deactivate/delete (uses the 33/40 visual language). |
| 34 | Departments & faculties | `/admin/departments` | `features/admin/departments/departments_screen.dart` | Campus structure stats, category filters, department cards and options, create department. |
| – | Faculties | `/admin/faculties` | `faculties_screen.dart` | Faculty list reachable from screen 34 (same visual language). |
| 35 | Academic terms | `/admin/academic-terms` | `features/admin/academic_terms/academic_terms_screen.dart` | Current term progress, snapshot, archived and planned terms, new term form. |
| 36 | Course management | `/admin` (tab 2) | `features/admin/courses/course_management_screen.dart` | Status tabs, search, course cards, assign lecturer, archive, new course. |
| – | Admin course details | `/admin/course-details` (arg: course id) | `admin_course_details_screen.dart` | Course info, lecturer assignment, sessions and attendance summary. |
| 38 | Reports & analytics | `/admin/reports` | `features/admin/reports/admin_reports_screen.dart` | Institutional KPIs, trend vs previous term, attendance by faculty and course, export (PDF/XLSX/CSV). |
| 39 | System settings | `/admin` (tab 3) | `features/admin/settings/admin_settings_screen.dart` | Academic configuration links, attendance policies (late threshold, auto join/leave, participation weight, geofencing), security and integrations. |
| 40 | Admin profile | `/admin/profile` | `features/admin/profile/admin_profile_screen.dart` | Identity, credentials, security enforcement, preferences, logout. |

## Shared states

Every data screen renders loading, empty and error (with retry) states via
`AsyncView`; forms validate through `Validators`; an *Access denied* page is
shown when a signed-in user opens another role's route.
