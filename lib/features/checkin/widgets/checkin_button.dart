import 'package:flutter/material.dart';

/// 签到按钮
class CheckinButton extends StatelessWidget {
  final bool hasCheckedIn;
  final VoidCallback onCheckIn;

  const CheckinButton({
    super.key,
    required this.hasCheckedIn,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              hasCheckedIn ? Icons.check_circle : Icons.calendar_today,
              size: 80,
              color: hasCheckedIn ? Colors.green : Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              hasCheckedIn ? '今日已签到' : '点击签到',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: hasCheckedIn ? null : onCheckIn,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  hasCheckedIn ? '已完成签到' : '立即签到',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

