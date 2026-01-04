import 'package:flutter/material.dart';

/// 积分卡片
class PointsCard extends StatelessWidget {
  final int balance;

  const PointsCard({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Theme.of(context).primaryColor,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '我的积分',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$balance',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '分',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Icon(Icons.stars, color: Colors.white70, size: 20),
                Text(
                  '签到赚积分，兑换好礼',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Icon(Icons.card_giftcard, color: Colors.white70, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

