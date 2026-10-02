--
-- PostgreSQL database dump
--

\restrict t8HHloco7SWF8putuyfNVaet2n6PQC7HMBE2WyKcBbGCCaGyuBoqGBHnvqsSxsT

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.questions DROP CONSTRAINT IF EXISTS questions_session_id_fkey;
ALTER TABLE IF EXISTS ONLY public.question_responses DROP CONSTRAINT IF EXISTS question_responses_selected_option_id_fkey;
ALTER TABLE IF EXISTS ONLY public.question_responses DROP CONSTRAINT IF EXISTS question_responses_question_id_fkey;
ALTER TABLE IF EXISTS ONLY public.question_responses DROP CONSTRAINT IF EXISTS question_responses_profile_id_fkey;
ALTER TABLE IF EXISTS ONLY public.question_options DROP CONSTRAINT IF EXISTS question_options_question_id_fkey;
ALTER TABLE IF EXISTS ONLY public.profiles DROP CONSTRAINT IF EXISTS profiles_department_id_fkey;
ALTER TABLE IF EXISTS ONLY public.password_reset_codes DROP CONSTRAINT IF EXISTS password_reset_codes_profile_id_fkey;
ALTER TABLE IF EXISTS ONLY public.notifications DROP CONSTRAINT IF EXISTS notifications_profile_id_fkey;
ALTER TABLE IF EXISTS ONLY public.enrollments DROP CONSTRAINT IF EXISTS enrollments_profile_id_fkey;
ALTER TABLE IF EXISTS ONLY public.enrollments DROP CONSTRAINT IF EXISTS enrollments_course_id_fkey;
ALTER TABLE IF EXISTS ONLY public.departments DROP CONSTRAINT IF EXISTS departments_faculty_id_fkey;
ALTER TABLE IF EXISTS ONLY public.courses DROP CONSTRAINT IF EXISTS courses_lecturer_id_fkey;
ALTER TABLE IF EXISTS ONLY public.courses DROP CONSTRAINT IF EXISTS courses_department_id_fkey;
ALTER TABLE IF EXISTS ONLY public.class_sessions DROP CONSTRAINT IF EXISTS class_sessions_lecturer_id_fkey;
ALTER TABLE IF EXISTS ONLY public.class_sessions DROP CONSTRAINT IF EXISTS class_sessions_course_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_session_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_profile_id_fkey;
ALTER TABLE IF EXISTS ONLY public.attendance_records DROP CONSTRAINT IF EXISTS attendance_records_session_id_fkey;
ALTER TABLE IF EXISTS ONLY public.attendance_records DROP CONSTRAINT IF EXISTS attendance_records_profile_id_fkey;
ALTER TABLE IF EXISTS ONLY public.attendance_appeals DROP CONSTRAINT IF EXISTS attendance_appeals_session_id_fkey;
ALTER TABLE IF EXISTS ONLY public.attendance_appeals DROP CONSTRAINT IF EXISTS attendance_appeals_profile_id_fkey;
ALTER TABLE IF EXISTS ONLY public.system_settings DROP CONSTRAINT IF EXISTS system_settings_pkey;
ALTER TABLE IF EXISTS ONLY public.questions DROP CONSTRAINT IF EXISTS questions_pkey;
ALTER TABLE IF EXISTS ONLY public.question_responses DROP CONSTRAINT IF EXISTS question_responses_pkey;
ALTER TABLE IF EXISTS ONLY public.question_options DROP CONSTRAINT IF EXISTS question_options_pkey;
ALTER TABLE IF EXISTS ONLY public.profiles DROP CONSTRAINT IF EXISTS profiles_pkey;
ALTER TABLE IF EXISTS ONLY public.profiles DROP CONSTRAINT IF EXISTS profiles_matricule_number_key;
ALTER TABLE IF EXISTS ONLY public.profiles DROP CONSTRAINT IF EXISTS profiles_email_key;
ALTER TABLE IF EXISTS ONLY public.password_reset_codes DROP CONSTRAINT IF EXISTS password_reset_codes_pkey;
ALTER TABLE IF EXISTS ONLY public.enrollments DROP CONSTRAINT IF EXISTS one_enrollment_per_student;
ALTER TABLE IF EXISTS ONLY public.question_responses DROP CONSTRAINT IF EXISTS one_answer_per_student;
ALTER TABLE IF EXISTS ONLY public.notifications DROP CONSTRAINT IF EXISTS notifications_pkey;
ALTER TABLE IF EXISTS ONLY public.faculties DROP CONSTRAINT IF EXISTS faculties_pkey;
ALTER TABLE IF EXISTS ONLY public.faculties DROP CONSTRAINT IF EXISTS faculties_name_key;
ALTER TABLE IF EXISTS ONLY public.enrollments DROP CONSTRAINT IF EXISTS enrollments_pkey;
ALTER TABLE IF EXISTS ONLY public.departments DROP CONSTRAINT IF EXISTS departments_pkey;
ALTER TABLE IF EXISTS ONLY public.departments DROP CONSTRAINT IF EXISTS departments_name_key;
ALTER TABLE IF EXISTS ONLY public.courses DROP CONSTRAINT IF EXISTS courses_pkey;
ALTER TABLE IF EXISTS ONLY public.class_sessions DROP CONSTRAINT IF EXISTS class_sessions_pkey;
ALTER TABLE IF EXISTS ONLY public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_pkey;
ALTER TABLE IF EXISTS ONLY public.attendance_records DROP CONSTRAINT IF EXISTS attendance_records_pkey;
ALTER TABLE IF EXISTS ONLY public.attendance_appeals DROP CONSTRAINT IF EXISTS attendance_appeals_pkey;
ALTER TABLE IF EXISTS ONLY public.alembic_version DROP CONSTRAINT IF EXISTS alembic_version_pkc;
ALTER TABLE IF EXISTS ONLY public.activity_logs DROP CONSTRAINT IF EXISTS activity_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.academic_terms DROP CONSTRAINT IF EXISTS academic_terms_pkey;
ALTER TABLE IF EXISTS ONLY public.academic_terms DROP CONSTRAINT IF EXISTS academic_terms_code_key;
ALTER TABLE IF EXISTS public.system_settings ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.questions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.question_responses ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.question_options ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.profiles ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.password_reset_codes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.notifications ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.faculties ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.enrollments ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.departments ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.courses ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.class_sessions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.chat_messages ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.attendance_records ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.attendance_appeals ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.activity_logs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.academic_terms ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.system_settings_id_seq;
DROP TABLE IF EXISTS public.system_settings;
DROP SEQUENCE IF EXISTS public.questions_id_seq;
DROP TABLE IF EXISTS public.questions;
DROP SEQUENCE IF EXISTS public.question_responses_id_seq;
DROP TABLE IF EXISTS public.question_responses;
DROP SEQUENCE IF EXISTS public.question_options_id_seq;
DROP TABLE IF EXISTS public.question_options;
DROP SEQUENCE IF EXISTS public.profiles_id_seq;
DROP TABLE IF EXISTS public.profiles;
DROP SEQUENCE IF EXISTS public.password_reset_codes_id_seq;
DROP TABLE IF EXISTS public.password_reset_codes;
DROP SEQUENCE IF EXISTS public.notifications_id_seq;
DROP TABLE IF EXISTS public.notifications;
DROP SEQUENCE IF EXISTS public.faculties_id_seq;
DROP TABLE IF EXISTS public.faculties;
DROP SEQUENCE IF EXISTS public.enrollments_id_seq;
DROP TABLE IF EXISTS public.enrollments;
DROP SEQUENCE IF EXISTS public.departments_id_seq;
DROP TABLE IF EXISTS public.departments;
DROP SEQUENCE IF EXISTS public.courses_id_seq;
DROP TABLE IF EXISTS public.courses;
DROP SEQUENCE IF EXISTS public.class_sessions_id_seq;
DROP TABLE IF EXISTS public.class_sessions;
DROP SEQUENCE IF EXISTS public.chat_messages_id_seq;
DROP TABLE IF EXISTS public.chat_messages;
DROP SEQUENCE IF EXISTS public.attendance_records_id_seq;
DROP TABLE IF EXISTS public.attendance_records;
DROP SEQUENCE IF EXISTS public.attendance_appeals_id_seq;
DROP TABLE IF EXISTS public.attendance_appeals;
DROP TABLE IF EXISTS public.alembic_version;
DROP SEQUENCE IF EXISTS public.activity_logs_id_seq;
DROP TABLE IF EXISTS public.activity_logs;
DROP SEQUENCE IF EXISTS public.academic_terms_id_seq;
DROP TABLE IF EXISTS public.academic_terms;
DROP TYPE IF EXISTS public.role;
DROP TYPE IF EXISTS public.questiontype;
DROP TYPE IF EXISTS public.attendancestatus;
DROP TYPE IF EXISTS public.appealstatus;
--
-- Name: appealstatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.appealstatus AS ENUM (
    'pending',
    'approved',
    'rejected'
);


