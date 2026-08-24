import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_theme.dart';

/// The official Lock In minimal ink logo widget
class LockInLogo extends StatelessWidget {
  final double size;
  final bool hasBorder;

  const LockInLogo({
    super.key,
    this.size = 36,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final logo = SvgPicture.asset(
      'assets/lock-in-logo.svg',
      width: size,
      height: size,
    );

    if (!hasBorder) return logo;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppTheme.ink, width: 1.5),
        boxShadow: AppTheme.smallTactileShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: logo,
    );
  }
}

/// Custom painter that draws an organic, slightly imperfect hand-drawn circle
/// providing the doodle/sketch tactile feel without excessive roughness.
class OrganicCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double progress; // 0.0 to 1.0 for timer progress if desired

  const OrganicCirclePainter({
    this.color = AppTheme.ink,
    this.strokeWidth = 1.5,
    this.progress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;

    final path = Path();
    const segments = 48;
    // Controlled subtle wobble offsets to give natural hand-drawn quality
    final wobble = [
      0.0, 0.8, 1.2, 0.6, -0.4, -1.0, -0.7, 0.3,
      0.9, 1.4, 0.8, -0.2, -0.9, -1.2, -0.5, 0.4,
      1.1, 1.3, 0.5, -0.6, -1.1, -0.8, 0.2, 0.9,
      1.2, 0.7, -0.3, -1.0, -1.3, -0.4, 0.5, 1.0,
      1.3, 0.6, -0.5, -1.1, -0.9, 0.1, 0.8, 1.2,
      0.7, -0.2, -0.8, -1.2, -0.6, 0.3, 0.9, 0.0,
    ];

    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      if (t > progress && progress < 1.0) break;
      final angle = (t * 2 * math.pi) - (math.pi / 2);
      final offset = wobble[i % wobble.length] * 0.9;
      final r = radius + offset;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (progress >= 1.0) {
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant OrganicCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progress != progress;
  }
}

/// Tiny decorative 4-point doodle sparkle icon
class SparkleDoodle extends StatelessWidget {
  final double size;
  final Color color;

  const SparkleDoodle({
    super.key,
    this.size = 20,
    this.color = AppTheme.ink,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(color: color),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;

  const _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path();

    // Draw a neat 4-pointed star sparkle
    path.moveTo(w * 0.5, 0);
    path.quadraticBezierTo(w * 0.5, h * 0.5, w, h * 0.5);
    path.quadraticBezierTo(w * 0.5, h * 0.5, w * 0.5, h);
    path.quadraticBezierTo(w * 0.5, h * 0.5, 0, h * 0.5);
    path.quadraticBezierTo(w * 0.5, h * 0.5, w * 0.5, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Tactile button with black 1.5px border, peach/sage fill, and hard 3px offset shadow
class TactileButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color fillColor;
  final Color textColor;
  final Color borderColor;
  final double height;
  final double borderRadius;
  final Widget? leading;
  final bool isFullWidth;
  final double fontSize;

  const TactileButton({
    super.key,
    required this.label,
    required this.onTap,
    this.fillColor = AppTheme.peach,
    this.textColor = AppTheme.ink,
    this.borderColor = AppTheme.ink,
    this.height = 54,
    this.borderRadius = 16,
    this.leading,
    this.isFullWidth = true,
    this.fontSize = 15,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      height: widget.height,
      width: widget.isFullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isFullWidth ? 16 : 22,
      ),
      transform: _isPressed
          ? Matrix4.translationValues(2, 2, 0)
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: widget.fillColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: widget.borderColor, width: 1.5),
        boxShadow: _isPressed
            ? [
                BoxShadow(
                  color: widget.borderColor,
                  offset: const Offset(1, 1),
                  blurRadius: 0,
                )
              ]
            : [
                BoxShadow(
                  color: widget.borderColor,
                  offset: const Offset(3, 3),
                  blurRadius: 0,
                )
              ],
      ),
      child: Row(
        mainAxisSize:
            widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: 8),
          ],
          Text(
            widget.label,
            style: AppTheme.sansBody(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w600,
              color: widget.textColor,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: content,
    );
  }
}

/// Outlined horizontal progress bar with solid black fill
class InkProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color fillColor;
  final Color borderColor;
  final Color trackColor;

  const InkProgressBar({
    super.key,
    required this.progress,
    this.height = 7,
    this.fillColor = AppTheme.ink,
    this.borderColor = AppTheme.ink,
    this.trackColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: constraints.maxWidth * clampedProgress,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Minimal duration selection chip
class DurationChip extends StatelessWidget {
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  const DurationChip({
    super.key,
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.ink : AppTheme.inkFaint,
            width: 1.2,
          ),
          boxShadow: isSelected ? AppTheme.smallTactileShadow : [],
        ),
        child: Text(
          '$minutes m',
          style: AppTheme.sansBody(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppTheme.background : AppTheme.inkMuted,
          ),
        ),
      ),
    );
  }
}
