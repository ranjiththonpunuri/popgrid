import 'package:flutter/material.dart';
import 'package:popgrid/core/constants/app_constants.dart';
import 'package:popgrid/core/theme/app_colors.dart';
import 'package:popgrid/features/bluetooth/screens/bluetooth_lobby_screen.dart';
import 'package:popgrid/features/home/widgets/mode_button.dart';
import 'package:popgrid/features/home/widgets/how_to_play_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: AppColors.textSecondary, size: 22),
                  onPressed: () => _showSettingsPlaceholder(context),
                ),
              ),
              const Spacer(flex: 2),
              // Animated Logo / Title
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.neonGreen,
                          fontSize: 36,
                          shadows: [
                            Shadow(
                              color: AppColors.neonGreen
                                  .withValues(alpha: _glowAnimation.value),
                              blurRadius: 20 + (_glowAnimation.value * 15),
                            ),
                            Shadow(
                              color: AppColors.player1
                                  .withValues(alpha: _glowAnimation.value * 0.3),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Line up. Flip. Dominate.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
              ),
              const Spacer(flex: 2),
              // Mode buttons
              ModeButton(
                label: 'Bluetooth',
                icon: Icons.bluetooth,
                color: AppColors.player1,
                enabled: true,
                onTap: () => _navigateToBluetoothLobby(context),
              ),
              const SizedBox(height: 16),
              ModeButton(
                label: 'Quick Match',
                icon: Icons.flash_on,
                color: AppColors.neonYellow,
                enabled: false,
                onTap: () => _showComingSoon(context, 'Quick Match'),
              ),
              const SizedBox(height: 16),
              ModeButton(
                label: 'Online',
                icon: Icons.public,
                color: AppColors.neonPurple,
                enabled: false,
                onTap: () => _showComingSoon(context, 'Online'),
              ),
              const Spacer(),
              // How to Play
              TextButton.icon(
                onPressed: () => _showHowToPlay(context),
                icon: const Icon(
                    Icons.help_outline, color: AppColors.textSecondary),
                label: Text(
                  'How to Play',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 10,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'v${AppConstants.appVersion}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 7,
                      color: AppColors.disabledText,
                    ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToBluetoothLobby(BuildContext context) {
    Navigator.of(context).push(_buildSlideRoute(const BluetoothLobbyScreen()));
  }

  void _showComingSoon(BuildContext context, String mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$mode is coming soon!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 9,
                color: AppColors.textPrimary,
              ),
        ),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSettingsPlaceholder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.neonGreen,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 24),
            _SettingsRow(
              icon: Icons.volume_up,
              label: 'Sound',
              trailing: Switch(
                value: false,
                onChanged: null,
                activeThumbColor: AppColors.neonGreen,
              ),
            ),
            _SettingsRow(
              icon: Icons.vibration,
              label: 'Haptics',
              trailing: Switch(
                value: false,
                onChanged: null,
                activeThumbColor: AppColors.neonGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'More settings coming soon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 8,
                    color: AppColors.disabledText,
                  ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  PageRouteBuilder _buildSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => const HowToPlaySheet(),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
          ),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}