--
-- Name: attendancestatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.attendancestatus AS ENUM (
    'present',
    'partial',
    'absent',
    'excused'
);


--
-- Name: questiontype; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.questiontype AS ENUM (
    'mcq',
    'text'
);


--
-- Name: role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.role AS ENUM (
    'student',
    'lecturer',
    'admin'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: academic_terms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.academic_terms (
    id integer NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    academic_year character varying NOT NULL,
    start_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone NOT NULL,
    status character varying NOT NULL,
    term_type character varying NOT NULL,
    teaching_days integer,
    enrollment_open boolean NOT NULL,
    add_drop_deadline timestamp without time zone,
    notes text
);


--
-- Name: academic_terms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.academic_terms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: academic_terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.academic_terms_id_seq OWNED BY public.academic_terms.id;


--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_logs (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    actor_name character varying,
    severity character varying NOT NULL,
    category character varying,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_logs_id_seq OWNED BY public.activity_logs.id;


--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


--
-- Name: attendance_appeals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attendance_appeals (
    id integer NOT NULL,
    session_id integer NOT NULL,
    profile_id integer NOT NULL,
    reason text NOT NULL,
    document_name character varying,
    status public.appealstatus NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: attendance_appeals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attendance_appeals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attendance_appeals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attendance_appeals_id_seq OWNED BY public.attendance_appeals.id;


--
-- Name: attendance_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attendance_records (
    id integer NOT NULL,
    session_id integer NOT NULL,
    profile_id integer NOT NULL,
    role_at_time public.role NOT NULL,
    status public.attendancestatus NOT NULL,
    joined_at timestamp without time zone,
    left_at timestamp without time zone,
    duration_seconds integer
);


--
-- Name: attendance_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attendance_records_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attendance_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attendance_records_id_seq OWNED BY public.attendance_records.id;


--
-- Name: chat_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_messages (
    id integer NOT NULL,
    session_id integer NOT NULL,
    profile_id integer NOT NULL,
    message text NOT NULL,
    is_question boolean NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: chat_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_messages_id_seq OWNED BY public.chat_messages.id;


--
-- Name: class_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.class_sessions (
    id integer NOT NULL,
    course_id integer NOT NULL,
    lecturer_id integer NOT NULL,
    title character varying,
    scheduled_start timestamp without time zone,
    duration_minutes integer,
    started_at timestamp without time zone,
    ended_at timestamp without time zone
);


--
-- Name: class_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.class_sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: class_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.class_sessions_id_seq OWNED BY public.class_sessions.id;


--
-- Name: courses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.courses (
    id integer NOT NULL,
    code character varying NOT NULL,
    title character varying NOT NULL,
    department_id integer NOT NULL,
    lecturer_id integer,
    description text,
    credits integer,
    is_archived boolean DEFAULT false NOT NULL
);


--
-- Name: courses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.courses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.courses_id_seq OWNED BY public.courses.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    id integer NOT NULL,
    name character varying NOT NULL,
    faculty_id integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.departments_id_seq OWNED BY public.departments.id;


--
-- Name: enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enrollments (
    id integer NOT NULL,
    course_id integer NOT NULL,
    profile_id integer NOT NULL
);


--
-- Name: enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enrollments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enrollments_id_seq OWNED BY public.enrollments.id;


--
-- Name: faculties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faculties (
    id integer NOT NULL,
    name character varying NOT NULL
);


--
-- Name: faculties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faculties_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faculties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faculties_id_seq OWNED BY public.faculties.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    profile_id integer NOT NULL,
    title character varying NOT NULL,
    body text NOT NULL,
    type character varying NOT NULL,
    reference_id character varying,
    action_label character varying,
    is_read boolean NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: password_reset_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_codes (
    id integer NOT NULL,
    profile_id integer NOT NULL,
    code character varying NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    used boolean NOT NULL,
    attempts integer DEFAULT 0 NOT NULL
);


--
-- Name: password_reset_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.password_reset_codes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: password_reset_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.password_reset_codes_id_seq OWNED BY public.password_reset_codes.id;


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id integer NOT NULL,
    full_name character varying NOT NULL,
    email character varying NOT NULL,
    phone_number character varying,
    matricule_number character varying,
    hashed_password character varying NOT NULL,
    role public.role NOT NULL,
    department_id integer,
    is_active boolean DEFAULT true NOT NULL,
    pending_activation boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    last_login_at timestamp without time zone
);


--
-- Name: profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profiles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profiles_id_seq OWNED BY public.profiles.id;


--
-- Name: question_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_options (
    id integer NOT NULL,
    question_id integer NOT NULL,
    text character varying NOT NULL,
    is_correct boolean NOT NULL
);


--
-- Name: question_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.question_options_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.question_options_id_seq OWNED BY public.question_options.id;


--
-- Name: question_responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_responses (
    id integer NOT NULL,
    question_id integer NOT NULL,
    profile_id integer NOT NULL,
    selected_option_id integer,
    answer_text character varying,
    is_correct boolean,
    responded_at timestamp without time zone NOT NULL
);


--
-- Name: question_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.question_responses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.question_responses_id_seq OWNED BY public.question_responses.id;


--
-- Name: questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.questions (
    id integer NOT NULL,
    session_id integer NOT NULL,
    question_type public.questiontype NOT NULL,
    prompt text NOT NULL,
    correct_answer character varying,
    is_open boolean NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.questions_id_seq OWNED BY public.questions.id;


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_settings (
    id integer NOT NULL,
    late_threshold_minutes integer NOT NULL,
    auto_join_leave_recording boolean NOT NULL,
    participation_weight integer NOT NULL,
    strict_geofencing boolean NOT NULL,
    session_timeout_minutes integer NOT NULL,
    enforce_sso boolean NOT NULL,
    minimum_attendance double precision NOT NULL,
    updated_at timestamp without time zone
);


--
-- Name: system_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.system_settings_id_seq OWNED BY public.system_settings.id;


--
-- Name: academic_terms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_terms ALTER COLUMN id SET DEFAULT nextval('public.academic_terms_id_seq'::regclass);


--
-- Name: activity_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs ALTER COLUMN id SET DEFAULT nextval('public.activity_logs_id_seq'::regclass);


--
-- Name: attendance_appeals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_appeals ALTER COLUMN id SET DEFAULT nextval('public.attendance_appeals_id_seq'::regclass);


--
-- Name: attendance_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_records ALTER COLUMN id SET DEFAULT nextval('public.attendance_records_id_seq'::regclass);


--
-- Name: chat_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages ALTER COLUMN id SET DEFAULT nextval('public.chat_messages_id_seq'::regclass);


--
-- Name: class_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_sessions ALTER COLUMN id SET DEFAULT nextval('public.class_sessions_id_seq'::regclass);


--
-- Name: courses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses ALTER COLUMN id SET DEFAULT nextval('public.courses_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments ALTER COLUMN id SET DEFAULT nextval('public.departments_id_seq'::regclass);


--
-- Name: enrollments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments ALTER COLUMN id SET DEFAULT nextval('public.enrollments_id_seq'::regclass);


--
-- Name: faculties id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculties ALTER COLUMN id SET DEFAULT nextval('public.faculties_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: password_reset_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_codes ALTER COLUMN id SET DEFAULT nextval('public.password_reset_codes_id_seq'::regclass);


--
-- Name: profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles ALTER COLUMN id SET DEFAULT nextval('public.profiles_id_seq'::regclass);


--
-- Name: question_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_options ALTER COLUMN id SET DEFAULT nextval('public.question_options_id_seq'::regclass);


--
-- Name: question_responses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_responses ALTER COLUMN id SET DEFAULT nextval('public.question_responses_id_seq'::regclass);


--
-- Name: questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions ALTER COLUMN id SET DEFAULT nextval('public.questions_id_seq'::regclass);


--
-- Name: system_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings ALTER COLUMN id SET DEFAULT nextval('public.system_settings_id_seq'::regclass);


--
-- Data for Name: academic_terms; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.academic_terms (id, name, code, academic_year, start_date, end_date, status, term_type, teaching_days, enrollment_open, add_drop_deadline, notes) FROM stdin;
\.


--
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.activity_logs (id, title, description, actor_name, severity, category, created_at) FROM stdin;
1	User deactivated	Fufu University	The ICT University	warning	users	2026-10-01 02:34:39.3913
2	User deleted	Fufu University (fufuuniversity@gmail.com)	The ICT University	critical	users	2026-10-01 02:34:46.334874
3	User deleted	Mr John (john@gmail.com)	The ICT University	critical	users	2026-10-01 02:34:50.568754
4	User deleted	Mr Peter (peter@gmail.com)	The ICT University	critical	users	2026-10-01 02:34:55.282649
5	User deactivated	Mr Paul	The ICT University	warning	users	2026-10-01 02:34:59.666265
6	User deactivated	Mac bright	The ICT University	warning	users	2026-10-01 02:35:21.617555
7	User deleted	Mac bright (macbright@gmail.com)	The ICT University	critical	users	2026-10-01 02:35:26.267585
8	Lecturer assigned	Engr John → MTH-2111	The ICT University	success	courses	2026-10-01 03:26:03.623018
9	Student enrolled	Mary Ann → MTH-2111	Mary Ann	success	courses	2026-10-01 09:48:43.813364
10	Faculty created	Faculty of Engineering	The ICT University	success	system	2026-10-02 11:15:02.168808
11	Department updated	Mathematics	The ICT University	info	system	2026-10-02 11:40:26.932237
12	Department created	Software Engineering	The ICT University	success	system	2026-10-02 11:40:50.559671
13	Course created	SEN2635 — Introduction to Software Engineering	The ICT University	success	courses	2026-10-02 11:42:25.666032
14	Lecturer assigned	Engr John → SEN2635	The ICT University	success	courses	2026-10-02 11:43:32.406795
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.alembic_version (version_num) FROM stdin;
60e799be4113
\.


--
-- Data for Name: attendance_appeals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.attendance_appeals (id, session_id, profile_id, reason, document_name, status, created_at) FROM stdin;
\.


--
-- Data for Name: attendance_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.attendance_records (id, session_id, profile_id, role_at_time, status, joined_at, left_at, duration_seconds) FROM stdin;
1	1	4	lecturer	present	2026-09-29 11:31:50.696289	2026-09-29 11:57:56.636011	1565
2	2	7	lecturer	present	2026-10-01 10:00:23.200863	2026-10-01 10:07:04.920726	401
3	2	9	student	present	2026-10-01 10:00:38.387299	2026-10-01 10:06:03.436193	325
5	3	9	student	present	2026-10-01 21:00:33.522496	2026-10-01 21:05:14.842137	281
4	3	7	lecturer	present	2026-10-01 21:00:15.220654	2026-10-01 21:05:24.909144	309
6	4	7	lecturer	present	2026-10-02 07:42:52.487555	2026-10-02 07:46:39.386137	226
7	4	9	student	present	2026-10-02 07:43:04.324017	2026-10-02 07:46:39.391454	215
8	4	10	student	present	2026-10-02 07:43:59.293222	2026-10-02 07:46:39.397043	160
\.


--
-- Data for Name: chat_messages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.chat_messages (id, session_id, profile_id, message, is_question, created_at) FROM stdin;
1	2	9	sir we can't see ur screen	f	2026-10-01 10:02:36.394752
2	4	10	hello	f	2026-10-02 07:44:18.218723
3	4	10	hi	f	2026-10-02 07:45:03.32921
4	4	9	hello	f	2026-10-02 07:45:08.672849
\.


--
-- Data for Name: class_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.class_sessions (id, course_id, lecturer_id, title, scheduled_start, duration_minutes, started_at, ended_at) FROM stdin;
1	1	4	\N	\N	\N	2026-09-29 11:30:00.638765	2026-09-29 13:30:00.638765
2	1	7	INTERGRATION	2026-10-01 10:00:00	45	2026-10-01 10:00:16.870111	2026-10-01 10:07:04.909038
3	1	7	Equations	2026-10-01 21:00:00	90	2026-10-01 21:00:09.680381	2026-10-01 21:05:24.894712
4	1	7	Vertices	2026-10-02 07:40:00	90	2026-10-02 07:42:51.009377	2026-10-02 07:46:39.356368
\.


--
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.courses (id, code, title, department_id, lecturer_id, description, credits, is_archived) FROM stdin;
1	MTH-2111	Real Analysis	1	7	\N	\N	f
2	SEN2635	Introduction to Software Engineering	2	7	\N	6	f
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.departments (id, name, faculty_id, is_active) FROM stdin;
1	Mathematics	1	t
2	Software Engineering	1	t
\.


--
-- Data for Name: enrollments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.enrollments (id, course_id, profile_id) FROM stdin;
1	1	9
\.


--
-- Data for Name: faculties; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.faculties (id, name) FROM stdin;
1	Faculty of ICT
2	Faculty of Engineering
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notifications (id, profile_id, title, body, type, reference_id, action_label, is_read, created_at) FROM stdin;
1	7	New course assigned	You now teach MTH-2111 — Real Analysis.	new_course	1	\N	f	2026-10-01 03:26:03.642476
2	9	New class for MTH-2111	INTERGRATION is scheduled for 2026-10-01 10:00 UTC.	class_reminder	2	\N	t	2026-10-01 09:55:33.802734
3	9	MTH-2111 is live	INTERGRATION has started. Join now to be marked present.	class_reminder	2	Join Now	t	2026-10-01 10:00:16.871593
4	9	Live question in MTH-2111	whats is 1+1?	live_question	2	Answer	t	2026-10-01 10:04:21.772661
5	9	New class for MTH-2111	Equations is scheduled for 2026-10-01 21:00 UTC.	class_reminder	3	\N	f	2026-10-01 20:53:23.35034
6	9	MTH-2111 is live	Equations has started. Join now to be marked present.	class_reminder	3	Join Now	f	2026-10-01 21:00:09.682607
7	9	New class for MTH-2111	Vertices is scheduled for 2026-10-02 07:40 UTC.	class_reminder	4	\N	f	2026-10-02 07:35:55.698492
8	9	MTH-2111 is live	Vertices has started. Join now to be marked present.	class_reminder	4	Join Now	f	2026-10-02 07:42:51.027938
9	10	MTH-2111 is live	Vertices has started. Join now to be marked present.	class_reminder	4	Join Now	f	2026-10-02 07:42:51.028077
10	9	Live question in MTH-2111	what is 1 + 1	live_question	4	Answer	f	2026-10-02 07:45:37.903049
11	10	Live question in MTH-2111	what is 1 + 1	live_question	4	Answer	f	2026-10-02 07:45:37.903057
12	7	New course assigned	You now teach SEN2635 — Introduction to Software Engineering.	new_course	2	\N	f	2026-10-02 11:43:32.409693
\.


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.profiles (id, full_name, email, phone_number, matricule_number, hashed_password, role, department_id, is_active, pending_activation, created_at, last_login_at) FROM stdin;
4	Mr Paul	paul@gmail.com	\N	LECT20260001	$2b$12$g37Oytl6nP5Ea13snvSnWeOPRIS.hNgXK6AjleVqp1Np2oUKekhlC	lecturer	\N	f	f	\N	\N
8	Mac-bright	macbright@gmail.com	673873734	ICT0000	$2b$10$BwjCLwnf.vidtQWWi3BBt.hiHK4fcdlgDAZhWspMDuodrGQiufwbW	student	\N	t	f	2026-10-01 02:48:49.177158	2026-10-01 08:16:36.354739
10	MBAH	mbah@gmail.com	\N	ICTU00	$2b$10$dooJ8DWdDAI1Qij/HthwmeFc5Mi5IuKkEJEr9OXcQJRuSnOaQGmQu	student	1	t	f	2026-10-02 07:41:31.760698	2026-10-02 07:41:32.088775
6	The ICT University	ictuniversity@gmail.com	+237678992283	UNI12345	$2b$10$80DUVkigybTtVyTeODxF/eULgHwVkzHPNueotDHdBUAgN5yXj4C92	admin	\N	t	f	2026-10-01 02:33:53.84763	2026-10-02 11:13:28.459081
9	Mary Ann	mary@gmail.com	\N	STU0000	$2b$10$Bq4Mq/J9uUQ3NYJGOi5znehgi5Pd0ngyHaL8y1NC8uMinI51cM2yu	student	\N	t	f	2026-10-01 08:40:06.069749	2026-10-02 16:24:49.292256
7	Engr John	john@gmail.com	\N	LEC0000	$2b$10$xvArlTmSUkRxv1a.FLublO2nnpvaTgj9KysScQLtjbGO4BF6igEBy	lecturer	\N	t	f	2026-10-01 02:38:41.315988	2026-10-02 16:25:37.559599
\.


--
-- Data for Name: question_options; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.question_options (id, question_id, text, is_correct) FROM stdin;
1	1	2	t
2	1	89	f
3	1	748	f
4	1	0	f
5	2	2	t
6	2	88	f
7	2	325	f
8	2	000	f
\.


--
-- Data for Name: question_responses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.question_responses (id, question_id, profile_id, selected_option_id, answer_text, is_correct, responded_at) FROM stdin;
1	1	9	1	\N	t	2026-10-01 10:04:30.365439
2	2	10	6	\N	f	2026-10-02 07:45:48.430967
3	2	9	5	\N	t	2026-10-02 07:45:52.867473
\.


--
-- Data for Name: questions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.questions (id, session_id, question_type, prompt, correct_answer, is_open, created_at) FROM stdin;
1	2	mcq	whats is 1+1?	\N	f	2026-10-01 10:04:21.776157
2	4	mcq	what is 1 + 1	\N	f	2026-10-02 07:45:37.905938
\.


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.system_settings (id, late_threshold_minutes, auto_join_leave_recording, participation_weight, strict_geofencing, session_timeout_minutes, enforce_sso, minimum_attendance, updated_at) FROM stdin;
1	15	t	20	f	60	f	75	\N
\.


--
-- Name: academic_terms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.academic_terms_id_seq', 1, false);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.activity_logs_id_seq', 14, true);


--
-- Name: attendance_appeals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.attendance_appeals_id_seq', 1, false);


--
-- Name: attendance_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.attendance_records_id_seq', 8, true);


--
-- Name: chat_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.chat_messages_id_seq', 4, true);


--
-- Name: class_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.class_sessions_id_seq', 4, true);


--
-- Name: courses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.courses_id_seq', 2, true);


--
-- Name: departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.departments_id_seq', 2, true);


--
-- Name: enrollments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.enrollments_id_seq', 1, true);


--
-- Name: faculties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.faculties_id_seq', 2, true);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notifications_id_seq', 12, true);


--
-- Name: password_reset_codes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.password_reset_codes_id_seq', 1, true);


--
-- Name: profiles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.profiles_id_seq', 10, true);


--
-- Name: question_options_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.question_options_id_seq', 8, true);


--
-- Name: question_responses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.question_responses_id_seq', 3, true);


--
-- Name: questions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.questions_id_seq', 2, true);


--
-- Name: system_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.system_settings_id_seq', 1, true);


--
-- Name: academic_terms academic_terms_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_terms
    ADD CONSTRAINT academic_terms_code_key UNIQUE (code);


--
-- Name: academic_terms academic_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_terms
    ADD CONSTRAINT academic_terms_pkey PRIMARY KEY (id);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: attendance_appeals attendance_appeals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_appeals
    ADD CONSTRAINT attendance_appeals_pkey PRIMARY KEY (id);


--
-- Name: attendance_records attendance_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_pkey PRIMARY KEY (id);


--
-- Name: chat_messages chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (id);


--
-- Name: class_sessions class_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_sessions
    ADD CONSTRAINT class_sessions_pkey PRIMARY KEY (id);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: departments departments_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_name_key UNIQUE (name);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: enrollments enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_pkey PRIMARY KEY (id);


--
-- Name: faculties faculties_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculties
    ADD CONSTRAINT faculties_name_key UNIQUE (name);


--
-- Name: faculties faculties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculties
    ADD CONSTRAINT faculties_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: question_responses one_answer_per_student; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_responses
    ADD CONSTRAINT one_answer_per_student UNIQUE (question_id, profile_id);


--
-- Name: enrollments one_enrollment_per_student; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT one_enrollment_per_student UNIQUE (course_id, profile_id);


--
-- Name: password_reset_codes password_reset_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_codes
    ADD CONSTRAINT password_reset_codes_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_email_key UNIQUE (email);


--
-- Name: profiles profiles_matricule_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_matricule_number_key UNIQUE (matricule_number);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: question_options question_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_options
    ADD CONSTRAINT question_options_pkey PRIMARY KEY (id);


--
-- Name: question_responses question_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_responses
    ADD CONSTRAINT question_responses_pkey PRIMARY KEY (id);


--
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (id);


--
-- Name: attendance_appeals attendance_appeals_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_appeals
    ADD CONSTRAINT attendance_appeals_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: attendance_appeals attendance_appeals_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_appeals
    ADD CONSTRAINT attendance_appeals_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.class_sessions(id);


--
-- Name: attendance_records attendance_records_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: attendance_records attendance_records_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_records
    ADD CONSTRAINT attendance_records_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.class_sessions(id);


--
-- Name: chat_messages chat_messages_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: chat_messages chat_messages_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.class_sessions(id);


--
-- Name: class_sessions class_sessions_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_sessions
    ADD CONSTRAINT class_sessions_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: class_sessions class_sessions_lecturer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_sessions
    ADD CONSTRAINT class_sessions_lecturer_id_fkey FOREIGN KEY (lecturer_id) REFERENCES public.profiles(id);


--
-- Name: courses courses_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: courses courses_lecturer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_lecturer_id_fkey FOREIGN KEY (lecturer_id) REFERENCES public.profiles(id);


--
-- Name: departments departments_faculty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_faculty_id_fkey FOREIGN KEY (faculty_id) REFERENCES public.faculties(id);


--
-- Name: enrollments enrollments_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: enrollments enrollments_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: notifications notifications_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: password_reset_codes password_reset_codes_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_codes
    ADD CONSTRAINT password_reset_codes_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: profiles profiles_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: question_options question_options_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_options
    ADD CONSTRAINT question_options_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: question_responses question_responses_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_responses
    ADD CONSTRAINT question_responses_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: question_responses question_responses_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_responses
    ADD CONSTRAINT question_responses_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: question_responses question_responses_selected_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_responses
    ADD CONSTRAINT question_responses_selected_option_id_fkey FOREIGN KEY (selected_option_id) REFERENCES public.question_options(id);


--
-- Name: questions questions_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.class_sessions(id);


--
-- PostgreSQL database dump complete
--

\unrestrict t8HHloco7SWF8putuyfNVaet2n6PQC7HMBE2WyKcBbGCCaGyuBoqGBHnvqsSxsT

