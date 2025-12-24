import 'package:flutter/material.dart';

/// 简单日历组件
class SimpleCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<DateTime> checkedInDates;
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final Function(DateTime focusedDay) onMonthChanged;

  const SimpleCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.checkedInDates,
    required this.onDaySelected,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 月份选择器
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
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
              '${focusedDay.year}年${focusedDay.month}月',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
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
        const SizedBox(height: 8),
        // 星期标题
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['日', '一', '二', '三', '四', '五', '六'].map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // 日期网格
        _buildCalendarGrid(context),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final List<Widget> dayWidgets = [];

    // 添加空白占位符
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // 添加日期
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedDay.year, focusedDay.month, day);
      final isToday = _isSameDay(date, DateTime.now());
      final isSelected = _isSameDay(date, selectedDay);
      final isCheckedIn = checkedInDates.any((d) => _isSameDay(d, date));

      dayWidgets.add(
        InkWell(
          onTap: () => onDaySelected(date, focusedDay),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : isToday
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : null,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                    fontWeight: isToday || isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (isCheckedIn)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // 计算需要多少行
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    // 添加剩余空白占位符
    while (dayWidgets.length < rows * 7) {
      dayWidgets.add(const SizedBox());
    }

    // 创建网格
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
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: index < dayWidgets.length
                        ? dayWidgets[index]
                        : const SizedBox(),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

