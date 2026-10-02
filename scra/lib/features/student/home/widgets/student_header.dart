import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../models/models.dart';
import '../../../../widgets/buttons/icon_button.dart';
import '../../../../widgets/common/user_avatar.dart';

class StudentHeader extends StatelessWidget {
  const StudentHeader({
    super.key,
    required this.student,
    required this.onSearch,
    required this.onNotifications,
    this.unreadCount = 0,
  });

  final StudentModel student;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        UserAvatar(
          name: student.user.fullName,
          imageUrl: student.user.avatarUrl,
          size: 56,
          showOnline: true,
        ),
        const SizedBox(width: AppDimensions.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Classes', style: theme.textTheme.headlineSmall),
              Text(
                student.semester == null
                    ? 'Welcome back, ${student.user.firstName}'
                    : 'Welcome back, ${student.user.firstName} • Semester ${student.semester}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSm),
        AppIconButton(
          icon: Icons.search,
          tooltip: 'Search courses',
          onPressed: onSearch,
        ),
        const SizedBox(width: AppDimensions.spaceSm),
        AppIconButton(
          icon: Icons.notifications_outlined,
          tooltip: 'Notifications',
          badgeCount: unreadCount == 0 ? null : unreadCount,
          onPressed: onNotifications,
        ),
      ],
    );
  }
}
