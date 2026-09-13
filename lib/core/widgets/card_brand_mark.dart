import 'package:flutter/material.dart';

import '../utils/card_utils.dart';

/// Visa and Mastercard marks, drawn rather than shipped as images.
///
/// Card-scheme logos are trademarks with their own artwork rules; these are
/// neutral recognisable stand-ins for the UI. Swap in the official assets from
/// each scheme's brand centre before a store release.
class CardBrandMark extends StatelessWidget {
  const CardBrandMark({super.key, required this.brand, this.height = 22});

  final CardBrand brand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double width = height * 1.6;

    Widget frame({required Widget child, Color? background}) => Container(
          height: height,
          width: width,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: child,
        );

    return switch (brand) {
      CardBrand.visa => frame(
          child: Text(
            'VISA',
            style: TextStyle(
              fontSize: height * 0.46,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF1A1F71),
            ),
          ),
          background: Colors.white,
        ),
      CardBrand.mastercard => frame(
          background: Colors.white,
          child: SizedBox(
            height: height * 0.62,
            width: height * 1.05,
            child: CustomPaint(painter: _MastercardPainter()),
          ),
        ),
      _ => frame(
          child: Icon(
            Icons.credit_card_rounded,
            size: height * 0.62,
            color: theme.colorScheme.onSurface,
          ),
        ),
    };
  }
}

class _MastercardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.height / 2;
    final Offset left = Offset(radius * 0.92, radius);
    final Offset right = Offset(size.width - radius * 0.92, radius);

    canvas.drawCircle(left, radius, Paint()..color = const Color(0xFFEB001B));
    canvas.drawCircle(right, radius, Paint()..color = const Color(0xFFF79E1B));

    // The overlap reads as the scheme's interlocking circles.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: left, radius: radius)),
    );
    canvas.drawCircle(right, radius, Paint()..color = const Color(0xFFFF5F00));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MastercardPainter oldDelegate) => false;
}

/// The row of accepted brands shown next to the card option.
class AcceptedCardBrands extends StatelessWidget {
  const AcceptedCardBrands({super.key, this.height = 20});

  final double height;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CardBrandMark(brand: CardBrand.visa, height: height),
          const SizedBox(width: 6),
          CardBrandMark(brand: CardBrand.mastercard, height: height),
        ],
      );
}
