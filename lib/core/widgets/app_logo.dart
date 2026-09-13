import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The brand mark: a rounded royal-blue square holding a wrench-and-spark
/// glyph, with the word mark beside or beneath it.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 56,
    this.showWordmark = true,
    this.vertical = false,
    this.onDark = false,
  });

  final double size;
  final bool showWordmark;
  final bool vertical;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Widget mark = Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.handyman_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    );

    if (!showWordmark) {
      return mark;
    }

    final Color textColor =
        onDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final Widget wordmark = Column(
      crossAxisAlignment:
          vertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Jwenn Mèt',
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: textColor,
          ),
        ),
        Text(
          'Ayiti',
          style: TextStyle(
            fontSize: size * 0.22,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: onDark
                ? Colors.white70
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );

    return vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              mark,
              const SizedBox(height: AppSpacing.md),
              wordmark,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              mark,
              const SizedBox(width: AppSpacing.md),
              wordmark,
            ],
          );
  }
}
