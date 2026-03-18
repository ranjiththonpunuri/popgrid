import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:popgrid/core/services/ad_service.dart';
import 'package:popgrid/core/services/auth_service.dart';
import 'package:popgrid/core/theme/app_colors.dart';
import 'package:popgrid/features/game/bloc/game_bloc.dart';
import 'package:popgrid/features/game/bloc/game_event.dart';
import 'package:popgrid/features/game/screens/game_screen.dart';
import 'package:popgrid/features/online/bloc/online_lobby_bloc.dart';
import 'package:popgrid/features/online/bloc/online_lobby_event.dart';
import 'package:popgrid/features/online/bloc/online_lobby_state.dart';
import 'package:popgrid/features/online/services/online_game_controller.dart';
import 'package:popgrid/features/online/services/online_game_service.dart';

class OnlineLobbyScreen extends StatefulWidget {
  /// If true, auto-start quick match on open.
  final bool quickMatch;

  const OnlineLobbyScreen({super.key, this.quickMatch = false});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController(text: 'Player');
  final _codeController = TextEditingController();
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.quickMatch ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnlineLobbyBloc(
        onlineService: GetIt.I<OnlineGameService>(),
        authService: GetIt.I<AuthService>(),
      ),
      child: Builder(
        builder: (context) => BlocListener<OnlineLobbyBloc, OnlineLobbyState>(
          listener: (context, state) {
            if (state is OnlineMatched && !_hasNavigated) {
              _hasNavigated = true;
              _navigateToGame(context, state);
            } else if (state is OnlineLobbyError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 9,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  backgroundColor: AppColors.surfaceLight,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          child: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Top bar
                    Builder(
                      builder: (context) => Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios,
                                color: AppColors.textSecondary, size: 20),
                            onPressed: () {
                              context
                                  .read<OnlineLobbyBloc>()
                                  .add(const LeaveOnlineLobby());
                              Navigator.of(context).pop();
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Online',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppColors.neonPurple,
                                    fontSize: 14,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48), // Balance the back button
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tab bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppColors.neonPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.neonPurple.withValues(alpha: 0.4),
                          ),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: AppColors.neonPurple,
                        unselectedLabelColor: AppColors.textSecondary,
                        labelStyle:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontSize: 9,
                                ),
                        tabs: const [
                          Tab(text: 'Quick Match'),
                          Tab(text: 'Create'),
                          Tab(text: 'Join'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _QuickMatchTab(nameController: _nameController),
                          _CreateTab(nameController: _nameController),
                          _JoinTab(
                            nameController: _nameController,
                            codeController: _codeController,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToGame(BuildContext context, OnlineMatched state) {
    final onlineService = GetIt.I<OnlineGameService>();
    final authService = GetIt.I<AuthService>();
    final bloc = context.read<OnlineLobbyBloc>();
    final gameBloc = GameBloc();
    final localPlayerId = state.isHost ? 1 : 2;

    final controller = OnlineGameController(
      onlineService: onlineService,
      authService: authService,
      gameBloc: gameBloc,
      localPlayerId: localPlayerId,
      gameId: state.gameId,
    );

    final hostName = state.isHost ? bloc.localPlayerName : state.opponentName;
    final joinerName =
        state.isHost ? state.opponentName : bloc.localPlayerName;

    // Start game with synced board seed
    gameBloc.add(StartGame(
      player1Name: hostName,
      player2Name: joinerName,
      boardSeed: state.boardSeed,
    ));

    controller.startListening();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
          create: (_) => gameBloc,
          child: GameScreen(
            player1Name: hostName,
            player2Name: joinerName,
            onlineController: controller,
            localPlayerId: localPlayerId,
          ),
        ),
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
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

// ─── Quick Match Tab ──────────────────────────────────────────────────────────

class _QuickMatchTab extends StatelessWidget {
  final TextEditingController nameController;

  const _QuickMatchTab({required this.nameController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnlineLobbyBloc, OnlineLobbyState>(
      builder: (context, state) {
        if (state is OnlineSearching) {
          return _buildSearching(context);
        }
        if (state is OnlineMatched) {
          return _buildMatched(context);
        }
        return _buildSetup(context);
      },
    );
  }

  Widget _buildSetup(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonYellow.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.neonYellow.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child:
              const Icon(Icons.flash_on, color: AppColors.neonYellow, size: 36),
        ),
        const SizedBox(height: 24),
        Text(
          'Quick Match',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Find a random opponent online',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
        ),
        const SizedBox(height: 32),
        _NameInput(controller: nameController, color: AppColors.neonYellow),
        const Spacer(),
        _LobbyButton(
          label: 'Find Match',
          icon: Icons.flash_on,
          color: AppColors.neonYellow,
          onTap: () {
            final name = nameController.text.trim();
            context.read<OnlineLobbyBloc>().add(
                  StartQuickMatch(
                      playerName: name.isEmpty ? 'Player' : name),
                );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSearching(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        const _PulsingIcon(icon: Icons.flash_on, color: AppColors.neonYellow),
        const SizedBox(height: 24),
        Text(
          'Finding opponent...',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Searching for available players',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 8,
              ),
        ),
        const Spacer(flex: 2),
        BannerAdWidget(adService: GetIt.I<AdService>()),
        const SizedBox(height: 12),
        _LobbyButton(
          label: 'Cancel',
          icon: Icons.close,
          color: AppColors.textSecondary,
          onTap: () {
            context.read<OnlineLobbyBloc>().add(const CancelSearch());
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMatched(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: AppColors.neonGreen, size: 48),
        const SizedBox(height: 16),
        Text(
          'Match Found!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.neonGreen,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Starting game...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
        ),
      ],
    );
  }
}

// ─── Create Tab ───────────────────────────────────────────────────────────────

class _CreateTab extends StatelessWidget {
  final TextEditingController nameController;

  const _CreateTab({required this.nameController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnlineLobbyBloc, OnlineLobbyState>(
      builder: (context, state) {
        if (state is OnlineGameCreated) {
          return _buildWaiting(context, state);
        }
        if (state is OnlineMatched) {
          return _buildMatched(context);
        }
        return _buildSetup(context);
      },
    );
  }

  Widget _buildSetup(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonPurple.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.neonPurple.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(Icons.add_circle_outline,
              color: AppColors.neonPurple, size: 36),
        ),
        const SizedBox(height: 24),
        Text(
          'Create Room',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share the code with a friend to play',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
        ),
        const SizedBox(height: 32),
        _NameInput(controller: nameController, color: AppColors.neonPurple),
        const Spacer(),
        _LobbyButton(
          label: 'Create Room',
          icon: Icons.add_circle_outline,
          color: AppColors.neonPurple,
          onTap: () {
            final name = nameController.text.trim();
            context.read<OnlineLobbyBloc>().add(
                  CreateOnlineGame(
                      playerName: name.isEmpty ? 'Player' : name),
                );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildWaiting(BuildContext context, OnlineGameCreated state) {
    return Column(
      children: [
        const Spacer(flex: 2),
        const _PulsingIcon(
            icon: Icons.wifi_tethering, color: AppColors.neonPurple),
        const SizedBox(height: 24),
        Text(
          'Waiting for opponent...',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'Share this code:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: state.gameCode));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Code copied!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 9,
                        color: AppColors.textPrimary,
                      ),
                ),
                backgroundColor: AppColors.surfaceLight,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neonPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.neonPurple.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.gameCode,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.neonPurple,
                        fontSize: 28,
                        letterSpacing: 8,
                      ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.copy,
                    color: AppColors.neonPurple.withValues(alpha: 0.6),
                    size: 18),
              ],
            ),
          ),
        ),
        const Spacer(flex: 2),
        BannerAdWidget(adService: GetIt.I<AdService>()),
        const SizedBox(height: 12),
        _LobbyButton(
          label: 'Cancel',
          icon: Icons.close,
          color: AppColors.textSecondary,
          onTap: () {
            context.read<OnlineLobbyBloc>().add(const CancelSearch());
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMatched(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: AppColors.neonGreen, size: 48),
        const SizedBox(height: 16),
        Text(
          'Opponent Joined!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.neonGreen,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Starting game...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
        ),
      ],
    );
  }
}

// ─── Join Tab ─────────────────────────────────────────────────────────────────

class _JoinTab extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController codeController;

  const _JoinTab({
    required this.nameController,
    required this.codeController,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnlineLobbyBloc, OnlineLobbyState>(
      builder: (context, state) {
        if (state is OnlineJoining) {
          return _buildJoining(context);
        }
        if (state is OnlineMatched) {
          return _buildMatched(context);
        }
        return _buildSetup(context);
      },
    );
  }

  Widget _buildSetup(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonGreen.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.neonGreen.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(Icons.login, color: AppColors.neonGreen, size: 36),
        ),
        const SizedBox(height: 24),
        Text(
          'Join Room',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the room code from your friend',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
        ),
        const SizedBox(height: 32),
        _NameInput(controller: nameController, color: AppColors.neonGreen),
        const SizedBox(height: 16),
        // Code input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: TextField(
            controller: codeController,
            maxLength: 4,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  color: AppColors.textPrimary,
                  letterSpacing: 8,
                ),
            decoration: InputDecoration(
              labelText: 'Room Code',
              labelStyle:
                  const TextStyle(color: AppColors.neonGreen, fontSize: 10),
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppColors.neonGreen.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.neonGreen, width: 1.5),
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const Spacer(),
        _LobbyButton(
          label: 'Join Room',
          icon: Icons.login,
          color: AppColors.neonGreen,
          onTap: () {
            final name = nameController.text.trim();
            final code = codeController.text.trim().toUpperCase();
            if (code.length != 4) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Please enter a 4-character room code',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 9,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  backgroundColor: AppColors.surfaceLight,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
              return;
            }
            context.read<OnlineLobbyBloc>().add(
                  JoinOnlineGameByCode(
                    code: code,
                    playerName: name.isEmpty ? 'Player' : name,
                  ),
                );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildJoining(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _PulsingIcon(icon: Icons.login, color: AppColors.neonGreen),
        const SizedBox(height: 24),
        Text(
          'Joining game...',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
        ),
      ],
    );
  }

  Widget _buildMatched(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: AppColors.neonGreen, size: 48),
        const SizedBox(height: 16),
        Text(
          'Joined!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.neonGreen,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Starting game...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
        ),
      ],
    );
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _NameInput extends StatelessWidget {
  final TextEditingController controller;
  final Color color;

  const _NameInput({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: TextField(
        controller: controller,
        maxLength: 12,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              color: AppColors.textPrimary,
            ),
        decoration: InputDecoration(
          labelText: 'Your Name',
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
      ),
    );
  }
}

class _LobbyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LobbyButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 11,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _PulsingIcon({required this.icon, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.1),
            border: Border.all(
              color: widget.color.withValues(alpha: _animation.value * 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.3),
                blurRadius: 20 + (_animation.value * 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(widget.icon, color: widget.color, size: 36),
        );
      },
    );
  }
}
