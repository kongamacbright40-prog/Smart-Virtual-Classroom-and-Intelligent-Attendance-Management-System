import 'dart:async';
import 'dart:math';

import 'package:smart_class/models/models.dart';

/// Demo accounts accepted by the mock authentication repository.
abstract final class DemoAccounts {
  static const String password = 'Password123!';

  static const String studentId = 'ICT20251181';
  static const String studentEmail = 'konga.macbright@student.univ.edu';
  static const String lecturerId = 'FAC-2024-8192';
  static const String lecturerEmail = 'k.mensah@smartclass.edu.ac';
  static const String adminId = 'ADM-001';
  static const String adminEmail = 'admin.root@smartclass.edu';
}

/// In-memory, internally consistent data set shared by every mock
/// repository so that actions in one role (e.g. a lecturer launching a
/// question) are visible to the others on the same device.
///
/// All dates are generated relative to [now] so that "live now" and
/// "upcoming" states always make sense when the app is opened.
class MockDataStore {
  MockDataStore({DateTime? now}) : now = now ?? DateTime.now() {
    _seed();
  }

  final DateTime now;
  final Random _random = Random(42);

  // Identity
  final Map<String, UserModel> users = {};
  final Map<String, StudentModel> students = {};
  final Map<String, LecturerModel> lecturers = {};
  final Map<String, AdminModel> admins = {};
  final Map<String, String> passwords = {};

  // Academic structure
  final Map<String, FacultyModel> faculties = {};
  final Map<String, DepartmentModel> departments = {};
  final Map<String, AcademicTermModel> terms = {};
  final Map<String, CourseModel> courses = {};

  /// courseId -> studentIds
  final Map<String, List<String>> enrollments = {};

  // Sessions & activity
  final Map<String, ClassSessionModel> sessions = {};
  final Map<String, ScheduleModel> schedules = {};
  final Map<String, AttendanceRecordModel> attendance = {};
  final Map<String, List<ParticipantModel>> participants = {};
  final Map<String, List<ChatMessageModel>> messages = {};
  final Map<String, QuestionModel> questions = {};
  final Map<String, QuestionResponseModel> responses = {};
  final Map<String, NotificationModel> notifications = {};
  final List<ActivityLogModel> activity = [];
  SystemSettingsModel systemSettings = const SystemSettingsModel();

  // Realtime channels (mock replacement for WebSocket events)
  final Map<String, StreamController<List<ParticipantModel>>>
  participantStreams = {};
  final Map<String, StreamController<ChatMessageModel>> chatStreams = {};
  final Map<String, StreamController<QuestionModel?>> questionStreams = {};
  final Map<String, StreamController<List<AttendanceRecordModel>>>
  attendanceStreams = {};
  final Map<String, StreamController<NotificationModel>> notificationStreams =
      {};

  int _idCounter = 1000;
  String nextId(String prefix) => '$prefix-${_idCounter++}';

  static const String currentStudentId = 'stu-001';
  static const String currentLecturerId = 'lec-001';
  static const String currentAdminId = 'adm-001';
  static const String liveSessionId = 'ses-cs301-live';
  static const String activeTermId = 'term-fa26';

  StreamController<T> _controller<T>(
    Map<String, StreamController<T>> map,
    String key,
  ) => map.putIfAbsent(key, StreamController<T>.broadcast);

  StreamController<List<ParticipantModel>> participantChannel(String id) =>
      _controller(participantStreams, id);
  StreamController<ChatMessageModel> chatChannel(String id) =>
      _controller(chatStreams, id);
  StreamController<QuestionModel?> questionChannel(String id) =>
      _controller(questionStreams, id);
  StreamController<List<AttendanceRecordModel>> attendanceChannel(String id) =>
      _controller(attendanceStreams, id);
  StreamController<NotificationModel> notificationChannel(String id) =>
      _controller(notificationStreams, id);

  List<AttendanceRecordModel> sessionAttendance(String sessionId) =>
      attendance.values.where((r) => r.sessionId == sessionId).toList()
        ..sort((a, b) => a.studentName.compareTo(b.studentName));

