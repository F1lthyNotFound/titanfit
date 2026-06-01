import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WeekDayItem {
  const WeekDayItem({
    required this.date,
    required this.weekday,
    required this.day,
    required this.isToday,
  });

  final String date;
  final String weekday;
  final int day;
  final bool isToday;

  static List<WeekDayItem> currentWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      final iso = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      return WeekDayItem(
        date: iso,
        weekday: names[i],
        day: d.day,
        isToday: d.year == now.year && d.month == now.month && d.day == now.day,
      );
    });
  }
}

class WeekDayStrip extends StatelessWidget {
  const WeekDayStrip({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.onSelect,
  });

  final List<WeekDayItem> days;
  final String? selectedDate;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((d) {
          final selected = d.date == selectedDate;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: selected
                  ? theme.colorScheme.onSurface
                  : (isDark ? TitanTheme.surfaceDark : TitanTheme.surfaceLight),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelect(d.date),
                child: Container(
                  width: 56,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        d.weekday,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: selected ? theme.colorScheme.surface : theme.colorScheme.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.day}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
