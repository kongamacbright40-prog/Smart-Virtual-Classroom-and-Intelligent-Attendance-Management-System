import 'package:flutter/material.dart';

import '../../features/student/attendance/student_attendance_screen.dart';
import '../../features/student/courses/student_courses_screen.dart';
import '../../features/student/home/student_home_screen.dart';
import '../../features/student/profile/student_profile_screen.dart';
import '../../features/student/schedule/student_schedule_screen.dart';
import 'role_shell.dart';

/// Student bottom navigation: Home • Courses • Schedule • Attendance • Profile.
class StudentNavigation extends StatelessWidget {
  const StudentNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      initialIndex: initialIndex,
      destinations: [
        ShellDestination(
          label: 'Home',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          builder: (_) => const StudentHomeScreen(),
        ),
        ShellDestination(
          label: 'Courses',
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book,
          builder: (_) => const StudentCoursesScreen(),
        ),
        ShellDestination(
          label: 'Schedule',
          icon: Icons.calendar_today_outlined,
          selectedIcon: Icons.calendar_today,
          builder: (_) => const StudentScheduleScreen(),
        ),
        ShellDestination(
          label: 'Attendance',
          icon: Icons.how_to_reg_outlined,
          selectedIcon: Icons.how_to_reg,
          builder: (_) => const StudentAttendanceScreen(),
        ),
        ShellDestination(
          label: 'Profile',
          icon: Icons.account_circle_outlined,
          selectedIcon: Icons.account_circle,
          builder: (_) => const StudentProfileScreen(),
        ),
      ],
    );
  }
}
