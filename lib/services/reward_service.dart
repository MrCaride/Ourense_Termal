import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/reward_model.dart';
import '../models/user_model.dart';
import '../data/rewards_data.dart';
import 'database_service.dart';
import 'dart:math';

class RewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  // Obtener todas las recompensas disponibles (delegando a RewardsData)
  static List<Reward> getAvailableRewards() {
    return RewardsData.getAvailableRewards();
  }

  // Filtrar recompensas por tipo (delegando a RewardsData)
  static List<Reward> filterRewardsByType(String type) {
    return RewardsData.filterRewardsByType(type);
  }

  // Canjear una recompensa
  Future<RedeemedReward> redeemReward(String userId, Reward reward) async {
    final couponCode = _generateCouponCode();
    final now = DateTime.now();

    final redeemedReward = RedeemedReward(
      id: 'redeemed_${userId}_${reward.id}_${now.millisecondsSinceEpoch}',
      rewardId: reward.id,
      couponCode: couponCode,
      redeemedDate: now,
      used: false,
    );

    try {
      // Guardar en Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('redeemed_rewards')
          .doc(redeemedReward.id)
          .set({
        'rewardId': redeemedReward.rewardId,
        'couponCode': redeemedReward.couponCode,
        'redeemedDate': Timestamp.fromDate(redeemedReward.redeemedDate),
        'used': redeemedReward.used,
      });
    } catch (e) {
      debugPrint('Error guardando recompensa canjeada en Firestore: $e');
    }

    // Solo intentar guardar en SQLite si no estamos en web
    if (!kIsWeb) {
      try {
        // Guardar en SQLite
        final db = await _dbService.database;
        await db.insert('user_redeemed_rewards', {
          'id': redeemedReward.id,
          'user_id': userId,
          'reward_id': redeemedReward.rewardId,
          'coupon_code': redeemedReward.couponCode,
          'redeemed_date': redeemedReward.redeemedDate.millisecondsSinceEpoch,
          'used': redeemedReward.used ? 1 : 0,
        });
      } catch (e) {
        debugPrint('Error guardando recompensa canjeada en SQLite: $e');
      }
    }

    return redeemedReward;
  }

  // Obtener recompensas canjeadas por el usuario
  Future<List<RedeemedReward>> getUserRedeemedRewards(String userId) async {
    List<RedeemedReward> redeemed = [];

    try {
      // Intentar Firestore primero
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('redeemed_rewards')
          .orderBy('redeemedDate', descending: true)
          .get();

      redeemed = snapshot.docs.map((doc) {
        final data = doc.data();
        return RedeemedReward(
          id: doc.id,
          rewardId: data['rewardId'] ?? '',
          couponCode: data['couponCode'] ?? '',
          redeemedDate: (data['redeemedDate'] as Timestamp).toDate(),
          used: data['used'] ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error obteniendo recompensas de Firestore: $e');

      // Fallback a SQLite (solo si no estamos en web)
      if (!kIsWeb) {
        try {
          final db = await _dbService.database;
          final List<Map<String, dynamic>> maps = await db.query(
            'user_redeemed_rewards',
            where: 'user_id = ?',
            whereArgs: [userId],
            orderBy: 'redeemed_date DESC',
          );

          redeemed = maps.map((map) {
            return RedeemedReward(
              id: map['id'],
              rewardId: map['reward_id'],
              couponCode: map['coupon_code'],
              redeemedDate: DateTime.fromMillisecondsSinceEpoch(map['redeemed_date']),
              used: map['used'] == 1,
            );
          }).toList();
        } catch (e) {
          debugPrint('Error obteniendo recompensas de SQLite: $e');
        }
      }
    }

    return redeemed;
  }

  // Marcar recompensa como usada
  Future<void> markRewardAsUsed(String userId, String redeemedRewardId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('redeemed_rewards')
          .doc(redeemedRewardId)
          .update({'used': true});
    } catch (e) {
      debugPrint('Error actualizando recompensa en Firestore: $e');
    }

    // Solo intentar actualizar en SQLite si no estamos en web
    if (!kIsWeb) {
      try {
        final db = await _dbService.database;
        await db.update(
          'user_redeemed_rewards',
          {'used': 1},
          where: 'id = ?',
          whereArgs: [redeemedRewardId],
        );
      } catch (e) {
        debugPrint('Error actualizando recompensa en SQLite: $e');
      }
    }
  }

  // Generar código de cupón único
  String _generateCouponCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)])
        .join();
  }
}
