import 'package:flutter/material.dart';
import 'package:popgrid/core/theme/app_colors.dart';

class ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const ModeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: Material(
        color: enabled ? AppColors.surface : AppColors.disabledButton,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled ? color.withValues(alpha: 0.5) : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: enabled ? color : AppColors.disabledText,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: enabled ? AppColors.textPrimary : AppColors.disabledText,
                        fontSize: 12,
                      ),
                ),
                const Spacer(),
                if (!enabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.disabledText.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Soon',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 8,
                            color: AppColors.disabledText,
                          ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color.withValues(alpha: 0.5),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
