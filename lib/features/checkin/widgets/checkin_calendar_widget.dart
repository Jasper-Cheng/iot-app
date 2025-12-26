import 'package:flutter/material.dart';
import '../../../data/models/checkin.dart';

/// 签到日历组件（按图片样式）
class CheckinCalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final List<DateTime> checkedInDates;
  final CheckinStats? stats;
  final Function(DateTime focusedDay) onMonthChanged;
  final VoidCallback? onCheckInRecordTap;
  final VoidCallback? onRewardRulesTap;
  final VoidCallback? onCheckIn;

  const CheckinCalendarWidget({
    super.key,
    required this.focusedDay,
    required this.checkedInDates,
    this.stats,
    required this.onMonthChanged,
    this.onCheckInRecordTap,
    this.onRewardRulesTap,
    this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _isSameDay(focusedDay, now);

    return Column(
      children: [
        // 顶部标题和统计
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 左侧：标题和统计
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '打卡日历',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    if (stats != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        children: [
                          Text(
                            '已打卡${stats!.totalCheckIns}天',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            '连击${stats!.continuousDays}天',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            '最长${stats!.longestContinuous}天',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // 右侧：打卡记录按钮
              if (onCheckInRecordTap != null)
                TextButton.icon(
                  onPressed: onCheckInRecordTap,
                  icon: const Icon(Icons.access_time, size: 16),
                  label: const Text('打卡记录'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ),

        // 月份导航
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: Theme.of(context).textTheme.bodyLarge?.color),
                onPressed: () {
                  final previousMonth = DateTime(
                    focusedDay.year,
                    focusedDay.month - 1,
                    1,
                  );
                  onMonthChanged(previousMonth);
                },
              ),
              Text(
                _getMonthText(focusedDay),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyLarge?.color),
                onPressed: () {
                  final nextMonth = DateTime(
                    focusedDay.year,
                    focusedDay.month + 1,
                    1,
                  );
                  onMonthChanged(nextMonth);
                },
              ),
            ],
          ),
        ),

        // 星期标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['日', '一', '二', '三', '四', '五', '六'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // 日期网格
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildCalendarGrid(context, now),
        ),

        // 底部图例和奖励规则
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 图例
              Row(
                children: [
                  _buildLegendItem(context, Colors.green, '已打卡'),
                  const SizedBox(width: 16),
                  _buildLegendItem(context, Colors.yellow, '今天'),
                  const SizedBox(width: 16),
                  _buildLegendItem(context, Colors.grey, '可打卡'),
                ],
              ),
              // 奖励规则按钮
              if (onRewardRulesTap != null)
                TextButton.icon(
                  onPressed: onRewardRulesTap,
                  icon: const Icon(Icons.star, size: 16),
                  label: const Text('奖励规则'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context, DateTime now) {
    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final List<Widget> dayWidgets = [];

    // 添加上个月的最后几天（灰色）
    final prevMonthLastDay = DateTime(focusedDay.year, focusedDay.month, 0);
    final prevMonthDays = prevMonthLastDay.day;
    for (int i = firstWeekday - 1; i >= 0; i--) {
      final day = prevMonthDays - i;
      dayWidgets.add(
        Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
            ),
          ),
        ),
      );
    }

    // 添加当前月的日期
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedDay.year, focusedDay.month, day);
      final isToday = _isSameDay(date, now);
      final isCheckedIn = checkedInDates.any((d) => _isSameDay(d, date));

      dayWidgets.add(
        GestureDetector(
          onTap: isToday && !isCheckedIn && onCheckIn != null ? onCheckIn : null,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCheckedIn
                  ? Colors.green
                  : isToday
                      ? Colors.yellow
                      : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isCheckedIn
                          ? Colors.white
                          : isToday
                              ? Colors.black87
                              : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                if (isCheckedIn)
                  const Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // 添加下个月的前几天（灰色）
    final totalCells = firstWeekday + daysInMonth;
    final remainingCells = 7 - (totalCells % 7);
    if (remainingCells < 7) {
      for (int day = 1; day <= remainingCells; day++) {
        dayWidgets.add(
          Center(
            child: Text(
              '$day',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white30,
              ),
            ),
          ),
        );
      }
    }

    // 创建网格
    final rows = (dayWidgets.length / 7).ceil();
    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final index = rowIndex * 7 + colIndex;
              return Expanded(
                child: Center(
                  child: index < dayWidgets.length
                      ? dayWidgets[index]
                      : const SizedBox(),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  String _getMonthText(DateTime date) {
    const months = [
      '一月',
      '二月',
      '三月',
      '四月',
      '五月',
      '六月',
      '七月',
      '八月',
      '九月',
      '十月',
      '十一月',
      '十二月',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

