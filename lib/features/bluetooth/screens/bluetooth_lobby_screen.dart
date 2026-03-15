import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:popgrid/core/theme/app_colors.dart';
import 'package:popgrid/features/bluetooth/bloc/bluetooth_bloc.dart';
import 'package:popgrid/features/bluetooth/bloc/bluetooth_event.dart';
import 'package:popgrid/features/bluetooth/bloc/bluetooth_state.dart';
import 'package:popgrid/features/bluetooth/services/bluetooth_game_controller.dart';
import 'package:popgrid/features/bluetooth/services/permission_service.dart';
import 'package:popgrid/features/game/bloc/game_bloc.dart';
import 'package:popgrid/features/game/bloc/game_event.dart';
import 'package:popgrid/features/game/screens/game_screen.dart';
import 'package:popgrid/features/home/widgets/player_name_dialog.dart';

class BluetoothLobbyScreen extends StatefulWidget {
  const BluetoothLobbyScreen({super.key});

  @override
  State<BluetoothLobbyScreen> createState() => _BluetoothLobbyScreenState();
}

class _BluetoothLobbyScreenState extends State<BluetoothLobbyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController(text: 'Player');
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BluetoothBloc(),
      child: Builder(
        builder: (context) => BlocListener<BluetoothBloc, BluetoothState>(
          listener: (context, state) {
            if (state is BluetoothConnected &&
                state.boardSeed != null &&
                !_hasNavigated) {
              _hasNavigated = true;
              _navigateToGame(context, state);
            } else if (state is BluetoothError) {
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
                                  .read<BluetoothBloc>()
                                  .add(const DisconnectRequested());
                              Navigator.of(context).pop();
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Bluetooth',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppColors.player1,
                                    fontSize: 14,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Local match button
                          IconButton(
                            icon: const Icon(Icons.people_outline,
                                color: AppColors.textSecondary, size: 20),
                            onPressed: () => _startLocalGame(context),
                            tooltip: 'Local Match',
                          ),
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
                          color: AppColors.player1.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.player1.withValues(alpha: 0.4),
                          ),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: AppColors.player1,
                        unselectedLabelColor: AppColors.textSecondary,
                        labelStyle:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontSize: 10,
                                ),
                        tabs: const [
                          Tab(text: 'Host Game'),
                          Tab(text: 'Join Game'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _HostTab(nameController: _nameController),
                          _JoinTab(nameController: _nameController),
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

  void _navigateToGame(BuildContext context, BluetoothConnected state) {
    final btBloc = context.read<BluetoothBloc>();
    final gameBloc = GameBloc();
    final localPlayerId = state.isHost ? 1 : 2;

    final controller = BluetoothGameController(
      btService: btBloc.btService,
      gameBloc: gameBloc,
      localPlayerId: localPlayerId,
    );

    final hostName =
        state.isHost ? btBloc.localPlayerName : state.opponentName;
    final joinerName =
        state.isHost ? state.opponentName : btBloc.localPlayerName;

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
            bluetoothController: controller,
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

  /// Local match flow — same as before (same device, two players).
  void _startLocalGame(BuildContext context) async {
    final navigator = Navigator.of(context);
    final names = await showDialog<({String player1, String player2})>(
      context: context,
      builder: (_) => const PlayerNameDialog(),
    );

    if (names == null) return;

    navigator.push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
          create: (_) => GameBloc(),
          child: GameScreen(
            player1Name: names.player1,
            player2Name: names.player2,
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

// ─── Host Tab ────────────────────────────────────────────────────────────────

class _HostTab extends StatelessWidget {
  final TextEditingController nameController;

  const _HostTab({required this.nameController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BluetoothBloc, BluetoothState>(
      builder: (context, state) {
        if (state is BluetoothHostWaiting) {
          return _buildWaiting(context);
        }
        if (state is BluetoothConnected) {
          return _buildConnected(context);
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
            color: AppColors.player1.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.player1.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(Icons.wifi_tethering,
              color: AppColors.player1, size: 36),
        ),
        const SizedBox(height: 24),
        Text(
          'Host a Game',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Other players nearby will see your game',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
        ),
        const SizedBox(height: 32),
        _NameInput(controller: nameController, label: 'Your Name'),
        const Spacer(),
        _LobbyButton(
          label: 'Start Hosting',
          icon: Icons.wifi_tethering,
          onTap: () => _startHosting(context),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildWaiting(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        const _PulsingIcon(
          icon: Icons.wifi_tethering,
          color: AppColors.player1,
        ),
        const SizedBox(height: 24),
        Text(
          'Waiting for opponent...',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Make sure the other player is searching nearby',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 8,
              ),
        ),
        const Spacer(flex: 2),
        _LobbyButton(
          label: 'Cancel',
          icon: Icons.close,
          color: AppColors.textSecondary,
          onTap: () {
            context.read<BluetoothBloc>().add(const DisconnectRequested());
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildConnected(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: AppColors.neonGreen, size: 48),
        const SizedBox(height: 16),
        Text(
          'Connected!',
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

  Future<void> _startHosting(BuildContext context) async {
    final granted = await PermissionService.requestWithExplanation(context);
    if (!granted || !context.mounted) return;

    final name = nameController.text.trim();
    context.read<BluetoothBloc>().add(
          StartHosting(playerName: name.isEmpty ? 'Host' : name),
        );
  }
}

// ─── Join Tab ────────────────────────────────────────────────────────────────

class _JoinTab extends StatelessWidget {
  final TextEditingController nameController;

  const _JoinTab({required this.nameController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BluetoothBloc, BluetoothState>(
      builder: (context, state) {
        if (state is BluetoothJoinSearching) {
          return _buildSearching(context, state);
        }
        if (state is BluetoothConnecting) {
          return _buildConnecting(context, state);
        }
        if (state is BluetoothConnected) {
          return _buildConnected(context);
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
            color: AppColors.player2.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.player2.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(Icons.search, color: AppColors.player2, size: 36),
        ),
        const SizedBox(height: 24),
        Text(
          'Join a Game',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Find nearby hosts to join their game',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
        ),
        const SizedBox(height: 32),
        _NameInput(controller: nameController, label: 'Your Name'),
        const Spacer(),
        _LobbyButton(
          label: 'Search Nearby',
          icon: Icons.search,
          color: AppColors.player2,
          onTap: () => _startSearching(context),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSearching(BuildContext context, BluetoothJoinSearching state) {
    return Column(
      children: [
        const SizedBox(height: 16),
        if (state.discoveredHosts.isEmpty) ...[
          const Spacer(),
          const _PulsingIcon(icon: Icons.search, color: AppColors.player2),
          const SizedBox(height: 24),
          Text(
            'Searching for hosts...',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure the host has started hosting',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                ),
          ),
          const Spacer(),
        ] else ...[
          Text(
            'Nearby Hosts',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: state.discoveredHosts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final device = state.discoveredHosts[index];
                return _HostTile(
                  device: device,
                  onTap: () {
                    context.read<BluetoothBloc>().add(ConnectToHost(
                          deviceId: device.deviceId,
                          deviceName: device.deviceName,
                        ));
                  },
                );
              },
            ),
          ),
        ],
        _LobbyButton(
          label: 'Cancel',
          icon: Icons.close,
          color: AppColors.textSecondary,
          onTap: () {
            context.read<BluetoothBloc>().add(const StopSearching());
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildConnecting(BuildContext context, BluetoothConnecting state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _PulsingIcon(
            icon: Icons.bluetooth_connected, color: AppColors.player1),
        const SizedBox(height: 24),
        Text(
          'Connecting to ${state.deviceName}...',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
        ),
      ],
    );
  }

  Widget _buildConnected(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: AppColors.neonGreen, size: 48),
        const SizedBox(height: 16),
        Text(
          'Connected!',
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

  Future<void> _startSearching(BuildContext context) async {
    final granted = await PermissionService.requestWithExplanation(context);
    if (!granted || !context.mounted) return;

    final name = nameController.text.trim();
    context.read<BluetoothBloc>().add(
          StartSearching(playerName: name.isEmpty ? 'Player' : name),
        );
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _NameInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _NameInput({required this.controller, required this.label});

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
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.player1, fontSize: 10),
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppColors.player1.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.player1, width: 1.5),
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
    this.color = AppColors.neonGreen,
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

class _HostTile extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;

  const _HostTile({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.player1.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.player1.withValues(alpha: 0.1),
                ),
                child:
                    const Icon(Icons.person, color: AppColors.player1, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 10,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to join',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 8,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.player1.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
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
