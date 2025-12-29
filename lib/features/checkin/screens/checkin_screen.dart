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
                          // 切换月份时加载对应月份的日历数据
                          notifier.loadCalendarForMonth(focusedDay.year, focusedDay.month);
                        },
                        onCheckInRecordTap: () {
                          _showCheckInRecordDialog(context, ref);
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
            Text('• 连续签到3-6天可获得额外10积分'),
            SizedBox(height: 8),
            Text('• 连续签到7天以上可获得超级奖励20积分'),
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

  void _showCheckInRecordDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(checkinProvider);
    final history = state.history;
    final totalDays = state.stats?.totalCheckIns ?? history.length;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '打卡记录',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Text(
                '总签到: ${totalDays}天',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const Divider(height: 24),
              // 列表
              Expanded(
                child: history.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无打卡记录',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final record = history[index];
                          final date = record.checkInTime;
                          final dateTimeStr = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';

                          String typeText = '正常';
                          if (record.checkInType == 'bonus') {
                            typeText = '奖励';
                          } else if (record.checkInType == 'makeup') {
                            typeText = '补签';
                          }

                          // 获取来源信息
                          String? source;
                          if (record.extra != null && record.extra!.containsKey('source')) {
                            final sourceValue = record.extra!['source'];
                            if (sourceValue != null) {
                              source = sourceValue.toString();
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 第一行：类型（左）和积分（右）
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      typeText,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '+${record.pointsEarned}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // 第二行：连续天数（左）和时间（右）
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '连续: ${record.continuousDays}天',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    Text(
                                      dateTimeStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                if (source != null) ...[
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '来源: ${source == 'web' ? 'Web' : source == 'ios' ? 'iOS' : source == 'android' ? 'Android' : source}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

