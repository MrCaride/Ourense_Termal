import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/index.dart';
import '../models/reward_model.dart';
import '../models/user_model.dart';
import '../services/reward_service.dart';
import '../services/user_data_service.dart';
import '../theme/index.dart';

class RewardDetailScreen extends StatefulWidget {
  final Reward reward;
  final User user;
  final bool canAfford;
  final bool hasRedeemed;

  const RewardDetailScreen({
    super.key,
    required this.reward,
    required this.user,
    required this.canAfford,
    required this.hasRedeemed,
  });

  @override
  State<RewardDetailScreen> createState() => _RewardDetailScreenState();
}

class _RewardDetailScreenState extends State<RewardDetailScreen> {
  final RewardService _rewardService = RewardService();
  final UserDataService _userDataService = UserDataService();

  bool _isRedeeming = false;
  RedeemedReward? _redeemedReward;

  @override
  void initState() {
    super.initState();
    if (widget.hasRedeemed) {
      _loadRedeemedReward();
    }
  }

  Future<void> _loadRedeemedReward() async {
    try {
      final redeemed = await _rewardService.getUserRedeemedRewards(widget.user.id);
      final found = redeemed.firstWhere(
        (r) => r.rewardId == widget.reward.id && !r.used,
        orElse: () => RedeemedReward(
          id: '',
          rewardId: '',
          couponCode: '',
          redeemedDate: DateTime.now(),
        ),
      );

      if (found.id.isNotEmpty && mounted) {
        setState(() => _redeemedReward = found);
      }
    } catch (_) {
    }
  }

  Color _rewardColor() {
    switch (widget.reward.businessType) {
      case 'spa':
        return AppColors.thermalCool;
      case 'restaurant':
        return AppColors.thermalWarm;
      case 'pastry':
        return AppColors.thermalGold;
      case 'shop':
        return AppColors.accentBlue;
      case 'experience':
        return AppColors.accentPurple;
      default:
        return AppColors.thermalCool;
    }
  }

  IconData _rewardIcon() {
    switch (widget.reward.businessType) {
      case 'spa':
        return Icons.spa;
      case 'restaurant':
        return Icons.restaurant;
      case 'pastry':
        return Icons.cake;
      case 'shop':
        return Icons.store;
      case 'experience':
        return Icons.attractions;
      default:
        return Icons.local_offer;
    }
  }

