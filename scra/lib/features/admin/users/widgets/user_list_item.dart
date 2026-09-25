
import 'package:flutter/material.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/status_chip.dart';
import 'package:smart_class/widgets/common/user_avatar.dart';

class UserListItem extends StatelessWidget {
  const UserListItem({
    super.key,
    required this.user,
    required this.identifier,
    required this.onEdit,
    required this.onResetPassword,
    required this.onToggleActive,
    required this.onDelete,
  });

  final UserModel user;
  final String identifier;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final roleTone = switch (user.role) {
      UserRole.student => StatusTone.neutral,
      UserRole.lecturer => StatusTone.primary,
      UserRole.admin => StatusTone.info,
    };
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(name: user.fullName, imageUrl: user.avatarUrl, showOnline: user.isActive),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppDimensions.spaceSm,
                      runSpacing: AppDimensions.spaceXs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(user.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                        StatusChip(label: user.role.label, tone: roleTone, dense: true),
                      ],
                    ),
                    Text(user.departmentName ?? user.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'User actions',
                onSelected: (value) {
                  switch (value) {
                    case 'edit': onEdit();
                    case 'reset': onResetPassword();
                    case 'toggle': onToggleActive();
                    case 'delete': onDelete();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Account')),
                  const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                  PopupMenuItem(value: 'toggle', child: Text(user.isActive ? 'Deactivate' : 'Activate')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete Record')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Wrap(
              spacing: AppDimensions.spaceSm,
              runSpacing: AppDimensions.spaceSm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(identifier, style: Theme.of(context).textTheme.labelLarge),
                Text('• ${user.email}', maxLines: 1, overflow: TextOverflow.ellipsis),
                StatusChip(label: user.isActive ? 'Active' : 'Suspended', tone: user.isActive ? StatusTone.live : StatusTone.neutral, showDot: true, dense: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
