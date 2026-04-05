part of 'habit_detail_screen.dart';


class _YearlyHeatmapState extends State<_YearlyHeatmap> {
  final ScrollController _scrollController = ScrollController();
  String? _tappedDateLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final emptyColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    final weeks = <List<DateTime?>>[];
    var current = yearStart;
    while (current.weekday != DateTime.monday) {
      current = current.subtract(const Duration(days: 1));
    }

    while (current.isBefore(now) || current.isAtSameMomentAs(now)) {
      final week = <DateTime?>[];
      for (int d = 0; d < 7; d++) {
        final date = current.add(Duration(days: d));
        if (date.year == now.year && !date.isAfter(now)) {
          week.add(date);
        } else {
          week.add(null);
        }
      }
      weeks.add(week);
      current = current.add(const Duration(days: 7));
    }

    final monthLabels = <int, String>{};
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    for (int w = 0; w < weeks.length; w++) {
      for (final date in weeks[w]) {
        if (date != null && date.day <= 7 && date.weekday == DateTime.monday) {
          monthLabels[w] = monthNames[date.month - 1];
          break;
        }
      }
    }

    const cellSize = 11.0;
    const cellSpacing = 2.5;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded, color: widget.habitColor, size: 18),
              const SizedBox(width: 8),
              Text('${now.year} Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 7 * (cellSize + cellSpacing) + 18,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 14,
                    child: Row(
                      children: List.generate(weeks.length, (w) {
                        return SizedBox(
                          width: cellSize + cellSpacing,
                          child: monthLabels.containsKey(w)
                              ? Text(monthLabels[w]!, style: TextStyle(fontSize: 8, color: widget.textSecondary))
                              : null,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(7, (dayIndex) {
                    return Row(
                      children: List.generate(weeks.length, (weekIndex) {
                        final date = weeks[weekIndex][dayIndex];
                        if (date == null) {
                          return SizedBox(width: cellSize + cellSpacing, height: cellSize + cellSpacing);
                        }
                        final normalizedDate = DateTime(date.year, date.month, date.day);
                        final completed = widget.data.yearlyData[normalizedDate] == true;
                        final isToday = normalizedDate.year == now.year &&
                            normalizedDate.month == now.month &&
                            normalizedDate.day == now.day;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              final status = completed ? 'Completed' : 'Missed';
                              _tappedDateLabel = '${monthNames[date.month - 1]} ${date.day}: $status';
                            });
                          },
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            margin: const EdgeInsets.all(cellSpacing / 2),
                            decoration: BoxDecoration(
                              color: completed ? widget.habitColor : emptyColor,
                              borderRadius: BorderRadius.circular(2.5),
                              border: isToday
                                  ? Border.all(color: widget.habitColor, width: 1.5)
                                  : null,
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (_tappedDateLabel != null)
            Center(child: Text(_tappedDateLabel!, style: TextStyle(fontSize: 10, color: widget.textSecondary, fontWeight: FontWeight.w500)))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 9, height: 9, decoration: BoxDecoration(color: emptyColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Text('Missed', style: TextStyle(fontSize: 9, color: widget.textSecondary)),
                const SizedBox(width: 14),
                Container(width: 9, height: 9, decoration: BoxDecoration(color: widget.habitColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Text('Done', style: TextStyle(fontSize: 9, color: widget.textSecondary)),
              ],
            ),
        ],
      ),
    );
  }
}


// ============================================
// MONTHLY SUMMARY
// ============================================

class _MonthlySummary extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;

  const _MonthlySummary({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    final monthlyData = <int, int>{};
    for (final entry in data.yearlyData.entries) {
      if (entry.value && entry.key.year == now.year) {
        monthlyData[entry.key.month] = (monthlyData[entry.key.month] ?? 0) + 1;
      }
    }

    final displayMonths = <int>[];
    for (int m = 1; m <= now.month; m++) {
      if ((monthlyData[m] ?? 0) > 0 || m == now.month) displayMonths.add(m);
    }

    if (displayMonths.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('No monthly data yet', style: TextStyle(fontSize: 12, color: textSecondary)),
        ),
      );
    }

    return Column(
      children: displayMonths.map((monthIndex) {
        final monthName = months[monthIndex - 1];
        final completions = monthlyData[monthIndex] ?? 0;
        final daysInMonth = DateTime(now.year, monthIndex + 1, 0).day;
        final maxDays = monthIndex == now.month ? now.day : daysInMonth;
        final percentage = maxDays > 0 ? (completions / maxDays * 100).round() : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 65,
                child: Text(monthName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: habitColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(habitColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '$percentage%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: habitColor),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}


// ============================================
// TAB 3: HISTORY
// ============================================

class _HistoryTab extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;

  const _HistoryTab({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    if (data.recentLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 44, color: textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            Text('No activity yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary)),
            const SizedBox(height: 6),
            Text('Complete this habit to see your history', style: TextStyle(fontSize: 12, color: textSecondary)),
          ],
        ),
      );
    }

    final groupedLogs = <String, List<HabitLogEntry>>{};
    for (final log in data.recentLogs) {
      final key = _formatDateHeader(log.date);
      groupedLogs.putIfAbsent(key, () => []).add(log);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedLogs.length,
      itemBuilder: (context, index) {
        final dateKey = groupedLogs.keys.elementAt(index);
        final logs = groupedLogs[dateKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 6, top: index > 0 ? 14.0 : 0),
              child: Text(dateKey, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
            ),
            ...logs.map((log) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: habitColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: habitColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Completed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                            Text(_formatTime(log.date), style: TextStyle(fontSize: 11, color: textSecondary)),
                          ],
                        ),
                      ),
                      if (log.value != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: habitColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${log.value}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: habitColor)),
                        ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (now.difference(dateOnly).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}


// ============================================
// MOTIVATIONAL CARD (with best-streak proximity)
// ============================================

class _MotivationalCard extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;

  const _MotivationalCard({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, message) = _getMotivation(data.currentStreak);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: habitColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _getMotivation(int streak) {
    if (streak == 0) {
      return ('🎯', 'Start your streak today! Every journey begins with a single step.');
    } else if (streak < 7) {
      return ('🌱', 'Great start! $streak days and counting. Keep building momentum.');
    } else if (streak < 14) {
      return ('💪', 'One week strong! You\'re building a real habit.');
    } else if (streak < 30) {
      return ('🔥', '$streak days! Research shows 21 days makes a habit.');
    } else if (streak < 60) {
      return ('⭐', 'Incredible $streak-day consistency! This habit is part of you now.');
    } else {
      return ('🏆', '$streak days! You\'ve mastered this habit. Truly inspiring.');
    }
  }
}


// ============================================
// GLASSMORPHIC BUTTON
// ============================================

class _GlassmorphicButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isDark;

  const _GlassmorphicButton({
    required this.onTap,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

