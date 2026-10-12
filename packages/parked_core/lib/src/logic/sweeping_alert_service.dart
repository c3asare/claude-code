import '../models/car.dart';
import '../models/park_event.dart';
import '../models/sweeping_schedule.dart';
import '../ports/alert_scheduler.dart';
import '../ports/repositories.dart';
import 'sweeping_planner.dart';

class SweepingStatus {
  const SweepingStatus.unknown()
      : schedule = null,
        window = null,
        alerts = const [];
  const SweepingStatus(this.schedule, this.window, this.alerts);

  final SweepingSchedule? schedule;
  final SweepWindow? window;
  final List<DateTime> alerts;

  /// No schedule found for this spot (either unsupported city or no sweeping).
  bool get isUnknown => schedule == null;

  /// Parked inside a window that has already started.
  bool isInWindow(DateTime now) =>
      window != null && !now.isBefore(window!.start) && now.isBefore(window!.end);
}

/// Looks up the sweeping rule for a parked spot and schedules alerts.
/// With several overlapping rules (e.g. both sides of a street) it picks the
/// one that sweeps soonest, so a false "you're safe" is the unlikely error.
class SweepingAlertService {
  SweepingAlertService(
    this._sweeping,
    this._scheduler, {
    this.planner = const SweepingPlanner(),
    this.leads = const [Duration(hours: 12), Duration(hours: 1)],
  });

  final SweepingRepository _sweeping;
  final AlertScheduler _scheduler;
  final SweepingPlanner planner;
  final List<Duration> leads;

  Future<SweepingStatus> statusFor(ParkEvent e, {DateTime? now}) async {
    final t = now ?? DateTime.now();
    SweepingSchedule? best;
    SweepWindow? bestWindow;
    for (final s in await _sweeping.coveringPoint(e.position)) {
      final w = planner.nextWindow(s, t);
      if (w == null) continue;
      if (bestWindow == null || w.start.isBefore(bestWindow.start)) {
        best = s;
        bestWindow = w;
      }
    }
    if (best == null || bestWindow == null) return const SweepingStatus.unknown();
    return SweepingStatus(best, bestWindow, planner.alertTimes(best, t, leads: leads));
  }

  /// Call once the user has confirmed which car this is.
  Future<SweepingStatus> onParked(ParkEvent e, {Car? car, DateTime? now}) async {
    final status = await statusFor(e, now: now);
    await _scheduler.cancelWhere(e.id);
    final who = car?.name ?? 'Your car';
    for (var i = 0; i < status.alerts.length; i++) {
      final lead = status.window!.start.difference(status.alerts[i]);
      await _scheduler.schedule(
        key: '${e.id}:$i',
        at: status.alerts[i],
        title: 'Move $who: street sweeping',
        body: lead.inHours >= 1
            ? 'Sweeping starts in about ${lead.inHours} h. Move it to avoid a ticket.'
            : 'Sweeping starts in ${lead.inMinutes} min. Move it now.',
      );
    }
    return status;
  }

  Future<void> onDeparted(ParkEvent e) => _scheduler.cancelWhere(e.id);
}
