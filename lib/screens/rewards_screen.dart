import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/reward_model.dart';
import '../services/reward_service.dart';
import '../services/user_data_service.dart';
import 'reward_detail_screen.dart';

class RewardsScreen extends StatefulWidget {
  final User user;

  const RewardsScreen({Key? key, required this.user}) : super(key: key);

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Recompensas'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Tus Puntos',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Text(
                '${_user.points}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Nivel ${_user.level}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterLabels.entries.map((entry) {
            final isSelected = _selectedFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
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
                selectedColor: Colors.blue[700],
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.blue[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToRewardDetail(reward),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  Image.network(
                    reward.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 50, color: Colors.grey),
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
                ],
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y descuento
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reward.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reward.businessName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          reward.discount,
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: canAfford ? Colors.blue[700] : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _navigateToRewardDetail(reward),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasRedeemed
                              ? Colors.green
                              : canAfford
                                  ? Colors.blue[700]
                                  : Colors.grey[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