  Future<void> _redeemReward() async {
    if (!widget.canAfford) {
      _showInsufficientPointsDialog();
      return;
    }

    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    if (!mounted) return;
    setState(() => _isRedeeming = true);

    try {
      final updatedUser = widget.user;
      updatedUser.points -= widget.reward.pointsCost;
      await _userDataService.setUserPoints(updatedUser.id, updatedUser.points);

      final redeemed = await _rewardService.redeemReward(
        widget.user.id,
        widget.reward,
      );

      if (!mounted) return;
      setState(() {
        _redeemedReward = redeemed;
        _isRedeeming = false;
      });

      _showSuccessDialog(redeemed.couponCode);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRedeeming = false);
      _showErrorDialog(e.toString());
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar canje'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿Deseas canjear esta recompensa?'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Costo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.reward.pointsCost} puntos',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Puntos restantes:'),
                    Text(
                      '${widget.user.points - widget.reward.pointsCost}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog(String couponCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 8),
            const Text('¡Recompensa canjeada!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu recompensa ha sido canjeada exitosamente.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Código del cupón:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    couponCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: couponCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Presenta este código en ${widget.reward.businessName} para usar tu recompensa.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientPointsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Puntos insuficientes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No tienes suficientes puntos para esta recompensa.'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Necesitas:'),
                Text(
                  '${widget.reward.pointsCost} puntos',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tienes:'),
                Text(
                  '${widget.user.points} puntos',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Te faltan:'),
                Text(
                  '${widget.reward.pointsCost - widget.user.points} puntos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Sigue haciendo check-ins en puntos termales para ganar más puntos.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text('Hubo un error al canjear la recompensa:\n$error'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _copyCodeToClipboard() {
    if (_redeemedReward != null) {
      Clipboard.setData(ClipboardData(text: _redeemedReward!.couponCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código copiado al portapapeles'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rewardColor = _rewardColor();
    final redeemed = _redeemedReward;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 18),
              title: Text(widget.reward.title),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.reward.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.image_outlined, size: 80, color: AppColors.textDisabled),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xC2000000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 68,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _RewardChip(
                              icon: _rewardIcon(),
                              label: widget.reward.businessName,
                              color: rewardColor,
                            ),
                            _RewardChip(
                              icon: Icons.local_fire_department,
                              label: widget.reward.discount,
                              color: AppColors.thermalGold,
                            ),
                            _RewardChip(
                              icon: Icons.stars_rounded,
                              label: '${widget.reward.pointsCost} pts',
                              color: AppColors.accentPurpleLight,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Canjea una recompensa pensada para acompañar tus rutas termales.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.reward.title,
                          style: AppTypography.displaySmall,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _RewardHighlight(
                        label: widget.reward.discount,
                        color: AppColors.thermalGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.reward.businessName,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          widget.reward.address,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          icon: Icons.stars_rounded,
                          value: '${widget.reward.pointsCost}',
                          label: 'Costo',
                          color: AppColors.thermalGold,
                          highlighted: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatTile(
                          icon: Icons.account_balance_wallet_outlined,
                          value: '${widget.user.points}',
                          label: 'Tus puntos',
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Descripción', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  CustomCard(
                    backgroundColor: AppColors.background,
                    border: Border.all(color: AppColors.borderLight),
                    child: Text(
                      widget.reward.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (widget.reward.validUntil != null) ...[
                    InfoTile(
                      icon: Icons.calendar_month_outlined,
                      title: 'Válido hasta',
                      subtitle: widget.reward.validUntil,
                      iconColor: AppColors.accentBlue,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Text('Términos y condiciones', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  CustomCard(
                    backgroundColor: AppColors.surfaceAlt,
                    border: Border.all(color: AppColors.borderLight),
                    child: Column(
                      children: widget.reward.termsAndConditions
                          .map(
                            (term) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 18,
                                    color: AppColors.thermalCool,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      term,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (redeemed != null) ...[
                    CustomCard(
                      backgroundColor: AppColors.accentGreen.withValues(alpha: 0.08),
                      border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.25)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.check_circle, color: AppColors.accentGreen),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('¡Recompensa canjeada!', style: AppTypography.titleSmall),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Tu cupón ya está activo. Cópialo o muéstralo en el local.',
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Tu código de cupón', style: AppTypography.titleSmall),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    redeemed.couponCode,
                                    style: AppTypography.displaySmall.copyWith(letterSpacing: 3),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: _copyCodeToClipboard,
                                  color: AppColors.thermalCool,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Canjeado el: ${redeemed.redeemedDate.day}/${redeemed.redeemedDate.month}/${redeemed.redeemedDate.year}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ] else if (!widget.hasRedeemed) ...[
                    CustomCard(
                      backgroundColor: widget.canAfford
                          ? AppColors.background
                          : AppColors.accentRed.withValues(alpha: 0.06),
                      border: Border.all(
                        color: widget.canAfford
                            ? AppColors.borderLight
                            : AppColors.accentRed.withValues(alpha: 0.25),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: (widget.canAfford ? AppColors.thermalGold : AppColors.accentRed)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.stars_rounded,
                                  color: widget.canAfford ? AppColors.thermalGold : AppColors.accentRed,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Canje de puntos', style: AppTypography.titleSmall),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      widget.canAfford
                                          ? 'Puedes canjear esta recompensa ahora mismo.'
                                          : 'Te faltan ${widget.reward.pointsCost - widget.user.points} puntos para desbloquearla.',
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: StatTile(
                                  icon: Icons.account_balance_wallet_outlined,
                                  value: '${widget.user.points}',
                                  label: 'Tus puntos',
                                  color: AppColors.accentBlue,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: StatTile(
                                  icon: Icons.local_offer_outlined,
                                  value: '${widget.reward.pointsCost}',
                                  label: 'Costo',
                                  color: AppColors.thermalGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          CustomButton(
                            label: widget.canAfford ? 'Canjear recompensa' : 'Puntos insuficientes',
                            icon: Icons.card_giftcard,
                            isDisabled: !widget.canAfford,
                            isLoading: _isRedeeming,
                            onPressed: _redeemReward,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RewardChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _RewardHighlight extends StatelessWidget {
  final String label;
  final Color color;

  const _RewardHighlight({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.titleSmall.copyWith(color: color),
      ),
    );
  }
}
