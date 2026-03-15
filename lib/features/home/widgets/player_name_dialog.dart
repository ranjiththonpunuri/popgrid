import 'package:flutter/material.dart';
import 'package:popgrid/core/theme/app_colors.dart';

class PlayerNameDialog extends StatefulWidget {
  const PlayerNameDialog({super.key});

  @override
  State<PlayerNameDialog> createState() => _PlayerNameDialogState();
}

class _PlayerNameDialogState extends State<PlayerNameDialog> {
  final _player1Controller = TextEditingController(text: 'Player 1');
  final _player2Controller = TextEditingController(text: 'Player 2');
  final _player1Focus = FocusNode();
  final _player2Focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Select all text when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _player1Focus.requestFocus();
      _player1Controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _player1Controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    _player1Focus.dispose();
    _player2Focus.dispose();
    super.dispose();
  }

  void _submit() {
    final p1 = _player1Controller.text.trim();
    final p2 = _player2Controller.text.trim();
    Navigator.of(context).pop((
      player1: p1.isEmpty ? 'Player 1' : p1,
      player2: p2.isEmpty ? 'Player 2' : p2,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.player1.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Players',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.neonGreen,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 24),
            _NameField(
              controller: _player1Controller,
              focusNode: _player1Focus,
              label: 'Player 1',
              color: AppColors.player1,
              onSubmitted: (_) => _player2Focus.requestFocus(),
            ),
            const SizedBox(height: 16),
            _NameField(
              controller: _player2Controller,
              focusNode: _player2Focus,
              label: 'Player 2',
              color: AppColors.player2,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Cancel',
                    color: AppColors.textSecondary,
                    filled: false,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: 'Start',
                    color: AppColors.neonGreen,
                    filled: true,
                    onTap: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final Color color;
  final ValueChanged<String> onSubmitted;

  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.color,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLength: 12,
      textInputAction: TextInputAction.next,
      onSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 11,
            color: AppColors.textPrimary,
          ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color, fontSize: 10),
        counterText: '',
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: filled ? 0.6 : 0.3),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 10,
                color: color,
              ),
        ),
      ),
    );
  }
}
