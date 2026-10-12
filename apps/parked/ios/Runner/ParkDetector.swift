import CoreLocation
import CoreMotion
import Flutter
import UIKit
import UserNotifications

/// iOS can't run continuously, so detection piggybacks on system relaunches:
/// significant-location-change and CLVisit events wake the app in the
/// background (even if it was terminated by the system). On each wake we ask
/// Core Motion's *history* whether a drive recently ended, then post the
/// "Looks like you parked" notification and park the result in UserDefaults
/// for Dart to drain (channel `app.parked/background`).
///
/// Limits (document to users): wake-ups are system-scheduled, so detection can
/// lag several minutes, and the car position is the nearest earlier location
/// sample, which may be a few hundred meters off. The app lets the user
/// adjust the pin after confirming. A user force-quit stops relaunches until
/// the app is opened again.
final class ParkDetector: NSObject, CLLocationManagerDelegate {
  static let shared = ParkDetector()

  private let lm = CLLocationManager()
  private let motion = CMMotionActivityManager()
  private let defaults = UserDefaults.standard
  private let enabledKey = "parked.enabled"
  private let pendingKey = "parked.pending"
  private let trailKey = "parked.trail"
  private let lastParkKey = "parked.lastParkAt"

  var isEnabled: Bool { defaults.bool(forKey: enabledKey) }

  override init() {
    super.init()
    lm.delegate = self
  }

  // MARK: Lifecycle

  /// Called from didFinishLaunching so relaunch-by-location events reach the delegate.
  func resumeIfEnabled() {
    if isEnabled { startMonitoring() }
  }

  func start() {
    defaults.set(true, forKey: enabledKey)
    startMonitoring()
  }

  func stop() {
    defaults.set(false, forKey: enabledKey)
    lm.stopMonitoringSignificantLocationChanges()
    lm.stopMonitoringVisits()
  }

  private func startMonitoring() {
    lm.startMonitoringSignificantLocationChanges()
    lm.startMonitoringVisits()
  }

  // MARK: Dart bridge

  func drain() -> [[String: Any]] {
    let items = defaults.array(forKey: pendingKey) as? [[String: Any]] ?? []
    defaults.removeObject(forKey: pendingKey)
    return items
  }

  // MARK: CLLocationManagerDelegate

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let latest = locations.last else { return }
    appendTrail(latest)
    evaluate(now: Date())
  }

  func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
    // Arrival at a place means the drive is very likely over.
    evaluate(now: Date())
  }

  // MARK: Detection

  private func evaluate(now: Date) {
    guard CMMotionActivityManager.isActivityAvailable() else { return }
    let from = now.addingTimeInterval(-30 * 60)
    motion.queryActivityStarting(from: from, to: now, to: .main) { [weak self] activities, _ in
      guard let self = self, let acts = activities, !acts.isEmpty else { return }
      guard let parkedAt = self.lastDriveEnd(in: acts) else { return }

      // De-dupe: one park per 10 minutes.
      let last = self.defaults.double(forKey: self.lastParkKey)
      if last > 0, abs(parkedAt.timeIntervalSince1970 - last) < 600 { return }
      self.defaults.set(parkedAt.timeIntervalSince1970, forKey: self.lastParkKey)

      guard let spot = self.trailLocation(near: parkedAt) ?? self.lm.location else { return }
      let id = UUID().uuidString
      var item: [String: Any] = [
        "id": id,
        "lat": spot.coordinate.latitude,
        "lng": spot.coordinate.longitude,
        "parkedAtMillis": Int64(parkedAt.timeIntervalSince1970 * 1000),
      ]
      if spot.horizontalAccuracy >= 0 { item["accuracy"] = spot.horizontalAccuracy }
      var pending = self.defaults.array(forKey: self.pendingKey) as? [[String: Any]] ?? []
      pending.append(item)
      self.defaults.set(pending, forKey: self.pendingKey)
      self.notify(id: id)
    }
  }

  /// End of the most recent automotive stretch that has since stopped, or nil
  /// if still driving / never drove.
  private func lastDriveEnd(in acts: [CMMotionActivity]) -> Date? {
    var lastAuto: Int?
    for (i, a) in acts.enumerated() where a.automotive && a.confidence != .low { lastAuto = i }
    guard let i = lastAuto, i + 1 < acts.count else { return nil }
    // The next non-automotive sample must be walking/stationary and sustained
    // for at least ~20s (or be the latest sample).
    let next = acts[i + 1]
    guard !next.automotive, next.walking || next.stationary || next.running else { return nil }
    return next.startDate
  }

  // MARK: Location trail (coarse breadcrumbs while driving)

  private func appendTrail(_ loc: CLLocation) {
    var trail = defaults.array(forKey: trailKey) as? [[String: Double]] ?? []
    trail.append(["lat": loc.coordinate.latitude, "lng": loc.coordinate.longitude,
                  "acc": loc.horizontalAccuracy, "t": loc.timestamp.timeIntervalSince1970])
    defaults.set(Array(trail.suffix(20)), forKey: trailKey)
  }

  private func trailLocation(near date: Date) -> CLLocation? {
    let trail = defaults.array(forKey: trailKey) as? [[String: Double]] ?? []
    let best = trail
      .filter { abs($0["t"]! - date.timeIntervalSince1970) < 15 * 60 }
      .min { abs($0["t"]! - date.timeIntervalSince1970) < abs($1["t"]! - date.timeIntervalSince1970) }
    guard let b = best else { return nil }
    return CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: b["lat"]!, longitude: b["lng"]!),
      altitude: 0, horizontalAccuracy: b["acc"] ?? -1, verticalAccuracy: -1,
      timestamp: Date(timeIntervalSince1970: b["t"]!))
  }

  // MARK: Notification

  private func notify(id: String) {
    let content = UNMutableNotificationContent()
    content.title = "Looks like you parked"
    content.body = "Tap to save this spot and pick your car."
    content.sound = .default
    content.userInfo = ["park_id": id]
    content.interruptionLevel = .timeSensitive
    UNUserNotificationCenter.current().add(
      UNNotificationRequest(identifier: "park-\(id)", content: content, trigger: nil))
  }
}

/// Registers the MethodChannel used by NativeBackgroundSource (Dart).
enum ParkChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "app.parked/background", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "start": ParkDetector.shared.start(); result(nil)
      case "stop": ParkDetector.shared.stop(); result(nil)
      case "drainDetected": result(ParkDetector.shared.drain())
      case "launchedFromPark": result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }
}
