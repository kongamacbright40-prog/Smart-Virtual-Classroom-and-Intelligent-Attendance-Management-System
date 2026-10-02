import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../models/user_model.dart';
import '../../../widgets/common/app_logo.dart';
import '../../authentication/providers/auth_provider.dart';

/// Stitch screen 01 — dark brand splash. Restores the session and routes to
/// the role home when signed in, otherwise straight to login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.minimumDuration = const Duration(milliseconds: 1600),
  });

  final Duration minimumDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();
    await Future.wait([
      auth.bootstrap(),
      Future<void>.delayed(widget.minimumDuration),
    ]);
    if (!mounted) return;
    final String route;
    Object? args;
    if (auth.isAuthenticated && auth.role != null) {
      route = AppRouter.homeFor(auth.role!);
    } else if (auth.selectedRole == UserRole.admin) {
      route = RouteNames.adminLogin;
    } else {
      route = RouteNames.login;
      args = auth.selectedRole;
    }
    Navigator.of(context).pushReplacementNamed(route, arguments: args);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.15),
                  radius: 0.8,
                  colors: [Color(0x400284C7), Color(0x000F172A)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceLg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _Emblem(),
                          const SizedBox(height: AppDimensions.spaceXl),
                          Text(
                            AppStrings.appName,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceSm),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: Text(
                              AppStrings.tagline,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.slate300,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceXl),
                          SizedBox(
                            width: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                              child: const LinearProgressIndicator(
                                minHeight: 6,
                                color: AppColors.sky500,
                                backgroundColor: AppColors.slate800,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceMd),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox.square(
                                dimension: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.sky400,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spaceSm),
                              Flexible(
                                child: Text(
                                  'Loading...',
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: const Color(0xCC7DD3FC),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spaceLg,
                    0,
                    AppDimensions.spaceLg,
                    AppDimensions.spaceLg,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'v${AppConstants.appVersion}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.slate400,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: 128,
          height: 128,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xE61E293B), Color(0xF20F172A)],
            ),
            border: Border.all(color: AppColors.sky400.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.sky500.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const AppLogo(size: 100),
        ),
        Positioned(
          bottom: -12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.splashBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34D399),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Color(0xFF6EE7B7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Faint academic blueprint grid behind the splash content.
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.sky400.withValues(alpha: 0.06)
      ..strokeWidth = 0.7;
    final dot = Paint()..color = AppColors.sky400.withValues(alpha: 0.1);
    const step = 48.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    for (var x = step / 2; x < size.width; x += step) {
      for (var y = step / 2; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.sky400.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height * 0.42);
    for (final r in [140.0, 220.0, 310.0]) {
      canvas.drawCircle(center, r, ring);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
