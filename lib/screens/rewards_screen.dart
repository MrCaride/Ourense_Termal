import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/reward_model.dart';
import '../services/reward_service.dart';
import '../services/user_data_service.dart';
import 'reward_detail_screen.dart';
import '../utils/app_theme.dart';

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
    'all': Icons.grid_view,
    'spa': Icons.hot_tub,
    'pastry': Icons.bakery_dining,
    'restaurant': Icons.restaurant,
    'shop': Icons.shopping_bag,
    'experience': Icons.explore,
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
      // Cargar usuario actualizado
      _user = await _userDataService.getUserWithStats(_user.id);
      
      // Cargar todas las recompensas
      _allRewards = RewardService.getAvailableRewards();
      _displayedRewards = _allRewards;
      
      // Cargar recompensas canjeadas
      _redeemedRewards = await _rewardService.getUserRedeemedRewards(_user.id);
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error cargando recompensas: $e');
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

  void _navigateToRewardDetail(Reward reward) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RewardDetailScreen(
          reward: reward,
          user: _user,
          canAfford: _canAfford(reward),
          hasRedeemed: _hasRedeemed(reward),
        ),
      ),
    );

    if (result == true) {
      // Recargar datos después de canjear
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      appBar: AppBar(title: const Text('Recompensas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  _buildPointsHeader(),
                  _buildFilterChips(),
                  Expanded(
                    child: _displayedRewards.isEmpty
                        ? _buildEmptyState()
                        : _buildRewardsList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPointsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.brandTeal, Color(0xFF0EA5A4), Color(0xFF0284C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.workspace_premium, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tu cartera termal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Nivel ${_user.level}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 32),
                const SizedBox(width: 8),
                Text(
                  '${_user.points}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('puntos', style: TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _user.getLevelProgress(),
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterLabels.entries.map((entry) {
            final isSelected = _selectedFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.brandTeal
                      : Colors.black.withValues(alpha: 0.08),
                ),
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _filterIcons[entry.key],
                      size: 18,
                      color: isSelected ? Colors.white : Colors.blue[700],
                    ),
                    const SizedBox(width: 6),
                    Text(entry.value),
                  ],
                ),
                selectedColor: AppTheme.brandTeal,
                checkmarkColor: Colors.white,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.brandTeal,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
                onSelected: (_) => _applyFilter(entry.key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRewardsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _displayedRewards.length,
      itemBuilder: (context, index) {
        final reward = _displayedRewards[index];
        return _buildRewardCard(reward);
      },
    );
  }

  Widget _buildRewardCard(Reward reward) {
    final canAfford = _canAfford(reward);
    final hasRedeemed = _hasRedeemed(reward);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _navigateToRewardDetail(reward),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  Image.network(
                    reward.imageUrl,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.44),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (hasRedeemed)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Canjeado',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Badge de categoría
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _filterIcons[reward.businessType],
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _filterLabels[reward.businessType] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            reward.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.businessName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Descripción
                  Text(
                    reward.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Ubicación
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reward.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Precio y botón
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.stars,
                            color: canAfford ? Colors.amber : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${reward.pointsCost} puntos',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: canAfford ? AppTheme.brandTeal : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      FilledButton(
                        onPressed: () => _navigateToRewardDetail(reward),
                        style: FilledButton.styleFrom(
                          backgroundColor: hasRedeemed
                              ? Colors.green
                              : canAfford
                                  ? AppTheme.brandTeal
                                  : Colors.grey[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        child: Text(
                          hasRedeemed ? 'Ver cupón' : 'Canjear',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay recompensas en esta categoría',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
