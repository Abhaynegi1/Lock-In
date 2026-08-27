import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/battle_provider.dart';
import '../providers/timer_provider.dart';
import '../screens/battle_lobby_screen.dart';
import '../utils/app_theme.dart';
import 'doodle_decorations.dart';

class JoinBattleModal extends StatefulWidget {
  const JoinBattleModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const JoinBattleModal(),
    );
  }

  @override
  State<JoinBattleModal> createState() => _JoinBattleModalState();
}

class _JoinBattleModalState extends State<JoinBattleModal> {
  late TextEditingController _nameController;
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final timerProvider = context.read<TimerProvider>();
    _nameController = TextEditingController(text: timerProvider.userName);
    _codeController.addListener(_clearError);
    _nameController.addListener(_clearError);
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_clearError);
    _nameController.removeListener(_clearError);
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter the 6-character room code.');
      return;
    }

    if (code.length != 6) {
      setState(
        () => _errorMessage = 'Room codes must be exactly 6 characters.',
      );
      return;
    }

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your display name.');
      return;
    }

    final battleProvider = context.read<BattleProvider>();
    final timerProvider = context.read<TimerProvider>();

    if (name != timerProvider.userName) {
      await timerProvider.updateUserName(name);
    }

    final success = await battleProvider.joinBattle(
      roomCode: code,
      displayName: name,
      avatar: timerProvider.userAvatar,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context); // close modal
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BattleLobbyScreen()),
        );
      } else {
        final err =
            battleProvider.errorMessage ?? 'Room "$code" does not exist.';
        setState(() => _errorMessage = err);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.background,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    err,
                    style: AppTheme.sansBody(
                      color: AppTheme.background,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.ink, width: 1),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final battleProvider = context.watch<BattleProvider>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppTheme.ink, width: 1.5),
            left: BorderSide(color: AppTheme.ink, width: 1.5),
            right: BorderSide(color: AppTheme.ink, width: 1.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.inkFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                const SparkleDoodle(size: 20, color: AppTheme.ink),
                const SizedBox(width: 8),
                Text(
                  'Join Focus Battle',
                  style: AppTheme.serifHeading(fontSize: 22),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the 6-character room code shared by your friend.',
              style: AppTheme.sansBody(fontSize: 13, color: AppTheme.inkMuted),
            ),
            const SizedBox(height: 20),

            // Room Code Input
            Text('ROOM CODE', style: AppTheme.sansLabel(fontSize: 11)),
            const SizedBox(height: 6),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                LengthLimitingTextInputFormatter(6),
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              style: AppTheme.serifHeading(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 4.0,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. K7XM4P',
                hintStyle: AppTheme.serifHeading(
                  fontSize: 20,
                  color: AppTheme.inkLight,
                  letterSpacing: 2.0,
                ),
                filled: true,
                fillColor: AppTheme.sand,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _errorMessage != null
                        ? AppTheme.errorMuted
                        : AppTheme.ink,
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _errorMessage != null
                        ? AppTheme.errorMuted
                        : AppTheme.ink,
                    width: 1.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Display Name
            Text('YOUR DISPLAY NAME', style: AppTheme.sansLabel(fontSize: 11)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: AppTheme.sansBody(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g. Maya, Sam, Liam',
                hintStyle: AppTheme.sansBody(color: AppTheme.inkLight),
                filled: true,
                fillColor: AppTheme.sand,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.ink, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.ink, width: 1.8),
                ),
              ),
            ),

            // Inline Error Banner Toast
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBEBE8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.errorMuted.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppTheme.errorMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTheme.sansBody(
                          fontSize: 13,
                          color: AppTheme.errorMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Join Button
            TactileButton(
              label: battleProvider.isLoading
                  ? 'Joining Room...'
                  : 'Join Battle Room',
              fillColor: AppTheme.sage,
              height: 52,
              fontSize: 15,
              onTap: battleProvider.isLoading ? () {} : _handleJoin,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
