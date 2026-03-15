import 'package:flutter/material.dart';
import 'package:popgrid/core/theme/app_colors.dart';
import 'package:popgrid/features/bluetooth/services/bluetooth_service.dart';

/// Small colored dot indicating Bluetooth connection status.
/// Green = connected, yellow = reconnecting, red = disconnected.
class ConnectionStatusIndicator extends StatefulWidget {
  final ValueNotifier<BtConnectionState> connectionState;

  const ConnectionStatusIndicator({
    super.key,
    required this.connectionState,
  });

  @override
  State<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<ConnectionStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BtConnectionState>(
      valueListenable: widget.connectionState,
      builder: (context, state, _) {
        final color = switch (state) {
          BtConnectionState.connected => AppColors.neonGreen,
          BtConnectionState.connecting => AppColors.neonYellow,
          BtConnectionState.disconnected => AppColors.player2,
        };

        final label = switch (state) {
          BtConnectionState.connected => 'Connected',
          BtConnectionState.connecting => 'Reconnecting...',
          BtConnectionState.disconnected => 'Disconnected',
        };

        // Only pulse when connected
        final shouldPulse = state == BtConnectionState.connected;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                final opacity = shouldPulse ? _pulseAnimation.value : 1.0;
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: opacity),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: opacity * 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 7,
                    color: color,
                  ),
            ),
          ],
        );
      },
    );
  }
}
