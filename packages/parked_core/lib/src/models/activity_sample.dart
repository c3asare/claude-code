enum ActivityKind { inVehicle, onFoot, walking, running, cycling, still, unknown }

enum ActivityConfidence { low, medium, high }

/// Platform-neutral activity reading. The sensing layer maps Core Motion /
/// Android Activity Recognition output into this.
class ActivitySample {
  const ActivitySample(this.kind, this.confidence, this.at);
  final ActivityKind kind;
  final ActivityConfidence confidence;
  final DateTime at;
}
