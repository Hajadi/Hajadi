import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Read-only star row. [size] keeps it usable from a dense list row up to a
/// profile header.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.color = AppColors.star,
  });

  final double rating;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int index = 1; index <= 5; index++)
            Icon(
              rating >= index
                  ? Icons.star_rounded
                  : (rating >= index - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
              size: size,
              color: color,
            ),
        ],
      );
}

/// Tappable star row used by the review form.
class RatingInput extends StatelessWidget {
  const RatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 40,
  });

  final double rating;
  final ValueChanged<double> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int index = 1; index <= 5; index++)
            IconButton(
              onPressed: () => onChanged(index.toDouble()),
              icon: Icon(
                rating >= index ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: AppColors.star,
              ),
              tooltip: '$index',
            ),
        ],
      );
}
