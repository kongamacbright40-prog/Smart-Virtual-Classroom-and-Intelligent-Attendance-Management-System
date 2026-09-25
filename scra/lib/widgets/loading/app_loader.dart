import 'package:flutter/material.dart';

/// Brand spinner. Use [AppLoader.overlay] to block a screen during a task.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 32, this.color, this.strokeWidth = 3});

  final double size;
  final Color? color;
  final double strokeWidth;

  static Widget overlay({required bool visible, required Widget child}) {
    return Stack(
      children: [
        child,
        if (visible)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66000000),
              child: Center(child: AppLoader(color: Colors.white)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
