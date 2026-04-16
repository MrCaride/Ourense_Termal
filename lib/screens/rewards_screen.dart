import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/index.dart';
import '../models/reward_model.dart';
import '../models/user_model.dart';
import '../services/reward_service.dart';
import '../services/user_data_service.dart';
import '../theme/index.dart';

class RewardsScreen extends StatefulWidget {
  final User user;

  const RewardsScreen({super.key, required this.user});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final RewardService _rewardService = RewardService();
  final UserDataService _userDataService = UserDataService();

  late User _user;
  List<Reward> _allRewards = [];
  List<Reward> _displayedRewards = [];
  List<RedeemedReward> _redeemedRewards = [];
  String _selectedFilter = 'all';
  bool _isLoading = true;

  final Map<String, String> _filterLabels = {
    'all': 'Todas',
    'spa': 'Termas',
    'pastry': 'Panaderías',
    'restaurant': 'Restaurantes',
    'shop': 'Tiendas',
    'experience': 'Experiencias',
  };

  final Map<String, IconData> _filterIcons = {
    'all': Icons.grid_view_rounded,
    'spa': Icons.hot_tub_rounded,
    'pastry': Icons.bakery_dining_rounded,
    'restaurant': Icons.restaurant_rounded,
    'shop': Icons.shopping_bag_rounded,
    'experience': Icons.explore_rounded,
  };

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _user = await _userDataService.getUserWithStats(_user.id);
      _allRewards = RewardService.getAvailableRewards();
      _displayedRewards = _allRewards;
      _redeemedRewards = await _rewardService.getUserRedeemedRewards(_user.id);
      setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _displayedRewards = RewardService.filterRewardsByType(filter);
    });
  }

  bool _canAfford(Reward reward) {
    return _user.points >= reward.pointsCost;
  }

  bool _hasRedeemed(Reward reward) {
    return _redeemedRewards.any((r) => r.rewardId == reward.id && !r.used);
  }

  Future<void> _showRewardDetails(Reward reward) async {
    final didChange = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.55,
          maxChildSize: 0.97,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: _RewardDetailPanel(
                  reward: reward,
                  user: _user,
                  canAfford: _canAfford(reward),
                  hasRedeemed: _hasRedeemed(reward),
                  onClosed: () => Navigator.pop(context),
                  onChanged: () => Navigator.pop(context, true),
                ),
              ),
            );
          },
        );
      },
    );

    if (didChange == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Recompensas'),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildPointsHeader(),
                  _buildFilterChips(),
                  if (_displayedRewards.isEmpty)
                    _buildEmptyState()
                  else
                    ..._displayedRewards.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          entry.key == 0 ? AppSpacing.sm : AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: AnimatedListItem(
                          index: entry.key,
                          delay: Duration(milliseconds: 50 * entry.key),
                          child: _buildRewardCard(entry.value),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
    );
  }

  Widget _buildPointsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: CustomCard(
        gradient: const LinearGradient(
          colors: [AppColors.thermalCool, AppColors.accentBlue, AppColors.thermalWarm],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.xl,
        padding: const EdgeInsets.all(AppSpacing.xl),
        shadows: AppShadows.elevation3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu cartera termal', style: AppTypography.titleLarge.copyWith(color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('Nivel ${_user.level} · ${_user.getLevelTitle()}', style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.84))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_user.points}',
                  style: AppTypography.displayLarge.copyWith(color: Colors.white, height: 0.95),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('puntos', style: AppTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.88))),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            CustomProgressBar(
              progress: _user.getLevelProgress(),
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              height: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterLabels.entries.map((entry) {
            final isSelected = _selectedFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_filterIcons[entry.key], size: 18),
                    const SizedBox(width: 6),
                    Text(entry.value),
                  ],
                ),
                selectedColor: AppColors.thermalCool,
                backgroundColor: Colors.white,
                labelStyle: AppTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                side: BorderSide(color: isSelected ? AppColors.thermalCool : AppColors.border),
                onSelected: (_) => _applyFilter(entry.key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRewardCard(Reward reward) {
    final canAfford = _canAfford(reward);
    final hasRedeemed = _hasRedeemed(reward);

    return CustomCard(
      borderRadius: AppRadius.xl,
      padding: EdgeInsets.zero,
      shadows: AppShadows.elevation2,
      onTap: () => _showRewardDetails(reward),
      isClickable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            child: Stack(
              children: [
                Image.network(
                  reward.imageUrl,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 190,
                    color: AppColors.surfaceAlt,
                    child: const Icon(Icons.image_rounded, size: 50, color: AppColors.textHint),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.52),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _BadgePill(
                    icon: _filterIcons[reward.businessType] ?? Icons.local_offer_rounded,
                    label: _filterLabels[reward.businessType] ?? '',
                  ),
                ),
                if (hasRedeemed)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _BadgePill(
                      icon: Icons.check_circle_rounded,
                      label: 'Canjeado',
                      color: AppColors.accentGreen,
                    ),
                  ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          reward.title,
                          style: AppTypography.titleLarge.copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          reward.discount,
                          style: AppTypography.labelSmall.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.businessName, style: AppTypography.labelLarge),
                const SizedBox(height: AppSpacing.md),
                Text(
                  reward.description,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        reward.address,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.stars_rounded, color: canAfford ? AppColors.thermalGold : AppColors.textDisabled, size: 24),
                        const SizedBox(width: 6),
                        Text(
                          '${reward.pointsCost} puntos',
                          style: AppTypography.titleSmall.copyWith(
                            color: canAfford ? AppColors.thermalCool : AppColors.textDisabled,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    CustomButton(
                      label: hasRedeemed ? 'Ver cupón' : 'Canjear',
                      size: ButtonSize.medium,
                      backgroundColor: hasRedeemed
                          ? AppColors.accentGreen
                          : canAfford
                              ? AppColors.thermalCool
                              : AppColors.textDisabled,
                      onPressed: () => _showRewardDetails(reward),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: EmptyState(
        icon: Icons.card_giftcard_rounded,
        title: 'No hay recompensas en esta categoría',
        description: 'Cambia el filtro o vuelve más tarde para descubrir nuevas opciones.',
        iconColor: AppColors.thermalCool,
      ),
    );
  }
}

class _RewardDetailPanel extends StatefulWidget {
  final Reward reward;
  final User user;
  final bool canAfford;
  final bool hasRedeemed;
  final VoidCallback onClosed;
  final VoidCallback onChanged;

  const _RewardDetailPanel({
    required this.reward,
    required this.user,
    required this.canAfford,
    required this.hasRedeemed,
    required this.onClosed,
    required this.onChanged,
  });

  @override
  State<_RewardDetailPanel> createState() => _RewardDetailPanelState();
}

class _RewardDetailPanelState extends State<_RewardDetailPanel> {
  final RewardService _rewardService = RewardService();
  final UserDataService _userDataService = UserDataService();
  RedeemedReward? _redeemedReward;
  bool _isRedeeming = false;

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
    } catch (_) {}
  }

  Future<void> _redeemReward() async {
    if (!widget.canAfford) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar canje'),
            content: Text('¿Deseas canjear "${widget.reward.title}" por ${widget.reward.pointsCost} puntos?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _isRedeeming = true);
    try {
      final updatedUser = widget.user;
      updatedUser.points -= widget.reward.pointsCost;
      await _userDataService.setUserPoints(updatedUser.id, updatedUser.points);

      final redeemed = await _rewardService.redeemReward(widget.user.id, widget.reward);

      if (!mounted) return;
      setState(() {
        _redeemedReward = redeemed;
        _isRedeeming = false;
      });

      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRedeeming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al canjear: $e')),
      );
    }
  }

  void _copyCoupon() {
    if (_redeemedReward == null) return;
    Clipboard.setData(ClipboardData(text: _redeemedReward!.couponCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    final redeemed = _redeemedReward;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClosed,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    reward.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 220,
                      color: AppColors.surfaceAlt,
                      child: const Icon(Icons.image_rounded, size: 64),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(reward.title, style: AppTypography.displaySmall),
                const SizedBox(height: 6),
                Text(reward.businessName, style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(reward.address, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                CustomCard(
                  backgroundColor: AppColors.surfaceAlt,
                  border: Border.all(color: AppColors.borderLight),
                  child: Text(
                    reward.description,
                    style: AppTypography.bodyMedium.copyWith(height: 1.5, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _RewardMiniStat(
                        icon: Icons.stars_rounded,
                        label: 'Costo',
                        value: '${reward.pointsCost}',
                        color: AppColors.thermalGold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RewardMiniStat(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Tus puntos',
                        value: '${widget.user.points}',
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Términos y condiciones', style: AppTypography.titleMedium),
                const SizedBox(height: 8),
                CustomCard(
                  backgroundColor: AppColors.background,
                  border: Border.all(color: AppColors.borderLight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: reward.termsAndConditions
                        .map(
                          (term) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 18, color: AppColors.thermalCool),
                                const SizedBox(width: 8),
                                Expanded(child: Text(term, style: AppTypography.bodySmall.copyWith(height: 1.45))),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (redeemed != null) ...[
                  CustomCard(
                    backgroundColor: AppColors.accentGreen.withValues(alpha: 0.08),
                    border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.25)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('¡Recompensa canjeada!', style: AppTypography.titleSmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                redeemed.couponCode,
                                style: AppTypography.displaySmall.copyWith(letterSpacing: 3),
                              ),
                            ),
                            IconButton(
                              onPressed: _copyCoupon,
                              icon: const Icon(Icons.copy),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  CustomButton(
                    label: widget.canAfford ? 'Canjear recompensa' : 'Puntos insuficientes',
                    icon: Icons.card_giftcard,
                    isDisabled: !widget.canAfford,
                    isLoading: _isRedeeming,
                    onPressed: _redeemReward,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardMiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RewardMiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _BadgePill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final pillColor = color ?? Colors.black54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pillColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelSmall.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
