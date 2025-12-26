import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/checkin_provider.dart';
import '../widgets/checkin_calendar_widget.dart';

/// 每日签到页面
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkinProvider);
    final notifier = ref.read(checkinProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('每日签到'),
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: state.isLoading && state.checkedInDates.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      CheckinCalendarWidget(
                        focusedDay: _focusedDay,
                        checkedInDates: state.checkedInDates,
                        stats: state.stats,
                        onMonthChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        onCheckInRecordTap: () {
                          // 跳转到打卡记录页面（可以显示签到历史）
                          // 这里可以创建一个新的页面或使用对话框
                        },
                        onRewardRulesTap: () {
                          _showRewardRulesDialog(context);
                        },
                        onCheckIn: () async {
                          final record = await notifier.checkIn();
                          if (record != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('签到成功！获得 ${record.pointsEarned} 积分'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else if (state.error != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.error!),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _showRewardRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('奖励规则'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• 每日签到可获得5积分'),
            SizedBox(height: 8),
            Text('• 连续签到7天可获得额外20积分'),
            SizedBox(height: 8),
            Text('• 连续签到30天可获得额外100积分'),
            SizedBox(height: 8),
            Text('• 积分可用于兑换礼品和优惠券'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

}

