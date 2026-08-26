import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/storage_service.dart';
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
  final Color borderColor;
  final Color? backgroundColor;
  final bool showShadow;
  final List<BoxShadow>? customShadow;

  const UserAvatar({
    super.key,
    required this.avatarPath,
    this.size = 44.0,
    this.borderWidth = 1.5,
    this.borderColor = AppTheme.ink,
    this.backgroundColor,
    this.showShadow = false,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePath = (avatarPath == null || avatarPath!.trim().isEmpty)
        ? StorageService.defaultAvatar
        : avatarPath!.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppTheme.sand,
        border: borderWidth > 0
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: customShadow ?? (showShadow ? AppTheme.tactileShadow : null),
      ),
      child: ClipOval(child: _buildAvatarContent(effectivePath)),
    );
  }

  Widget _buildAvatarContent(String path) {
    if (path.startsWith('assets/') || path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _fallbackIcon(),
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
          errorBuilder: (context, error, stackTrace) => _fallbackSvg(),
        );
      }
    } catch (_) {
      // Fallback
    }

    return _fallbackSvg();
  }

  Widget _fallbackSvg() {
    return SvgPicture.asset(
      StorageService.defaultAvatar,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholderBuilder: (_) => _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Center(
      child: Icon(Icons.person_rounded, size: size * 0.55, color: AppTheme.ink),
    );
  }
}
