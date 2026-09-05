import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/timer_provider.dart';
import '../services/completion_feedback_service.dart';
import '../utils/app_theme.dart';
import '../widgets/avatar_picker_modal.dart';
import '../widgets/cloud_sync_modal.dart';
import '../widgets/doodle_decorations.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Back button and Cloud Sync button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (Navigator.canPop(context))
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.sandColor(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.inkColor(context), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              size: 16,
                              color: AppTheme.text(context),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Back',
                              style: AppTheme.sansBody(
                                context: context,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.text(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Cloud Sync Button
                  GestureDetector(
                    onTap: () => CloudSyncModal.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: auth.isAuthenticated ? AppTheme.sageColor(context) : AppTheme.sandColor(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.inkColor(context), width: 1.2),
                        boxShadow: AppTheme.smallShadow(context),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            auth.isAuthenticated
                                ? Icons.cloud_done_outlined
                                : Icons.cloud_outlined,
                            size: 16,
                            color: AppTheme.text(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            auth.isAuthenticated ? 'Synced' : 'Cloud',
                            style: AppTheme.sansBody(
                              context: context,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.text(context),
                            ),
                          ),
                          if (auth.isSyncing) ...[
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppTheme.text(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Circular Profile Picture and Nickname Section
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Circular PFP with tactile border and edit badge
                    GestureDetector(
                      onTap: () => AvatarPickerModal.show(context, provider),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          UserAvatar(
                            avatarPath: provider.userAvatar,
                            size: 88,
                            borderWidth: 2.0,
                            showShadow: true,
                          ),
                          // Edit badge icon at bottom right
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.peachColor(context),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.inkColor(context),
                                  width: 1.5,
                                ),
                                boxShadow: AppTheme.smallShadow(context),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.edit,
                                  size: 13,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Nickname (Tap to edit)
                    GestureDetector(
                      onTap: () => _showEditNicknameDialog(context, provider),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.userName,
                            style: AppTheme.serifHeading(
                              context: context,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: AppTheme.muted(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quiet deep work club · Member',
                      style: AppTheme.sansBody(
                        context: context,
                        fontSize: 13,
                        color: AppTheme.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: AppTheme.faint(context), thickness: 1),
              const SizedBox(height: 24),

              // Overview Section
              Text('PERSONAL STATS', style: AppTheme.sansLabel(context: context)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ProfileMetricBox(
                      title: 'Current Streak',
                      value: '${provider.currentStreak} days',
                      subtitle: 'Consecutive focus',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProfileMetricBox(
                      title: 'Daily Target',
                      value: provider.dailyGoalMinutes % 60 == 0
                          ? '${provider.dailyGoalMinutes ~/ 60} hours'
                          : '${(provider.dailyGoalMinutes / 60).toStringAsFixed(1)} hours',
                      subtitle: 'Tap to edit goal',
                      isEditable: true,
                      onTap: () =>
                          _showEditDailyTargetDialog(context, provider),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Focus Philosophy / Manifesto
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.sandColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.inkColor(context), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SparkleDoodle(size: 16, color: AppTheme.inkColor(context)),
                        const SizedBox(width: 8),
                        Text(
                          'The Lock In Rule',
                          style: AppTheme.sansBody(
                            context: context,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'One thing at a time. When a session begins, leaving the app forfeits your timer. True focus is unbroken presence.',
                      style: AppTheme.sansBody(
                        context: context,
                        fontSize: 13,
                        color: AppTheme.muted(context),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Accountability Rules
              Text('PREFERENCES', style: AppTheme.sansLabel(context: context)),
              const SizedBox(height: 12),
              _SettingTile(
                title: 'Appearance',
                subtitle: themeProvider.themeMode == ThemeMode.light
                    ? 'Light Mode · Warm paper'
                    : themeProvider.themeMode == ThemeMode.dark
                        ? 'Dark Mode · Deep slate'
                        : 'Follow System Settings · Auto',
                onTap: () => _showThemeModal(context, themeProvider),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      themeProvider.themeMode == ThemeMode.light
                          ? Icons.wb_sunny_outlined
                          : themeProvider.themeMode == ThemeMode.dark
                              ? Icons.dark_mode_outlined
                              : Icons.brightness_auto_outlined,
                      size: 15,
                      color: AppTheme.text(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      themeProvider.themeMode == ThemeMode.light
                          ? 'Light'
                          : themeProvider.themeMode == ThemeMode.dark
                              ? 'Dark'
                              : 'System',
                      style: AppTheme.sansBody(
                        context: context,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _SettingTile(
                title: 'Strict anti-distraction',
                subtitle: provider.isStrictAntiDistraction
                    ? 'Screen kept awake · Ends if you leave app'
                    : 'Session continues when leaving app',
                onTap: () => _showAntiDistractionModal(context, provider),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: provider.isStrictAntiDistraction
                        ? AppTheme.sageColor(context)
                        : AppTheme.sandColor(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: provider.isStrictAntiDistraction
                          ? AppTheme.inkColor(context)
                          : AppTheme.lightColor(context),
                      width: 1.2,
                    ),
                    boxShadow: provider.isStrictAntiDistraction
                        ? AppTheme.smallShadow(context)
                        : null,
                  ),
                  child: Text(
                    provider.isStrictAntiDistraction ? 'ACTIVE' : 'INACTIVE',
                    style: AppTheme.sansLabel(
                      context: context,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: provider.isStrictAntiDistraction
                          ? AppTheme.text(context)
                          : AppTheme.muted(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _SettingTile(
                title: 'Finish cue',
                subtitle: _getFinishCueSubtitle(provider),
                onTap: () => _showFinishCueModal(context, provider),
                trailing: Text(
                  _getFinishCueTrailing(provider),
                  style: AppTheme.sansBody(
                    context: context,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNicknameDialog(BuildContext context, TimerProvider provider) {
    final controller = TextEditingController(text: provider.userName);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.bg(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.inkColor(context), width: 1.5),
              boxShadow: AppTheme.shadow(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Nickname',
                      style: AppTheme.serifHeading(
                        context: context,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: AppTheme.muted(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you appear in Focus Battles and club logs:',
                  style: AppTheme.sansBody(
                    context: context,
                    fontSize: 13,
                    color: AppTheme.muted(context),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: AppTheme.sansBody(
                    context: context,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Focus Monk, Neo...',
                    filled: true,
                    fillColor: AppTheme.sandColor(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppTheme.inkColor(context),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppTheme.inkColor(context),
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TactileButton(
                        label: 'Cancel',
                        fillColor: AppTheme.sandColor(context),
                        textColor: AppTheme.text(context),
                        height: 46,
                        borderRadius: 12,
                        fontSize: 14,
                        onTap: () => Navigator.pop(dialogCtx),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TactileButton(
                        label: 'Save',
                        fillColor: AppTheme.peachColor(context),
                        textColor: AppTheme.ink,
                        height: 46,
                        borderRadius: 12,
                        fontSize: 14,
                        onTap: () {
                          provider.updateUserName(controller.text);
                          Navigator.pop(dialogCtx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeModal(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.bg(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppTheme.inkColor(context), width: 1.5),
            boxShadow: AppTheme.shadow(context),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.lightColor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appearance',
                      style: AppTheme.serifHeading(
                        context: context,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetCtx),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: AppTheme.muted(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose your preferred theme or match your device settings:',
                  style: AppTheme.sansBody(
                    context: context,
                    fontSize: 13,
                    color: AppTheme.muted(context),
                  ),
                ),
                const SizedBox(height: 20),

                // Option 1: Light Mode (Default)
                _AntiDistractionOptionCard(
                  title: 'Light Mode',
                  subtitle:
                      'Warm paper off-white with crisp black ink and tactile shadows.',
                  badgeText: 'DEFAULT',
                  badgeColor: AppTheme.peachColor(context),
                  isSelected: themeProvider.themeMode == ThemeMode.light,
                  icon: Icons.wb_sunny_outlined,
                  onTap: () {
                    themeProvider.setThemeMode(ThemeMode.light);
                    Navigator.pop(sheetCtx);
                  },
                ),
                const SizedBox(height: 12),

                // Option 2: Dark Mode
                _AntiDistractionOptionCard(
                  title: 'Dark Mode',
                  subtitle:
                      'Deep charcoal slate paper tone designed for low-light night focus.',
                  badgeText: 'NIGHT',
                  badgeColor: AppTheme.sandColor(context),
                  isSelected: themeProvider.themeMode == ThemeMode.dark,
                  icon: Icons.dark_mode_outlined,
                  onTap: () {
                    themeProvider.setThemeMode(ThemeMode.dark);
                    Navigator.pop(sheetCtx);
                  },
                ),
                const SizedBox(height: 12),

                // Option 3: Follow System Settings
                _AntiDistractionOptionCard(
                  title: 'Follow System Settings',
                  subtitle:
                      'Automatically switch theme based on your device system appearance.',
                  badgeText: 'AUTO',
                  badgeColor: AppTheme.sageColor(context),
                  isSelected: themeProvider.themeMode == ThemeMode.system,
                  icon: Icons.brightness_auto_outlined,
                  onTap: () {
                    themeProvider.setThemeMode(ThemeMode.system);
                    Navigator.pop(sheetCtx);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAntiDistractionModal(BuildContext context, TimerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.bg(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppTheme.inkColor(context), width: 1.5),
            boxShadow: AppTheme.shadow(context),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.lightColor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Anti-Distraction Mode',
                      style: AppTheme.serifHeading(
                        context: context,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetCtx),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: AppTheme.muted(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose what happens when you leave Lock In during a session:',
                  style: AppTheme.sansBody(
                    context: context,
                    fontSize: 13,
                    color: AppTheme.muted(context),
                  ),
                ),
                const SizedBox(height: 20),

                // Option 1: ACTIVE
                _AntiDistractionOptionCard(
                  title: 'Active (Strict)',
                  subtitle:
                      'Session ends immediately if you leave the app. Screen stays awake while focusing to prevent phone sleep.',
                  badgeText: 'STRICT',
                  badgeColor: AppTheme.sageColor(context),
                  isSelected: provider.isStrictAntiDistraction,
                  icon: Icons.shield_outlined,
                  onTap: () {
                    provider.setStrictAntiDistraction(true);
                    Navigator.pop(sheetCtx);
                  },
                ),
                const SizedBox(height: 12),

                // Option 2: INACTIVE
                _AntiDistractionOptionCard(
                  title: 'Inactive (Flexible)',
                  subtitle:
                      'You can leave the app to take notes or check messages; the session continues running quietly.',
                  badgeText: 'FLEXIBLE',
                  badgeColor: AppTheme.sandColor(context),
                  isSelected: !provider.isStrictAntiDistraction,
                  icon: Icons.timer_outlined,
                  onTap: () {
                    provider.setStrictAntiDistraction(false);
                    Navigator.pop(sheetCtx);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFinishCueSubtitle(TimerProvider provider) {
    if (provider.finishCueMode == 'haptics_only') {
      return 'Library Mode (Vibration only)';
    } else if (provider.finishCueMode == 'silent') {
      return 'Off · No completion cue';
    }
    final presetName = provider.finishCuePreset == 'warm_tone'
        ? 'Warm Tone'
        : provider.finishCuePreset == 'gentle_chime'
            ? 'Gentle Chime'
            : 'Soft Bell';
    return '$presetName · Sound + Haptics';
  }

  String _getFinishCueTrailing(TimerProvider provider) {
    if (provider.finishCueMode == 'haptics_only') {
      return 'Library';
    } else if (provider.finishCueMode == 'silent') {
      return 'Off';
    }
    return 'On';
  }

  void _showFinishCueModal(BuildContext context, TimerProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentMode = provider.finishCueMode;
            final currentPreset = provider.finishCuePreset;

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: AppTheme.bg(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppTheme.inkColor(context), width: 1.5),
                boxShadow: AppTheme.shadow(context),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.lightColor(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Finish Cue',
                          style: AppTheme.serifHeading(
                            context: context,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(sheetCtx),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: AppTheme.muted(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'How should LockIn let you know your session is complete?',
                      style: AppTheme.sansBody(
                        context: context,
                        fontSize: 13,
                        color: AppTheme.muted(context),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Mode 1: Sound + Haptics
                    _AntiDistractionOptionCard(
                      title: 'Sound + Haptics',
                      subtitle:
                          'Soft acoustic acknowledgment and subtle vibration.',
                      badgeText: 'CHIME',
                      badgeColor: AppTheme.sandColor(context),
                      isSelected: currentMode == 'sound_and_haptics',
                      icon: Icons.volume_up_outlined,
                      onTap: () {
                        provider.setFinishCueMode('sound_and_haptics');
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 12),

                    // Mode 2: Vibration Only (Library Mode)
                    _AntiDistractionOptionCard(
                      title: 'Vibration Only',
                      subtitle:
                          'Completely silent. Subtle double pulse for study halls and cafes.',
                      badgeText: 'LIBRARY',
                      badgeColor: AppTheme.sandColor(context),
                      isSelected: currentMode == 'haptics_only',
                      icon: Icons.vibration_outlined,
                      onTap: () {
                        provider.setFinishCueMode('haptics_only');
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 12),

                    // Mode 3: Silent (Off)
                    _AntiDistractionOptionCard(
                      title: 'Silent (Off)',
                      subtitle:
                          'Pure visual transition. No audio or haptic trigger.',
                      badgeText: 'DEFAULT',
                      badgeColor: AppTheme.sageColor(context),
                      isSelected: currentMode == 'silent',
                      icon: Icons.volume_off_outlined,
                      onTap: () {
                        provider.setFinishCueMode('silent');
                        setModalState(() {});
                      },
                    ),

                    // Sound Selector (visible when sound is enabled)
                    if (currentMode == 'sound_and_haptics') ...[
                      const SizedBox(height: 24),
                      Text(
                        'CUE TONE',
                        style: AppTheme.sansLabel(context: context, fontSize: 10),
                      ),
                      const SizedBox(height: 12),
                      _SoundPresetTile(
                        title: 'Soft Bell',
                        subtitle: 'Warm harmonic bell with natural decay',
                        isSelected: currentPreset == 'soft_bell',
                        onSelect: () {
                          provider.setFinishCuePreset('soft_bell');
                          setModalState(() {});
                        },
                        onPreview: () {
                          DefaultCompletionFeedbackService()
                              .previewPreset('soft_bell');
                        },
                      ),
                      const SizedBox(height: 8),
                      _SoundPresetTile(
                        title: 'Warm Tone',
                        subtitle: 'Deep acoustic wooden resonance',
                        isSelected: currentPreset == 'warm_tone',
                        onSelect: () {
                          provider.setFinishCuePreset('warm_tone');
                          setModalState(() {});
                        },
                        onPreview: () {
                          DefaultCompletionFeedbackService()
                              .previewPreset('warm_tone');
                        },
                      ),
                      const SizedBox(height: 8),
                      _SoundPresetTile(
                        title: 'Gentle Chime',
                        subtitle: 'Delicate acoustic chime tone',
                        isSelected: currentPreset == 'gentle_chime',
                        onSelect: () {
                          provider.setFinishCuePreset('gentle_chime');
                          setModalState(() {});
                        },
                        onPreview: () {
                          DefaultCompletionFeedbackService()
                              .previewPreset('gentle_chime');
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDailyTargetDialog(
    BuildContext context,
    TimerProvider provider,
  ) {
    int targetMinutes = provider.dailyGoalMinutes;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hours = targetMinutes ~/ 60;
            final mins = targetMinutes % 60;
            final displayText = mins > 0
                ? '${hours}h ${mins}m'
                : '$hours hours';

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.bg(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.inkColor(context), width: 1.5),
                  boxShadow: AppTheme.shadow(context),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Focus Goal',
                          style: AppTheme.serifHeading(
                            context: context,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogCtx),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: AppTheme.muted(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'How many hours of deep work would you like to target each day?',
                      style: AppTheme.sansBody(
                        context: context,
                        fontSize: 13,
                        color: AppTheme.muted(context),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Preset Chips (1h, 2h, 3h, 4h, 6h, 8h)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [1, 2, 3, 4, 6, 8].map((h) {
                        final isSelected = targetMinutes == h * 60;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              targetMinutes = h * 60;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.peachColor(context)
                                  : AppTheme.sandColor(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.inkColor(context),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? AppTheme.smallShadow(context)
                                  : null,
                            ),
                            child: Text(
                              '${h}h',
                              style: AppTheme.sansBody(
                                context: context,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? AppTheme.ink : AppTheme.text(context),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Stepper (- and +)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.sandColor(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.inkColor(context), width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (targetMinutes > 30) {
                                setDialogState(() {
                                  targetMinutes -= 30;
                                });
                              }
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.bg(context),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.inkColor(context),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 18,
                                color: AppTheme.text(context),
                              ),
                            ),
                          ),
                          Text(
                            displayText,
                            style: AppTheme.serifHeading(
                              context: context,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (targetMinutes < 720) {
                                setDialogState(() {
                                  targetMinutes += 30;
                                });
                              }
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.bg(context),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.inkColor(context),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 18,
                                color: AppTheme.text(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: TactileButton(
                            label: 'Cancel',
                            fillColor: AppTheme.sandColor(context),
                            textColor: AppTheme.text(context),
                            height: 46,
                            borderRadius: 12,
                            fontSize: 14,
                            onTap: () => Navigator.pop(dialogCtx),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TactileButton(
                            label: 'Save Target',
                            fillColor: AppTheme.peachColor(context),
                            textColor: AppTheme.ink,
                            height: 46,
                            borderRadius: 12,
                            fontSize: 14,
                            onTap: () {
                              provider.updateDailyGoalMinutes(targetMinutes);
                              Navigator.pop(dialogCtx);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AntiDistractionOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _AntiDistractionOptionCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.sandColor(context) : AppTheme.bg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.inkColor(context),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected ? AppTheme.smallShadow(context) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.bg(context) : AppTheme.sandColor(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.inkColor(context), width: 1.2),
              ),
              child: Icon(icon, size: 20, color: AppTheme.text(context)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTheme.sansBody(
                          context: context,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.text(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.inkColor(context), width: 1),
                        ),
                        child: Text(
                          badgeText,
                          style: AppTheme.sansLabel(
                            context: context,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.sansBody(
                      context: context,
                      fontSize: 12,
                      color: AppTheme.muted(context),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.peachColor(context) : Colors.transparent,
                border: Border.all(color: AppTheme.inkColor(context), width: 1.5),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: AppTheme.ink)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMetricBox extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isEditable;

  const _ProfileMetricBox({
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.inkColor(context), width: 1.2),
          boxShadow: isEditable ? AppTheme.smallShadow(context) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTheme.sansLabel(
                    context: context,
                    fontSize: 10,
                    color: AppTheme.muted(context),
                  ),
                ),
                if (isEditable)
                  Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: AppTheme.muted(context),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTheme.serifHeading(
                context: context,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.sansBody(context: context, fontSize: 11, color: AppTheme.lightColor(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bg(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.faint(context), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.sansBody(
                      context: context,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.sansBody(
                      context: context,
                      fontSize: 12,
                      color: AppTheme.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _SoundPresetTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  const _SoundPresetTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onSelect,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.sandColor(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.inkColor(context) : AppTheme.lightColor(context),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: isSelected ? AppTheme.text(context) : AppTheme.muted(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.sansBody(
                      context: context,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.sansBody(
                      context: context,
                      fontSize: 11,
                      color: AppTheme.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onPreview,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.bg(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.inkColor(context), width: 1),
                  boxShadow: AppTheme.smallShadow(context),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded,
                        size: 14, color: AppTheme.text(context)),
                    const SizedBox(width: 4),
                    Text(
                      'Preview',
                      style: AppTheme.sansLabel(
                          context: context,
                          fontSize: 9, color: AppTheme.text(context)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
