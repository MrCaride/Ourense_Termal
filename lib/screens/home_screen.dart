import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../components/index.dart';
import '../data/thermal_points_data.dart';
import '../models/thermal_point_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/user_data_service.dart';
import '../theme/index.dart';
import '../widgets/role_based_navigator.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'rewards_screen.dart';
import 'routes_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final UserDataService _userDataService = UserDataService();

  late User _user;
  late List<ThermalPoint> _thermalPoints;
  List<CheckIn> _checkIns = [];
  bool _isLoading = true;
  bool _showHeader = false;
  bool _showGreeting = true;
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (mounted) {
        setState(() {
          _showHeader = true;
        });
      }
    });
    _greetingTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      setState(() {
        _showGreeting = false;
      });
    });
    _initializeData();
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    _user = widget.user;

    if (_user.role != UserRole.user) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _thermalPoints = ThermalPointsData.getThermalPoints();

    try {
      _checkIns = await _userDataService.getUserCheckIns(_user.id);
      _user = await _userDataService.getUserWithStats(_user.id);
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      _checkIns = await _userDataService.getUserCheckIns(_user.id);
      _user = await _userDataService.getUserWithStats(_user.id);
      setState(() {});
    } catch (_) {}
  }

  void _showTutorial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tutorial de la aplicacion'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Registrate o inicia sesion para acceder al contenido.\n\n'
            '2. En Mapa puedes ver puntos termales cercanos y hacer check-in.\n\n'
            '3. En Rutas puedes seguir recorridos y completar objetivos.\n\n'
            '4. Al completar visitas y rutas acumulas puntos y subes de nivel.\n\n'
            '5. En Recompensas puedes canjear tus puntos por beneficios.\n\n'
            '6. En Perfil puedes consultar progreso, nivel e insignias.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showProgressSheet(List<CheckIn> userCheckIns) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'ourense_app_mark',
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [AppColors.thermalCool, AppColors.accentBlue],
                        ),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Tu progreso', style: AppTypography.titleLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              LevelProgressBar(
                currentPoints: _user.points,
                pointsPerLevel: _user.level * 300,
                level: _user.level,
                color: AppColors.thermalWarm,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.workspace_premium_rounded,
                      value: '${_user.badges.length}',
                      label: 'Insignias',
                      color: AppColors.accentPurple,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatTile(
                      icon: Icons.qr_code_scanner_rounded,
                      value: '${userCheckIns.length}',
                      label: 'Check-ins',
                      color: AppColors.thermalCool,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              CustomButton(
                label: 'Cerrar',
                variant: ButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user.role != UserRole.user) {
      return RoleBasedNavigator(user: _user);
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final userCheckIns = _checkIns.where((c) => c.userId == _user.id).toList();
    final levelProgress = _user.getLevelProgress();

    final screens = [
      MapScreen(
        thermalPoints: _thermalPoints,
        user: _user,
        checkIns: userCheckIns,
        onCheckIn: _refreshData,
      ),
      RoutesScreen(
        user: _user,
        onCheckIn: _refreshData,
      ),
      RewardsScreen(
        user: _user,
      ),
      ProfileScreen(
        user: _user,
        checkIns: userCheckIns,
        thermalPoints: _thermalPoints,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF0F9FF),
                  Color(0xFFF8FCFF),
                  Colors.white,
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(_selectedIndex),
              child: screens[_selectedIndex],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: AnimatedOpacity(
                  opacity: _showHeader && _selectedIndex != 3 ? 1 : 0,
                  duration: const Duration(milliseconds: 320),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: -8, end: 0),
                    duration: const Duration(milliseconds: 360),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, value),
                        child: child,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: CustomCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.83),
                          borderRadius: AppRadius.xl,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                          shadows: AppShadows.elevation1,
                          child: Row(
                            children: [
                              Hero(
                                tag: 'ourense_app_mark',
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.thermalCool,
                                        AppColors.accentBlue,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.water_drop_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      child: _showGreeting && _selectedIndex != 3
                                          ? Text(
                                              'Hola, ${_user.name.split(' ').first}',
                                              key: const ValueKey('greeting-visible'),
                                              style: AppTypography.titleSmall,
                                            )
                                          : const SizedBox(
                                              key: ValueKey('greeting-hidden'),
                                              height: 0,
                                            ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Nivel ${_user.level} - ${_user.points} pts',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 110,
                                child: CustomProgressBar(
                                  progress: levelProgress,
                                  height: 8,
                                  foregroundColor: AppColors.thermalWarm,
                                  showPercentage: false,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showProgressSheet(userCheckIns),
                                icon: const Icon(Icons.insights_rounded),
                                tooltip: 'Ver progreso',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showTutorial();
          AppToast.show(
            context,
            message: 'Abriendo guia rapida',
            type: ToastType.info,
          );
        },
        backgroundColor: AppColors.thermalCool,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Ayuda'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.11),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                height: 72,
                indicatorColor: AppColors.thermalCool.withValues(alpha: 0.16),
                backgroundColor: Colors.transparent,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map_rounded),
                    label: 'Mapa',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.route_outlined),
                    selectedIcon: Icon(Icons.route_rounded),
                    label: 'Rutas',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.redeem_outlined),
                    selectedIcon: Icon(Icons.redeem_rounded),
                    label: 'Recompensas',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Perfil',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
