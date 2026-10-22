import '../models/sweeping_schedule.dart';

class SweepWindow {
  const SweepWindow(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

/// Computes upcoming sweep windows and alert times. All DateTimes are local
/// wall-clock in the schedule's city.
class SweepingPlanner {
  const SweepingPlanner();

  static int weekOfMonth(DateTime d) => (d.day - 1) ~/ 7 + 1;

  bool _runsOn(SweepingSchedule s, DateTime day) =>
      s.weekdays.contains(day.weekday) &&
      s.weeksOfMonth.contains(weekOfMonth(day)) &&
      !s.skipDates.any((k) =>
          k.year == day.year && k.month == day.month && k.day == day.day);

  /// First window whose end is after [from], searching up to [horizonDays].
  SweepWindow? nextWindow(SweepingSchedule s, DateTime from,
      {int horizonDays = 62}) {
    final day0 = DateTime(from.year, from.month, from.day);
    for (var i = 0; i <= horizonDays; i++) {
      final day = DateTime(day0.year, day0.month, day0.day + i);
      if (!_runsOn(s, day)) continue;
      final start = day.add(Duration(minutes: s.startMinute));
      final end = day.add(Duration(minutes: s.endMinute));
      if (end.isAfter(from)) return SweepWindow(start, end);
    }
    return null;
  }

  /// Alert instants before the next window, e.g. [Duration(hours: 12), Duration(hours: 1)].
  /// Past instants are dropped, but a car already inside the window still gets none.
  List<DateTime> alertTimes(
    SweepingSchedule s,
    DateTime from, {
    List<Duration> leads = const [Duration(hours: 12), Duration(hours: 1)],
  }) {
    final w = nextWindow(s, from);
    if (w == null) return const [];
    return [for (final l in leads) w.start.subtract(l)]
        .where((t) => t.isAfter(from))
        .toList()
      ..sort();
  }
}
