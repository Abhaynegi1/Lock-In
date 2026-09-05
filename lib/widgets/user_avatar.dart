import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_theme.dart';

class DefaultAvatarItem {
  final String path;
  final String label;
  final String description;

  const DefaultAvatarItem({
    required this.path,
    required this.label,
    required this.description,
  });
}

class AppAvatars {
  static const List<DefaultAvatarItem> presets = [
    DefaultAvatarItem(
      path: '',
      label: 'Classic Profile',
      description: 'Standard profile icon',
    ),
    DefaultAvatarItem(
      path: 'assets/default_pfp/avatar-spark.svg',
      label: 'Peach Spark',
      description: 'Energetic focus',
    ),
    DefaultAvatarItem(
      path: 'assets/default_pfp/avatar-moon.svg',
      label: 'Sage Moon',
      description: 'Night owl session',
    ),
    DefaultAvatarItem(
      path: 'assets/default_pfp/avatar-book.svg',
      label: 'Blue Book',
      description: 'Deep study & reading',
    ),
    DefaultAvatarItem(
      path: 'assets/default_pfp/avatar-orbit.svg',
      label: 'Lavender Orbit',
      description: 'In the zone',
    ),
  ];

  static bool isPreset(String path) {
    return presets.any((item) => item.path == path);
  }
}

class UserAvatar extends StatelessWidget {
  final String? avatarPath;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool showShadow;
  final List<BoxShadow>? customShadow;

  const UserAvatar({
    super.key,
    required this.avatarPath,
    this.size = 44.0,
    this.borderWidth = 1.5,
    this.borderColor,
    this.backgroundColor,
    this.showShadow = false,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePath = (avatarPath == null || avatarPath!.trim().isEmpty || avatarPath == 'default')
        ? ''
        : avatarPath!.trim();
    final effectiveBorderColor = borderColor ?? AppTheme.inkColor(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppTheme.sandColor(context),
        border: borderWidth > 0
            ? Border.all(color: effectiveBorderColor, width: borderWidth)
            : null,
        boxShadow: customShadow ?? (showShadow ? AppTheme.shadow(context) : null),
      ),
      child: ClipOval(child: _buildAvatarContent(context, effectivePath)),
    );
  }

  Widget _buildAvatarContent(BuildContext context, String path) {
    if (path.isEmpty) {
      return _fallbackIcon(context);
    }

    if (path.startsWith('assets/') || path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _fallbackIcon(context),
      );
    }

    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackIcon(context),
        );
      }
    } catch (_) {
      // Fallback
    }

    return _fallbackIcon(context);
  }

  Widget _fallbackIcon(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: size * 0.58,
        color: AppTheme.text(context),
      ),
    );
  }
}
