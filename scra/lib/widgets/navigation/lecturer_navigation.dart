import 'package:flutter/material.dart';

import '../../features/lecturer/attendance/live_attendance_screen.dart';
import '../../features/lecturer/courses/lecturer_courses_screen.dart';
import '../../features/lecturer/dashboard/lecturer_dashboard_screen.dart';
import '../../features/lecturer/reports/attendance_reports_screen.dart';
import 'role_shell.dart';

/// Lecturer bottom navigation: Dashboard • Courses • Attendance • Reports
/// (matches the Stitch lecturer screens).
class LecturerNavigation extends StatelessWidget {
  const LecturerNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      initialIndex: initialIndex,
      destinations: [
        ShellDestination(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          builder: (_) => const LecturerDashboardScreen(),
        ),
        ShellDestination(
          label: 'Courses',
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book,
          builder: (_) => const LecturerCoursesScreen(),
        ),
        ShellDestination(
          label: 'Attendance',
          icon: Icons.how_to_reg_outlined,
          selectedIcon: Icons.how_to_reg,
          builder: (_) => const LiveAttendanceScreen(sessionId: null),
        ),
        ShellDestination(
          label: 'Reports',
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          builder: (_) => const AttendanceReportsScreen(courseId: null),
        ),
      ],
    );
  }
}
