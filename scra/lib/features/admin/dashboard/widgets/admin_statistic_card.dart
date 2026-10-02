import 'package:flutter/material.dart';

import 'package:smart_class/core/constants/app_colors.dart';
import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/status_chip.dart';

class AdminStatisticCard extends StatelessWidget {
  const AdminStatisticCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.helper,
    this.badge,
    this.tone = StatusTone.primary,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final String helper;
  final String? badge;
  final StatusTone tone;

  /// Opens the details behind the number (shows a chevron when set).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceSm),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              if (badge != null)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: StatusChip(label: badge!, tone: tone, dense: true),
                    ),
                  ),
                )
              else
                const Spacer(),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppDimensions.spaceXs),
          Row(
            children: [
              Expanded(
                child: Text(
                  helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
