import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/checkin_provider.dart';
import '../widgets/checkin_button.dart';
import '../widgets/checkin_stats_card.dart';
import '../widgets/points_card.dart';
import '../widgets/checkin_history_list.dart';
import '../widgets/simple_calendar.dart';

/// 签到与积分页面
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkinProvider);
    final notifier = ref.read(checkinProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('签到与积分'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '签到'),
            Tab(text: '积分'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCheckinTab(state, notifier),
            _buildPointsTab(state),
          ],
        ),
      ),
    );
  }

  /// 签到标签页
  Widget _buildCheckinTab(CheckinState state, CheckinNotifier notifier) {
    if (state.isLoading && state.checkedInDates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 签到按钮
          CheckinButton(
            hasCheckedIn: state.hasCheckedInToday,
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
          const SizedBox(height: 24),

          // 签到统计卡片
          if (state.stats != null)
            CheckinStatsCard(stats: state.stats!),
          const SizedBox(height: 24),

          // 签到日历
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '签到日历',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SimpleCalendar(
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    checkedInDates: state.checkedInDates,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onMonthChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 签到历史
          const Text(
            '签到历史',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          CheckinHistoryList(history: state.history),
        ],
      ),
    );
  }

  /// 积分标签页
  Widget _buildPointsTab(CheckinState state) {
    if (state.isLoading && state.pointsHistory.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 积分余额卡片
          PointsCard(balance: state.pointsBalance),
          const SizedBox(height: 24),

          // 积分历史
          const Text(
            '积分记录',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...state.pointsHistory.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.amount > 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.amount > 0 ? Icons.add : Icons.remove,
                    color: item.amount > 0 ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(item.description),
                subtitle: Text(
                  _formatTime(item.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                trailing: Text(
                  '${item.amount > 0 ? '+' : ''}${item.amount}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: item.amount > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

