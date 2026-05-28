import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/thermal_point_model.dart';
import '../data/badges_data.dart';
import '../services/auth_service.dart';
import '../components/index.dart';
import '../theme/index.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final User user;
  final List<CheckIn> checkIns;
  final List<ThermalPoint> thermalPoints;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.checkIns,
    required this.thermalPoints,
  });

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AuthService().logout();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Vas a borrar tu cuenta y todos tus datos asociados. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentRed),
            child: const Text('Borrar cuenta'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) {
      return;
    }

    try {
      await AuthService().deleteCurrentAccount();
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allBadges = BadgesData.getBadgeDefinitions();
    final unlockedIds = user.badges.map((b) => b.id).toSet();

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text('Perfil'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmAndLogout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: CustomCard(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.thermalCool, AppColors.accentBlue, AppColors.thermalWarm],
                ),
                borderRadius: AppRadius.xl,
                shadows: AppShadows.elevation3,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        child: CircleAvatar(radius: 32, backgroundColor: Colors.white, child: Icon(Icons.person, size: 34, color: AppColors.thermalCool)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: AppTypography.titleLarge.copyWith(color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(user.email, style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.82))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Nivel ${user.level}', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomProgressBar(progress: user.getLevelProgress(), foregroundColor: Colors.white, backgroundColor: Colors.white.withValues(alpha: 0.2), height: 8),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(user.getLevelTitle(), style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.82))),
                      Text('${user.getPointsToNextLevel()} pts para subir', style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.82))),
                    ],
                  ),
                ],
              ),
              ),
            ),
          ),
          // Nivel y progreso
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.thermalGold),
                              const SizedBox(width: 8),
                              Text('Nivel ${user.level}', style: AppTypography.titleSmall),
                            ],
                          ),
                          Text(
                            user.getLevelTitle(),
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomProgressBar(progress: user.getLevelProgress(), foregroundColor: AppColors.thermalGold, backgroundColor: AppColors.surfaceAlt, height: 8),
                      const SizedBox(height: 8),
                      Text('${user.getPointsToNextLevel()} puntos para nivel ${user.level + 1}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  StatTile(icon: Icons.stars_rounded, value: user.points.toString(), label: 'Puntos', color: AppColors.thermalWarm),
                  StatTile(icon: Icons.location_on_rounded, value: checkIns.length.toString(), label: 'Visitas', color: AppColors.thermalCool),
                  StatTile(icon: Icons.verified_rounded, value: user.badges.length.toString(), label: 'Insignias', color: AppColors.accentPurple),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: CustomCard(
                backgroundColor: const Color(0xFFFFF5F5),
                border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.35)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accentRed.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete_forever_rounded, color: AppColors.accentRed),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Eliminar cuenta', style: AppTypography.titleSmall.copyWith(color: AppColors.accentRed)),
                                const SizedBox(height: 4),
                                Text(
                                  'Borra tu perfil, puntos, insignias y check-ins asociados.',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _confirmAndDeleteAccount(context),
                          icon: const Icon(Icons.delete_forever_rounded),
                          label: const Text('Eliminar mi cuenta'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 16)),
          // Insignias
          if (user.badges.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Insignias Recientes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          if (user.badges.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final badge = user.badges[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: CustomCard(
                      border: Border.all(color: AppColors.thermalGold),
                      child: Row(
                          children: [
                            Text(badge.icon, style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(badge.name, style: AppTypography.titleSmall),
                                  Text(badge.description, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ),
                  );
                },
                childCount: user.badges.length,
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Todas las insignias',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final badge = allBadges[index];
                  final unlocked = unlockedIds.contains(badge.id);
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(badge.name),
                          content: Text(
                            '${badge.description}\n\n'
                            'Estado: ${unlocked ? 'Desbloqueada' : 'No desbloqueada'}\n'
                            'Puntos: ${badge.points}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: unlocked ? Colors.green : Colors.grey[300]!,
                        ),
                        color: unlocked ? Colors.green[50] : Colors.grey[100],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            unlocked ? badge.icon : '🔒',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            badge.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: unlocked ? Colors.black : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: allBadges.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 16)),
          // Botón de logout
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () => _confirmAndLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.accentRed),
                  foregroundColor: AppColors.accentRed,
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppTheme.brandTeal),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
