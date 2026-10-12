/// Schedules a future local notification. Implemented in the app layer.
abstract interface class AlertScheduler {
  Future<void> schedule({
    required String key,
    required DateTime at,
    required String title,
    required String body,
  });

  /// Cancels every alert whose key starts with [keyPrefix].
  Future<void> cancelWhere(String keyPrefix);
}
