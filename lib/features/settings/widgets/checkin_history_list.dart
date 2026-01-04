import 'package:flutter/material.dart';
import '../../../data/models/checkin.dart';

/// 签到历史列表
class CheckinHistoryList extends StatelessWidget {
  final List<CheckinRecord> history;

  const CheckinHistoryList({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              '暂无签到记录',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: history.map((record) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTypeColor(record.checkInType).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTypeIcon(record.checkInType),
                color: _getTypeColor(record.checkInType),
              ),
            ),
            title: Text(_getTypeText(record.checkInType)),
            subtitle: Text(
              _formatTime(record.checkInTime),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${record.pointsEarned}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (record.continuousDays > 1)
                  Text(
                    '连签${record.continuousDays}天',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'bonus':
        return Icons.card_giftcard;
      case 'makeup':
        return Icons.history;
      default:
        return Icons.check_circle;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'bonus':
        return Colors.amber;
      case 'makeup':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'bonus':
        return '连签奖励';
      case 'makeup':
        return '补签';
      default:
        return '每日签到';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

