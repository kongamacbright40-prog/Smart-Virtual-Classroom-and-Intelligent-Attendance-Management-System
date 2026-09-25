import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Initials avatar with optional online / status indicator.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.imageUrl,
    this.showOnline = false,
    this.statusColor,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String name;
  final double size;
  final String? imageUrl;
  final bool showOnline;
  final Color? statusColor;
  final Color? backgroundColor;
  final Color? foregroundColor;

  static const List<Color> _palette = [
    Color(0xFFDBE1FF),
    Color(0xFFC9E6FF),
    Color(0xFFDAE2FD),
    Color(0xFFD1FAE5),
    Color(0xFFFEF3C7),
    Color(0xFFFFE4E6),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        _palette[name.codeUnits.fold<int>(0, (a, b) => a + b) % _palette.length];
    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: bg,
      foregroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
      child: Text(
        Formatters.initials(name),
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: foregroundColor ?? AppColors.onPrimaryFixed,
        ),
      ),
    );
    if (!showOnline && statusColor == null) return avatar;
    final dot = size * 0.28;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: statusColor ?? AppColors.live,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