  Future<void> dispose() async {
    for (final c in [
      ...participantStreams.values,
      ...chatStreams.values,
      ...questionStreams.values,
      ...attendanceStreams.values,
      ...notificationStreams.values,
    ]) {
      await c.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Seed data
  // ---------------------------------------------------------------------------

  void _seed() {
    _seedStructure();
    _seedStaff();
    _seedCourses();
    _seedStudents();
    _seedSessions();
    _seedAttendance();
    _seedClassroom();
    _seedNotifications();
    _seedActivity();
  }

  void _seedStructure() {
    const facultyData = [
      (
        'fac-fcs',
        'Faculty of Computer Science',
        'FCS-ENG',
        'Prof. Kwame Mensah, Ph.D.',
        'Science & Tech',
        5,
        12,
        320,
        18,
      ),
      (
        'fac-ece',
        'Faculty of Electrical & Computer Eng.',
        'ECE-ENG',
        'Dr. Mamadou Kaba, Ph.D.',
        'Engineering',
        4,
        10,
        285,
        14,
      ),
      (
        'fac-mas',
        'Faculty of Mathematics & Statistics',
        'MAS-SCI',
        'Prof. Elena Rostova',
        'Science & Tech',
        3,
        8,
        410,
        11,
      ),
      (
        'fac-bae',
        'Faculty of Business Administration',
        'BAE-MGMT',
        'Dr. Sarah Boateng',
        'Business',
        4,
        14,
        520,
        22,
      ),
      (
        'fac-hum',
        'Faculty of Arts & Humanities',
        'ART-HUM',
        'Prof. M. Adebayo',
        'Humanities',
        4,
        9,
        360,
        12,
      ),
      (
        'fac-nsc',
        'Faculty of Natural Sciences',
        'NAT-SCI',
        'Dr. Isaac Asante',
        'Science & Tech',
        4,
        11,
        395,
        15,
      ),
    ];
    for (final f in facultyData) {
      faculties[f.$1] = FacultyModel(
        id: f.$1,
        name: f.$2,
        code: f.$3,
        deanName: f.$4,
        category: f.$5,
        departmentCount: f.$6,
        courseCount: f.$7,
        studentCount: f.$8,
        staffCount: f.$9,
      );
    }

    const deptData = [
      (
        'dep-cs',
        'Dept. of Computer Science & Engineering',
        'CSE',
        'fac-fcs',
        'Software, Algorithms & Intelligent Systems',
        'Prof. Kwame Mensah, Ph.D.',
        12,
        320,
        18,
        4,
        92.4,
      ),
      (
        'dep-ce',
        'Dept. of Robotics, Circuits & Systems',
        'RCS',
        'fac-ece',
        'Embedded, Robotics & Computer Engineering',
        'Dr. Mamadou Kaba, Ph.D.',
        10,
        285,
        14,
        2,
        94.1,
      ),
      (
        'dep-math',
        'Dept. of Mathematics & Statistics',
        'MAS',
        'fac-mas',
        'Applied Modeling & Data Sciences',
        'Prof. Elena Rostova',
        8,
        410,
        11,
        1,
        88.7,
      ),
      (
        'dep-bus',
        'Dept. of Management & Finance',
        'MGF',
        'fac-bae',
        'Management, Finance & Applied Econ',
        'Dr. Sarah Boateng',
        14,
        520,
        22,
        3,
        90.2,
      ),
      (
        'dep-eng',
        'Dept. of English & Communications',
        'ENC',
        'fac-hum',
        'Academic Writing & Media',
        'Prof. M. Adebayo',
        9,
        360,
        12,
        1,
        91.0,
      ),
      (
        'dep-bio',
        'Dept. of Biological Sciences',
        'BIO',
        'fac-nsc',
        'Biotech, Genetics & Ecology',
        'Dr. Isaac Asante',
        11,
        395,
        15,
        0,
        81.5,
      ),
    ];
    for (final d in deptData) {
      departments[d.$1] = DepartmentModel(
        id: d.$1,
        name: d.$2,
        code: d.$3,
        facultyId: d.$4,
        facultyName: faculties[d.$4]!.name,
        description: d.$5,
        headName: d.$6,
        courseCount: d.$7,
        studentCount: d.$8,
        staffCount: d.$9,
        liveSessions: d.$10,
        averageAttendance: d.$11,
      );
    }

    final year = now.year;
    terms['term-fa26'] = AcademicTermModel(
      id: 'term-fa26',
      name: 'Fall Semester $year',
      code: 'FA${year % 100}-REGULAR',
      academicYear: '$year/${year + 1}',
      startDate: now.subtract(const Duration(days: 38)),
      endDate: now.add(const Duration(days: 74)),
      status: TermStatus.active,
      teachingDays: 78,
      enrollmentOpen: true,
      addDropDeadline: now.add(const Duration(days: 3)),
      enrolledStudents: 1420,
      courseCount: 48,
      averageAttendance: 89.4,
    );
    terms['term-sp26'] = AcademicTermModel(
      id: 'term-sp26',
      name: 'Spring Semester $year',
      code: 'SP${year % 100}-REGULAR',
      academicYear: '${year - 1}/$year',
      startDate: DateTime(year, 1, 12),
      endDate: DateTime(year, 5, 22),
      status: TermStatus.archived,
      enrolledStudents: 1390,
      courseCount: 46,
      averageAttendance: 91.4,
    );
    terms['term-fa25'] = AcademicTermModel(
      id: 'term-fa25',
      name: 'Fall Semester ${year - 1}',
      code: 'FA${(year - 1) % 100}-REGULAR',
      academicYear: '${year - 1}/$year',
      startDate: DateTime(year - 1, 9, 3),
      endDate: DateTime(year - 1, 12, 19),
      status: TermStatus.archived,
      enrolledStudents: 1310,
      courseCount: 44,
      averageAttendance: 89.8,
    );
    terms['term-su25'] = AcademicTermModel(
      id: 'term-su25',
      name: 'Summer Term ${year - 1}',
      code: 'SU${(year - 1) % 100}-INTENSIVE',
      academicYear: '${year - 2}/${year - 1}',
      startDate: DateTime(year - 1, 6, 9),
      endDate: DateTime(year - 1, 7, 25),
      status: TermStatus.archived,
      termType: 'Intensive',
      enrolledStudents: 420,
      courseCount: 12,
      averageAttendance: 94.2,
    );
    terms['term-sp27'] = AcademicTermModel(
      id: 'term-sp27',
      name: 'Spring Semester ${year + 1}',
      code: 'SP${(year + 1) % 100}-REGULAR',
      academicYear: '$year/${year + 1}',
      startDate: DateTime(year + 1, 1, 11),
      endDate: DateTime(year + 1, 5, 21),
      status: TermStatus.planned,
      notes:
          'Curriculum draft under administrative review. Enrollment registration scheduled for Nov 15, $year.',
    );
  }

  void _addUser(UserModel user, {String password = DemoAccounts.password}) {
    users[user.id] = user;
    passwords[user.id] = password;
  }

  void _seedStaff() {
    const lecturerData = [
      (
        'lec-001',
        'Prof. Kwame Mensah',
        DemoAccounts.lecturerEmail,
        'FAC-2024-8192',
        'Prof.',
        'dep-cs',
        'Algorithms & Distributed Systems',
        'Faculty of CS, Block A, Room 204',
      ),
      (
        'lec-002',
        'Dr. Mamadou Kaba',
        'm.kaba@smartclass.edu.ac',
        'FAC-2018-042',
        'Dr.',
        'dep-ce',
        'Distributed Systems & Embedded IoT',
        'Faculty of Eng., Block C, Room 314',
      ),
      (
        'lec-003',
        'Dr. S. Thorne',
        's.thorne@smartclass.edu.ac',
        'FAC-2019-117',
        'Dr.',
        'dep-cs',
        'Database Systems',
        'Faculty of CS, Lab 4B',
      ),
      (
        'lec-004',
        'Dr. E. Vance',
        'e.vance@smartclass.edu.ac',
        'FAC-2016-221',
        'Dr.',
        'dep-math',
        'Real & Functional Analysis',
        'Maths Block, Room 12',
      ),
      (
        'lec-005',
        'Prof. M. Adebayo',
        'm.adebayo@smartclass.edu.ac',
        'FAC-2012-009',
        'Prof.',
        'dep-eng',
        'Technical Communication',
        'Humanities Wing, Seminar Rm 1',
      ),
    ];
    for (final l in lecturerData) {
      final user = UserModel(
        id: l.$1,
        fullName: l.$2,
        email: l.$3,
        role: UserRole.lecturer,
        phone: '+233 302 765 ${400 + lecturerData.indexOf(l)}',
        departmentId: l.$6,
        departmentName: departments[l.$6]!.name,
        createdAt: now.subtract(const Duration(days: 900)),
        lastActiveAt: now.subtract(const Duration(minutes: 12)),
      );
      _addUser(user);
      lecturers[l.$1] = LecturerModel(
        user: user,
        staffId: l.$4,
        title: l.$5,
        specialization: l.$7,
        officeLocation: l.$8,
        officeHours: 'Tue & Thu • 2:00 — 4:00 PM',
        rating: 4.8,
      );
    }

    final admin = UserModel(
      id: currentAdminId,
      fullName: 'System Administrator',
      email: DemoAccounts.adminEmail,
      role: UserRole.admin,
      phone: '+233 302 700 100',
      createdAt: now.subtract(const Duration(days: 1200)),
      lastActiveAt: now,
    );
    _addUser(admin);
    admins[admin.id] = AdminModel(
      user: admin,
      adminId: DemoAccounts.adminId,
      accessLevel: AdminAccessLevel.system,
      jobTitle: 'Super Admin • Root Tier 1',
      permissions: const [
        'users',
        'courses',
        'departments',
        'terms',
        'reports',
        'settings',
      ],
      lastLoginAt: DateTime(now.year, now.month, now.day, 9, 15),
    );
    final admin2 = UserModel(
      id: 'adm-002',
      fullName: 'Sarah Jenkins',
      email: 's.jenkins@smartclass.edu.ac',
      role: UserRole.admin,
      createdAt: now.subtract(const Duration(days: 400)),
    );
    _addUser(admin2);
    admins[admin2.id] = AdminModel(
      user: admin2,
      adminId: 'ADM-014',
      accessLevel: AdminAccessLevel.faculty,
      jobTitle: 'Systems Registrar',
    );
  }

  void _seedCourses() {
    final c = [
      CourseModel(
        id: 'crs-cs301',
        code: 'CS-301',
        title: 'Data Structures & Algorithms',
        description: 'Comprehensive study of fundamental data structures, abstract data types, dynamic memory allocation, complexity analysis, trees, graphs, and hash tables with hands-on algorithm implementation.',
        category: 'Core Major',
        credits: 4,
        creditNote: 'Theory + Lab',
        lecturerId: 'lec-001',
        lecturerName: 'Prof. Kwame Mensah',
        lecturerRole: 'Dept. Head',
        departmentId: 'dep-cs',
        departmentName: 'Computer Science',
        facultyName: 'Faculty of Computer Science',
        termId: activeTermId,
        enrolledCount: 42,
        capacity: 60,
        totalSessions: 24,
        sessionsHeld: 12,
        scheduleSummary: 'Mon & Wed • 10:00 — 11:30 AM',
        room: 'Hall B (Main)',
        virtualRoomUrl: 'smartclass.edu/cs301-live',
        topics: ['C++', 'Big-O Notation', 'Binary Trees', 'Hash Maps'],
      ),
      CourseModel(
        id: 'crs-mth1221',
        code: 'MTH-1221',
        title: 'Real Analysis',
        description: 'Rigorous treatment of sequences, limits, continuity, differentiation and Riemann integration on the real line.',
        category: 'Faculty Elective',
        credits: 4,
        creditNote: 'Pure Math',
        lecturerId: 'lec-004',
        lecturerName: 'Dr. E. Vance',
        lecturerRole: 'Faculty Mentor',
        departmentId: 'dep-math',
        departmentName: 'Mathematics',
        facultyName: 'Faculty of Mathematics & Statistics',
        termId: activeTermId,
        enrolledCount: 56,
        totalSessions: 16,
        sessionsHeld: 14,
        scheduleSummary: 'Tue & Thu • 08:30 — 09:45 AM',
        room: 'Hall C • Room 102',
        topics: ['Sequences', 'Limits', 'Continuity', 'Integration'],
      ),
      CourseModel(
        id: 'crs-cs305',
        code: 'CS-305',
        title: 'Database Systems',
        description: 'Relational modelling, SQL, normalization, transactions, indexing and query optimisation with applied PostgreSQL labs.',
        category: 'Core Major',
        credits: 3,
        creditNote: 'Applied SQL',
        lecturerId: 'lec-003',
        lecturerName: 'Dr. S. Thorne',
        lecturerRole: 'Lab Lead',
        departmentId: 'dep-cs',
        departmentName: 'Computer Science',
        facultyName: 'Faculty of Computer Science',
        termId: activeTermId,
        enrolledCount: 50,
        totalSessions: 14,
        sessionsHeld: 10,
        scheduleSummary: 'Thu • 11:30 AM — 1:00 PM',
        room: 'Lab 4B',
        topics: ['SQL', 'Normalization', 'Transactions', 'Indexing'],
      ),
      CourseModel(
        id: 'crs-eng210',
        code: 'ENG-210',
        title: 'Academic Technical Writing',
        description: 'Writing clear technical reports, research papers and documentation for scientific audiences.',
        category: 'Faculty Elective',
        credits: 2,
        creditNote: 'Seminar',
        lecturerId: 'lec-005',
        lecturerName: 'Prof. M. Adebayo',
        lecturerRole: 'Communications',
        departmentId: 'dep-eng',
        departmentName: 'English & Communications',
        facultyName: 'Faculty of Arts & Humanities',
        termId: activeTermId,
        enrolledCount: 30,
        totalSessions: 12,
        sessionsHeld: 11,
        scheduleSummary: 'Fri • 9:00 — 10:15 AM',
        room: 'Seminar Rm 1',
        topics: ['Reports', 'Citations', 'Peer Review'],
      ),
      CourseModel(
        id: 'crs-swe201',
        code: 'SWE-201',
        title: 'Software Engineering Principles',
        description: 'Software process models, requirements, design patterns, testing and agile project delivery.',
        category: 'Core Major',
        credits: 3,
        lecturerId: 'lec-001',
        lecturerName: 'Prof. Kwame Mensah',
        departmentId: 'dep-cs',
        departmentName: 'Computer Science',
        facultyName: 'Faculty of Computer Science',
        termId: activeTermId,
        enrolledCount: 52,
        totalSessions: 16,
        sessionsHeld: 11,
        scheduleSummary: 'Tue & Thu • 2:00 — 3:30 PM',
        room: 'Lab Hall B',
        topics: ['Agile', 'UML', 'Testing'],
      ),
      CourseModel(
        id: 'crs-cs220',
        code: 'CS-220',
        title: 'Object-Oriented Programming',
        description: 'Classes, inheritance, polymorphism, interfaces and SOLID design using Java and Dart.',
        category: 'Core Major',
        credits: 3,
        lecturerId: 'lec-001',
        lecturerName: 'Prof. Kwame Mensah',
        departmentId: 'dep-cs',
        departmentName: 'Computer Science',
        facultyName: 'Faculty of Computer Science',
        termId: activeTermId,
        enrolledCount: 48,
        totalSessions: 16,
        sessionsHeld: 10,
        scheduleSummary: 'Mon • 1:00 — 2:30 PM',
        room: 'Room 304',
        topics: ['OOP', 'SOLID', 'Design Patterns'],
      ),
      CourseModel(
        id: 'crs-cs450',
        code: 'CS-450',
        title: 'Distributed Systems',
        description: 'Consensus, replication, fault tolerance and real-time communication in distributed architectures.',
        category: 'Elective',
        credits: 3,
        lecturerId: 'lec-001',
        lecturerName: 'Prof. Kwame Mensah',
        departmentId: 'dep-cs',
        departmentName: 'Computer Science',
        facultyName: 'Faculty of Computer Science',
        termId: activeTermId,
        enrolledCount: 36,
        totalSessions: 14,
        sessionsHeld: 9,
        scheduleSummary: 'Fri • 11:00 AM — 12:30 PM',
        room: 'Room 408B',
        topics: ['Consensus', 'Replication', 'WebRTC'],
      ),
      CourseModel(
        id: 'crs-ce330',
        code: 'CE-330',
        title: 'Computer Architecture',
        category: 'Core Major',
        credits: 3,
        lecturerId: 'lec-002',
        lecturerName: 'Dr. Mamadou Kaba',
        departmentId: 'dep-ce',
        departmentName: 'Computer Engineering',
        facultyName: 'Faculty of Electrical & Computer Eng.',
        termId: activeTermId,
        enrolledCount: 38,
        totalSessions: 16,
        sessionsHeld: 12,
        scheduleSummary: 'Tue & Thu • 10:00 — 11:30 AM',
        room: 'Circuits Lab 102',
      ),
      CourseModel(
        id: 'crs-eee402',
        code: 'EEE-402',
        title: 'Embedded Systems Architecture',
        category: 'Core Major',
        credits: 3,
        departmentId: 'dep-ce',
        departmentName: 'Electrical & Electronic Engineering',
        facultyName: 'Faculty of Electrical & Computer Eng.',
        termId: activeTermId,
        status: CourseStatus.pendingLecturer,
        enrolledCount: 29,
        totalSessions: 14,
        scheduleSummary: 'Friday • 01:00 — 04:00 PM',
        room: 'Circuits Lab 102',
      ),
      CourseModel(
        id: 'crs-bus110',
        code: 'BUS-110',
        title: 'Principles of Management',
        category: 'Required',
        credits: 2,
        departmentId: 'dep-bus',
        departmentName: 'Management & Finance',
        facultyName: 'Faculty of Business Administration',
        termId: 'term-sp26',
        status: CourseStatus.archived,
        enrolledCount: 120,
        totalSessions: 14,
        sessionsHeld: 14,
      ),
    ];
    for (final course in c) {
      courses[course.id] = course;
    }
    for (final l in lecturers.values.toList()) {
      final ids = courses.values
          .where((c) => c.lecturerId == l.id)
          .map((c) => c.id)
          .toList();
      final total = courses.values
          .where((c) => c.lecturerId == l.id)
          .fold<int>(0, (s, c) => s + c.enrolledCount);
      lecturers[l.id] = LecturerModel(
        user: l.user,
        staffId: l.staffId,
        title: l.title,
        specialization: l.specialization,
        officeLocation: l.officeLocation,
        officeHours: l.officeHours,
        courseIds: ids,
        totalStudents: total,
        averageAttendance: 88,
        rating: l.rating,
      );
    }
  }

  static const List<String> _firstNames = [
    'Kofi',
    'Ama',
    'Yaw',
    'Efua',
    'Kwesi',
    'Abena',
    'Ifeoma',
    'Tunde',
    'Ngozi',
    'Chinedu',
    'Fatima',
    'Musa',
    'Zainab',
    'Ibrahim',
    'Aisha',
    'Samuel',
    'Grace',
    'Daniel',
    'Esther',
    'Joseph',
    'Mercy',
    'Peter',
    'Ruth',
    'Paul',
    'Linda',
    'Michael',
    'Joy',
    'Victor',
    'Precious',
    'Henry',
    'Blessing',
    'Kelvin',
    'Adwoa',
    'Nana',
    'Selorm',
  ];
  static const List<String> _lastNames = [
    'Mensah',
    'Owusu',
    'Boateng',
    'Asante',
    'Adeyemi',
    'Okafor',
    'Eze',
    'Bello',
    'Abubakar',
    'Danso',
    'Appiah',
    'Nwosu',
    'Ogunleye',
    'Yeboah',
    'Tetteh',
    'Addo',
    'Quaye',
    'Amoah',
    'Obi',
    'Lawal',
  ];

  void _seedStudents() {
    const named = [
      (
        currentStudentId,
        'Konga Mac-Bright',
        DemoAccounts.studentEmail,
        'ICT20251181',
        'B.Sc. Software Engineering & Systems',
      ),
      (
        'stu-002',
        'Amina Bello',
        'amina.bello@student.univ.edu',
        'ICT20251002',
        'Software Engineering',
      ),
      (
        'stu-003',
        'Emmanuel Kwame',
        'emmanuel.kwame@student.univ.edu',
        'ICT20251019',
        'Computer Science',
      ),
      (
        'stu-004',
        'Chiamaka Okonjo',
        'chiamaka.okonjo@student.univ.edu',
        'ICT20251044',
        'Artificial Intelligence',
      ),
      (
        'stu-005',
        'Tariq Al-Mansoor',
        'tariq.almansoor@student.univ.edu',
        'ICT20251088',
        'Info Systems',
      ),
      (
        'stu-006',
        'Sarah Osei-Bonsu',
        'sarah.osei@student.univ.edu',
        'ICT20251105',
        'Software Engineering',
      ),
      (
        'stu-007',
        'David Kalu',
        'david.kalu@student.univ.edu',
        'ICT20251031',
        'Computer Science',
      ),
    ];
    final entries = <(String, String, String, String, String)>[...named];
    for (var i = 0; i < 35; i++) {
      final first = _firstNames[i % _firstNames.length];
      final last = _lastNames[(i * 7) % _lastNames.length];
      final matric = 'ICT2025${(1200 + i * 3).toString().padLeft(4, '0')}';
      entries.add((
        'stu-${(100 + i).toString()}',
        '$first $last',
        '${first.toLowerCase()}.${last.toLowerCase()}$i@student.univ.edu',
        matric,
        i.isEven ? 'Computer Science' : 'Software Engineering',
      ));
    }

    for (final s in entries) {
      final user = UserModel(
        id: s.$1,
        fullName: s.$2,
        email: s.$3,
        role: UserRole.student,
        phone: s.$1 == currentStudentId ? '+234 803 456 7890' : null,
        departmentId: 'dep-cs',
        departmentName: 'Department of Computer Science',
        createdAt: now.subtract(const Duration(days: 700)),
        lastActiveAt: now.subtract(Duration(minutes: _random.nextInt(600))),
      );
      _addUser(user);
      final isCurrent = s.$1 == currentStudentId;
      students[s.$1] = StudentModel(
        user: user,
        matricule: s.$4,
        programme: s.$5,
        level: isCurrent ? 300 : 200,
        semester: 1,
        facultyName: 'Faculty of Computer Science',
        enrolledCourseIds: isCurrent
            ? const ['crs-cs301', 'crs-mth1221', 'crs-cs305', 'crs-eng210']
            : const ['crs-cs301', 'crs-swe201'],
        activeCredits: isCurrent ? 18 : 7,
        gpa: isCurrent ? 3.72 : null,
      );
    }

    final studentIds = students.keys.toList();
    enrollments['crs-cs301'] = studentIds.take(42).toList();
    enrollments['crs-swe201'] = studentIds.skip(1).take(40).toList();
    enrollments['crs-cs220'] = studentIds.skip(3).take(30).toList();
    enrollments['crs-cs450'] = studentIds.skip(5).take(25).toList();
    for (final id in ['crs-mth1221', 'crs-cs305', 'crs-eng210']) {
      enrollments[id] = [currentStudentId, ...studentIds.skip(10).take(20)];
    }
    for (final entry in enrollments.entries) {
      final course = courses[entry.key];
      if (course != null) {
        courses[entry.key] = course.copyWith(enrolledCount: entry.value.length);
      }
    }
  }

  DateTime _todayAt(int hour, int minute, {int dayOffset = 0}) {
    final d = now.add(Duration(days: dayOffset));
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  void _addSession(ClassSessionModel s) => sessions[s.id] = s;

  void _seedSessions() {
    // Today's timetable, anchored on "now" so there is always a live class.
    final liveStart = now.subtract(const Duration(minutes: 45));
    _addSession(
      ClassSessionModel(
        id: 'ses-mth1221-today',
        courseId: 'crs-mth1221',
        courseCode: 'MTH-1221',
        courseTitle: 'Real Analysis',
        title: 'Lecture 15: Uniform Continuity',
        startTime: liveStart.subtract(const Duration(minutes: 150)),
        endTime: liveStart.subtract(const Duration(minutes: 75)),
        lecturerId: 'lec-004',
        lecturerName: 'Dr. E. Vance',
        room: 'Hall C • Room 102',
        mode: SessionMode.inPerson,
        status: SessionStatus.completed,
        sessionNumber: 15,
        expectedCount: 21,
        participantCount: 20,
      ),
    );
    _addSession(
      ClassSessionModel(
        id: liveSessionId,
        courseId: 'crs-cs301',
        courseCode: 'CS-301',
        courseTitle: 'Data Structures & Algorithms',
        title: 'Lecture 13: Graph Traversal & BFS',
        startTime: liveStart,
        endTime: liveStart.add(const Duration(minutes: 90)),
        lecturerId: 'lec-001',
        lecturerName: 'Prof. Kwame Mensah',
        room: 'Hall B / Virtual Stream 01',
        mode: SessionMode.hybrid,
        status: SessionStatus.live,
        sessionNumber: 13,
        expectedCount: 42,
        participantCount: 38,
        attendanceActive: true,
        materials: const ['SlideDeck_13.pdf'],
      ),
    );
    _addSession(
      ClassSessionModel(
        id: 'ses-swe201-next',
        courseId: 'crs-swe201',
        courseCode: 'SWE-201',
        courseTitle: 'Software Engineering Principles',
        title: 'Lecture 12: Test-Driven Development',
        startTime: now.add(const Duration(minutes: 75)),
        endTime: now.add(const Duration(minutes: 165)),
        lecturerId: 'lec-001',
        lecturerName: 'Prof. Kwame Mensah',
        room: 'Lab Hall B',
        status: SessionStatus.scheduled,
        sessionNumber: 12,
        expectedCount: 40,
      ),
    );
    _addSession(
      ClassSessionModel(
        id: 'ses-cs305-today',
        courseId: 'crs-cs305',
        courseCode: 'CS-305',
        courseTitle: 'Database Systems',
        title: 'Lab 11: Query Optimisation',
        startTime: now.add(const Duration(minutes: 120)),
        endTime: now.add(const Duration(minutes: 210)),
        lecturerId: 'lec-003',
        lecturerName: 'Dr. S. Thorne',
        room: 'Lab 4B • Computer Science Wing',
        mode: SessionMode.inPerson,
        sessionNumber: 11,
        expectedCount: 21,
        materials: const ['Lab11_Preparatory.zip'],
      ),
    );
    _addSession(
      ClassSessionModel(
        id: 'ses-eng210-today',
        courseId: 'crs-eng210',
        courseCode: 'ENG-210',
        courseTitle: 'Academic Technical Writing',
        title: 'Seminar 12: Draft Submission Review',
        startTime: now.add(const Duration(minutes: 240)),
        endTime: now.add(const Duration(minutes: 315)),
        lecturerId: 'lec-005',
        lecturerName: 'Prof. M. Adebayo',
        room: 'Seminar Room 1',
        mode: SessionMode.inPerson,
        sessionNumber: 12,
        expectedCount: 21,
      ),
    );

    // Upcoming week.
    const upcoming = [
      (
        'crs-cs301',
        'Lecture 14: Shortest Paths (Dijkstra)',
        1,
        10,
        0,
        90,
        'Hall B & Virtual Room 2',
      ),
      (
        'crs-mth1221',
        'Lecture 16: Riemann Integration',
        1,
        10,
        0,
        75,
        'Hall C',
      ),
      (
        'crs-cs220',
        'Lecture 11: Interfaces & Mixins',
        1,
        13,
        0,
        90,
        'Room 304',
      ),
      ('crs-cs450', 'Lecture 10: Raft Consensus', 2, 11, 0, 90, 'Room 408B'),
      (
        'crs-cs305',
        'Lecture 12: Transactions & Isolation',
        3,
        11,
        30,
        90,
        'Lab 4B',
      ),
      (
        'crs-eng210',
        'Seminar 13: Peer Review Workshop',
        3,
        9,
        0,
        75,
        'Seminar Rm 1',
      ),
      (
        'crs-cs301',
        'Lecture 15: Minimum Spanning Trees',
        3,
        10,
        0,
        90,
        'Hall B & Virtual Room 2',
      ),
      (
        'crs-swe201',
        'Lecture 13: Continuous Integration',
        2,
        14,
        0,
        90,
        'Lab Hall B',
      ),
    ];
    for (var i = 0; i < upcoming.length; i++) {
      final u = upcoming[i];
      final course = courses[u.$1]!;
      final start = _todayAt(u.$4, u.$5, dayOffset: u.$3);
      _addSession(
        ClassSessionModel(
          id: 'ses-up-$i',
          courseId: course.id,
          courseCode: course.code,
          courseTitle: course.title,
          title: u.$2,
          startTime: start,
          endTime: start.add(Duration(minutes: u.$6)),
          lecturerId: course.lecturerId,
          lecturerName: course.lecturerName,
          room: u.$7,
          expectedCount: enrollments[course.id]?.length ?? 0,
        ),
      );
    }

    // Past sessions (completed) used for attendance history.
    const pastTopics = {
      'crs-cs301': [
        'Lecture 12: Binary Search Trees & AVL',
        'Lecture 11: Priority Queues & Heaps',
        'Lecture 10: Hash Tables',
        'Lecture 09: Balanced Trees',
        'Lecture 08: AVL Trees Balancing',
        'Lecture 07: Recursion & Divide and Conquer',
        'Lecture 06: Sorting Algorithms',
        'Lecture 05: Stacks & Queues',
        'Lecture 04: Linked Lists',
        'Lecture 03: Arrays & Complexity',
        'Lecture 02: Big-O Notation',
        'Lecture 01: Course Introduction',
      ],
      'crs-mth1221': [
        'Lecture 14: Continuity',
        'Lecture 13: Limits of Functions',
        'Lecture 12: Series Tests',
        'Lecture 11: Cauchy Sequences',
        'Lecture 10: Subsequences',
        'Lecture 09: Monotone Convergence',
        'Lecture 08: Sequences',
        'Lecture 07: Completeness Axiom',
        'Lecture 06: Supremum & Infimum',
        'Lecture 05: Countability',
      ],
      'crs-cs305': [
        'Lab 10: Indexing',
        'Lab 09: Normal Forms',
        'Lab 08: Joins',
        'Lab 07: Aggregations',
        'Lab 06: Subqueries',
        'Lab 05: ER Modelling',
        'Lab 04: Constraints',
        'Lab 03: Basic SQL',
        'Lab 02: Relational Model',
        'Lab 01: Introduction',
      ],
      'crs-eng210': [
        'Seminar 11: Abstracts',
        'Seminar 10: Figures & Tables',
        'Seminar 09: Referencing',
        'Seminar 08: Methods Sections',
        'Seminar 07: Structure',
        'Seminar 06: Audience',
        'Seminar 05: Clarity',
        'Seminar 04: Style',
        'Seminar 03: Planning',
        'Seminar 02: Reading Papers',
        'Seminar 01: Introduction',
      ],
      'crs-swe201': [
        'Lecture 11: Refactoring',
        'Lecture 10: Code Review',
        'Lecture 09: Unit Testing',
        'Lecture 08: Design Patterns',
      ],
      'crs-cs220': ['Lecture 10: Generics', 'Lecture 09: Polymorphism'],
      'crs-cs450': ['Lecture 09: Vector Clocks', 'Lecture 08: Replication'],
    };
    const pastRooms = {
      'crs-cs301': ['Hall B', 'Virtual Stream'],
      'crs-mth1221': ['Hall C'],
      'crs-cs305': ['Lab 4'],
      'crs-eng210': ['Seminar Rm 1'],
      'crs-swe201': ['Lab Hall B'],
      'crs-cs220': ['Room 304'],
      'crs-cs450': ['Room 408B'],
    };
    const startHours = {
      'crs-cs301': (10, 0, 90),
      'crs-mth1221': (8, 30, 75),
      'crs-cs305': (11, 30, 90),
      'crs-eng210': (9, 0, 75),
      'crs-swe201': (14, 0, 90),
      'crs-cs220': (13, 0, 90),
      'crs-cs450': (11, 0, 90),
    };
    pastTopics.forEach((courseId, topics) {
      final course = courses[courseId]!;
      final time = startHours[courseId]!;
      final rooms = pastRooms[courseId]!;
      for (var i = 0; i < topics.length; i++) {
        final daysAgo = 2 + i * 3 + (courseId.length % 2);
        final start = _todayAt(time.$1, time.$2, dayOffset: -daysAgo);
        _addSession(
          ClassSessionModel(
            id: 'ses-$courseId-past-$i',
            courseId: courseId,
            courseCode: course.code,
            courseTitle: course.title,
            title: topics[i],
            startTime: start,
            endTime: start.add(Duration(minutes: time.$3)),
            lecturerId: course.lecturerId,
            lecturerName: course.lecturerName,
            room: rooms[i % rooms.length],
            status: SessionStatus.completed,
            sessionNumber: topics.length - i,
            expectedCount: enrollments[courseId]?.length ?? 0,
          ),
        );
      }
    });
  }

  AttendanceStatus _statusFor(String studentId, String courseId, int index) {
    // Hand-tuned outcomes that match the Stitch designs.
    if (studentId == currentStudentId) {
      if (courseId == 'crs-cs301' && index == 3) {
        return AttendanceStatus.excused;
      }
      if (courseId == 'crs-mth1221' && index == 1) return AttendanceStatus.late;
      if (courseId == 'crs-mth1221' && index == 6) {
        return AttendanceStatus.absent;
      }
      if (courseId == 'crs-cs305' && index == 4) return AttendanceStatus.absent;
      if (courseId == 'crs-cs305' && index == 8) return AttendanceStatus.late;
      if (courseId == 'crs-eng210' && index == 9) {
        return AttendanceStatus.absent;
      }
      return AttendanceStatus.present;
    }
    if (studentId == 'stu-005') {
      return index % 3 == 0
          ? AttendanceStatus.absent
          : AttendanceStatus.present;
    }
    if (studentId == 'stu-002' || studentId == 'stu-003') {
      return AttendanceStatus.present;
    }
    if (studentId == 'stu-006' && index == 0) return AttendanceStatus.late;
    final roll = _random.nextDouble();
    if (roll < 0.06) return AttendanceStatus.absent;
    if (roll < 0.1) return AttendanceStatus.late;
    return AttendanceStatus.present;
  }

  static const List<String> _verificationMethods = [
    'Smart Geofence & Biometric check-in',
    'BLE Geofence Verified',
    'Biometric Sign-in',
    'Room PIN Verified',
    'BLE Proximity',
  ];

  void _seedAttendance() {
    final completed =
        sessions.values
            .where((s) => s.status == SessionStatus.completed)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final indexByCourse = <String, int>{};
    for (final session in completed) {
      final index = indexByCourse.update(
        session.courseId,
        (v) => v + 1,
        ifAbsent: () => 0,
      );
      final enrolled = enrollments[session.courseId] ?? const [];
      final minutes = session.duration.inMinutes;
      for (final studentId in enrolled) {
        final student = students[studentId]!;
        final status = _statusFor(studentId, session.courseId, index);
        final lateBy = status == AttendanceStatus.late ? 12 + index % 7 : 0;
        final checkIn = status.countsAsAttended
            ? session.startTime.add(Duration(minutes: lateBy))
            : null;
        final logged = switch (status) {
          AttendanceStatus.present => minutes - _random.nextInt(4),
          AttendanceStatus.late => minutes - lateBy,
          _ => 0,
        };
        final id = 'att-${session.id}-$studentId';
        attendance[id] = AttendanceRecordModel(
          id: id,
          sessionId: session.id,
          studentId: studentId,
          studentName: student.user.fullName,
          matricule: student.matricule,
          courseId: session.courseId,
          courseCode: session.courseCode,
          courseTitle: session.courseTitle,
          status: status,
          sessionStart: session.startTime,
          checkedInAt: checkIn,
          leftAt: checkIn == null ? null : session.endTime,
          minutesLogged: logged,
          sessionMinutes: minutes,
          verificationMethod: status == AttendanceStatus.excused
              ? 'Medical Slip #MED-881 Approved'
              : status.countsAsAttended
              ? _verificationMethods[index % _verificationMethods.length]
              : 'No Check-in Recorded',
          lecturerName: session.lecturerName,
          room: session.room,
        );
      }
    }

    // Live session: most of the cohort already checked in.
    final live = sessions[liveSessionId]!;
    final cohort = enrollments[live.courseId]!;
    for (var i = 0; i < cohort.length; i++) {
      final studentId = cohort[i];
      final student = students[studentId]!;
      final AttendanceStatus status;
      if (studentId == 'stu-005' || i == cohort.length - 1) {
        status = AttendanceStatus.absent;
      } else if (studentId == 'stu-006' || i == cohort.length - 2) {
        status = AttendanceStatus.late;
      } else if (studentId == currentStudentId) {
        // The demo student checks in when joining the live class.
        continue;
      } else {
        status = AttendanceStatus.present;
      }
      final lateBy = status == AttendanceStatus.late ? 17 : i % 4;
      final checkIn = status == AttendanceStatus.absent
          ? null
          : live.startTime.add(Duration(minutes: lateBy));
      final id = 'att-${live.id}-$studentId';
      attendance[id] = AttendanceRecordModel(
        id: id,
        sessionId: live.id,
        studentId: studentId,
        studentName: student.user.fullName,
        matricule: student.matricule,
        courseId: live.courseId,
        courseCode: live.courseCode,
        courseTitle: live.courseTitle,
        status: status,
        sessionStart: live.startTime,
        checkedInAt: checkIn,
        minutesLogged: checkIn == null ? 0 : now.difference(checkIn).inMinutes,
        sessionMinutes: live.duration.inMinutes,
        verificationMethod: checkIn == null
            ? 'No proximity detected'
            : _verificationMethods[i % _verificationMethods.length],
        lecturerName: live.lecturerName,
        room: live.room,
      );
    }
  }

  void _seedClassroom() {
    final live = sessions[liveSessionId]!;
    final lecturer = lecturers['lec-001']!;
    final list = <ParticipantModel>[
      ParticipantModel(
        userId: lecturer.id,
        name: lecturer.user.fullName,
        role: UserRole.lecturer,
        joinedAt: live.startTime,
        isMuted: false,
        isVideoOn: true,
        isSpeaking: true,
      ),
    ];
    final present = sessionAttendance(live.id)
        .where((r) => r.status.countsAsAttended)
        .toList();
    for (var i = 0; i < present.length; i++) {
      final r = present[i];
      list.add(
        ParticipantModel(
          userId: r.studentId,
          name: r.studentName,
          role: UserRole.student,
          joinedAt: r.checkedInAt ?? live.startTime,
          isVideoOn: i % 3 == 0,
          isHandRaised: r.studentId == 'stu-007',
        ),
      );
    }
    participants[live.id] = list;

    final chat = [
      (
        'lec-001',
        'Prof. Kwame Mensah',
        UserRole.lecturer,
        'Welcome everyone! Today we cover BFS and graph traversal. Slides are in the course materials.',
        40,
      ),
      (
        'stu-002',
        'Amina Bello',
        UserRole.student,
        'Good morning Prof! Will BFS be on the midterm?',
        36,
      ),
      (
        'lec-001',
        'Prof. Kwame Mensah',
        UserRole.lecturer,
        'Yes — both BFS and DFS, including complexity analysis.',
        35,
      ),
      (
        'stu-003',
        'Emmanuel Kwame',
        UserRole.student,
        'Is the adjacency list always better than the matrix for sparse graphs?',
        20,
      ),
      (
        'stu-004',
        'Chiamaka Okonjo',
        UserRole.student,
        'I think it saves memory: O(V + E) instead of O(V²).',
        18,
      ),
      (
        'stu-007',
        'David Kalu',
        UserRole.student,
        'Can you repeat the queue step for the visited set?',
        6,
      ),
    ];
    messages[live.id] = [
      for (var i = 0; i < chat.length; i++)
        ChatMessageModel(
          id: 'msg-$i',
          classroomId: live.id,
          senderId: chat[i].$1,
          senderName: chat[i].$2,
          senderRole: chat[i].$3,
          message: chat[i].$4,
          timestamp: now.subtract(Duration(minutes: chat[i].$5)),
          isQuestion: chat[i].$4.endsWith('?'),
          isPinned: i == 0,
        ),
    ];

    const opts = ['O(1)', 'O(n)', 'O(log n)', 'O(n²)'];
    const labels = ['A', 'B', 'C', 'D'];
    const counts = [2, 5, 24, 1];
    questions['q-live-1'] = QuestionModel(
      id: 'q-live-1',
      sessionId: live.id,
      text: 'What is the average time complexity of Binary Search on a sorted array?',
      topic: 'Algorithms & Complexity • Single Choice',
      options: [
        for (var i = 0; i < opts.length; i++)
          QuestionOption(
            id: 'q-live-1-${labels[i]}',
            label: labels[i],
            text: opts[i],
            responseCount: counts[i],
          ),
      ],
      correctOptionId: 'q-live-1-C',
      durationSeconds: 600,
      status: QuestionStatus.active,
      createdAt: now.subtract(const Duration(minutes: 1)),
      launchedAt: now,
      expectedResponders: present.length,
    );
  }

  void _seedNotifications() {
    final items = [
      (
        currentStudentId,
        'CS-301 is live now',
        'Prof. Kwame Mensah started "Lecture 13: Graph Traversal & BFS". Smart attendance is active.',
        NotificationType.classReminder,
        44,
        false,
        liveSessionId,
        'Join Now',
      ),
      (
        currentStudentId,
        'New live question',
        'A participation check is open in CS-301. Answer before the timer ends.',
        NotificationType.liveQuestion,
        1,
        false,
        'q-live-1',
        'Answer',
      ),
      (
        currentStudentId,
        'Attendance updated',
        'MTH-1221 Session 13 was marked Late (18 min delay). You can submit an appeal within 48 hours.',
        NotificationType.attendanceUpdate,
        180,
        false,
        null,
        null,
      ),
      (
        currentStudentId,
        'Room change: CS-305',
        'Lab 11 moves to Lab 4B • Computer Science Wing.',
        NotificationType.classReminder,
        300,
        true,
        'ses-cs305-today',
        null,
      ),
      (
        currentStudentId,
        'Enrolled in ENG-210',
        'You have been enrolled in Academic Technical Writing for this term.',
        NotificationType.newCourse,
        60 * 24 * 3,
        true,
        'crs-eng210',
        null,
      ),
      (
        currentStudentId,
        'Mid-semester exam timetable published',
        'The Registrar has published the mid-semester examination timetable.',
        NotificationType.announcement,
        60 * 24 * 5,
        true,
        null,
        null,
      ),
      (
        'lec-001',
        '2 attendance appeals pending',
        'MTH-1221 students submitted medical leave slips for review.',
        NotificationType.attendanceUpdate,
        90,
        false,
        null,
        'Review',
      ),
      (
        'lec-001',
        'SWE-201 starts soon',
        'Lecture 12: Test-Driven Development begins in Lab Hall B.',
        NotificationType.classReminder,
        5,
        false,
        'ses-swe201-next',
        null,
      ),
      (
        'lec-001',
        'Faculty board meeting',
        'Faculty board meeting moved to Friday 3:00 PM.',
        NotificationType.announcement,
        60 * 26,
        true,
        null,
        null,
      ),
      (
        currentAdminId,
        'Registrar sync completed',
        'PostgreSQL & SIS sync finished successfully (1,420 records).',
        NotificationType.announcement,
        18,
        false,
        null,
        null,
      ),
      (
        currentAdminId,
        'EEE-402 needs a lecturer',
        'Embedded Systems Architecture has no assigned instructor.',
        NotificationType.newCourse,
        240,
        false,
        'crs-eee402',
        'Assign',
      ),
    ];
    for (var i = 0; i < items.length; i++) {
      final n = items[i];
      notifications['ntf-$i'] = NotificationModel(
        id: 'ntf-$i',
        userId: n.$1,
        title: n.$2,
        body: n.$3,
        type: n.$4,
        createdAt: now.subtract(Duration(minutes: n.$5)),
        isRead: n.$6,
        referenceId: n.$7,
        actionLabel: n.$8,
      );
    }
  }

  void _seedActivity() {
    final items = [
      (
        'New lecturer onboarded',
        'Dr. S. Thorne completed faculty registration.',
        'System',
        ActivitySeverity.success,
        'users',
        25,
      ),
      (
        'Course created',
        'EEE-402 Embedded Systems Architecture added to Fall term.',
        'Sarah Jenkins',
        ActivitySeverity.info,
        'courses',
        90,
      ),
      (
        'Attendance threshold alert',
        '48 students are below the 75% attendance requirement.',
        'Attendance Engine',
        ActivitySeverity.warning,
        'attendance',
        180,
      ),
      (
        'Registrar sync',
        'PostgreSQL & SIS registrar sync completed in 42s.',
        'Scheduler',
        ActivitySeverity.success,
        'system',
        18,
      ),
      (
        'Failed login attempts',
        '5 failed admin login attempts from an unknown device.',
        'Security Monitor',
        ActivitySeverity.critical,
        'security',
        400,
      ),
    ];
    for (var i = 0; i < items.length; i++) {
      final a = items[i];
      activity.add(
        ActivityLogModel(
          id: 'act-$i',
          title: a.$1,
          description: a.$2,
          actorName: a.$3,
          severity: a.$4,
          category: a.$5,
          timestamp: now.subtract(Duration(minutes: a.$6)),
        ),
      );
    }
    activity.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
