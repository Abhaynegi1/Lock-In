import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/timer_provider.dart';
import '../utils/app_theme.dart';
import 'user_avatar.dart';

class AvatarPickerModal extends StatefulWidget {
  final TimerProvider provider;

  const AvatarPickerModal({
    super.key,
    required this.provider,
  });

  static Future<void> show(BuildContext context, TimerProvider provider) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AvatarPickerModal(provider: provider),
    );
  }

  @override
  State<AvatarPickerModal> createState() => _AvatarPickerModalState();
}

class _AvatarPickerModalState extends State<AvatarPickerModal> {
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;

  Future<void> _pickFromGallery() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      // pickImage restricted strictly to photo gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final path = pickedFile.path;
        final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
        const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'bmp'};

        if (allowedExtensions.contains(ext)) {
          await widget.provider.updateUserAvatar(path);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Profile picture updated!',
                  style: AppTheme.sansBody(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.sand,
                  ),
                ),
                backgroundColor: AppTheme.ink,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Only photo files (PNG, JPG, WEBP) are allowed, not documents.',
                  style: AppTheme.sansBody(
                    fontSize: 13,
                    color: AppTheme.sand,
                  ),
                ),
                backgroundColor: AppTheme.errorMuted,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not pick image: $e',
              style: AppTheme.sansBody(
                fontSize: 13,
                color: AppTheme.sand,
              ),
            ),
            backgroundColor: AppTheme.errorMuted,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _selectPreset(String path) async {
    await widget.provider.updateUserAvatar(path);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Default avatar selected!',
            style: AppTheme.sansBody(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.sand,
            ),
          ),
          backgroundColor: AppTheme.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatar = widget.provider.userAvatar;
    final isCustomPhoto = !AppAvatars.isPreset(currentAvatar) &&
        File(currentAvatar).existsSync();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.ink, width: 2),
          left: BorderSide(color: AppTheme.ink, width: 2),
          right: BorderSide(color: AppTheme.ink, width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.inkMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Picture',
                        style: AppTheme.serifHeading(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose an avatar or upload from gallery',
                        style: AppTheme.sansBody(
                          fontSize: 13,
                          color: AppTheme.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.sand,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.ink, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Active Avatar Preview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.sand,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.ink, width: 1.5),
                  boxShadow: AppTheme.smallTactileShadow,
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      avatarPath: currentAvatar,
                      size: 64,
                      borderWidth: 2,
                      showShadow: true,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Profile Picture',
                            style: AppTheme.sansBody(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCustomPhoto
                                ? 'Custom Gallery Photo'
                                : (AppAvatars.presets
                                        .where((p) => p.path == currentAvatar)
                                        .firstOrNull
                                        ?.label ??
                                    'Default Preset'),
                            style: AppTheme.serifHeading(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section 1: Default Avatars
              Text(
                'DEFAULT AVATARS',
                style: AppTheme.sansLabel(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // 2x2 Grid of Default Avatars
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                itemCount: AppAvatars.presets.length,
                itemBuilder: (context, index) {
                  final preset = AppAvatars.presets[index];
                  final isSelected = currentAvatar == preset.path;

                  return GestureDetector(
                    onTap: () => _selectPreset(preset.path),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.peach.withValues(alpha: 0.4)
                            : AppTheme.sand,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.ink
                              : AppTheme.ink.withValues(alpha: 0.4),
                          width: isSelected ? 2.2 : 1.2,
                        ),
                        boxShadow: isSelected
                            ? AppTheme.tactileShadow
                            : AppTheme.smallTactileShadow,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              UserAvatar(
                                avatarPath: preset.path,
                                size: 52,
                                borderWidth: 1.5,
                              ),
                              if (isSelected)
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.sage,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.ink,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            preset.label,
                            style: AppTheme.sansBody(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Section 2: Custom Gallery Photo
              Text(
                'CUSTOM PHOTO',
                style: AppTheme.sansLabel(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _isPicking ? null : _pickFromGallery,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isCustomPhoto
                        ? AppTheme.peach.withValues(alpha: 0.4)
                        : AppTheme.sand,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCustomPhoto
                          ? AppTheme.ink
                          : AppTheme.ink.withValues(alpha: 0.5),
                      width: isCustomPhoto ? 2.0 : 1.2,
                    ),
                    boxShadow: AppTheme.smallTactileShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.ink, width: 1.5),
                        ),
                        child: _isPicking
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.ink,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 24,
                                color: AppTheme.ink,
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose from Gallery',
                              style: AppTheme.sansBody(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select any photo (PNG, JPG, WEBP)',
                              style: AppTheme.sansBody(
                                fontSize: 12,
                                color: AppTheme.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.ink,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
