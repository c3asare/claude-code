# Parked: architecture and package choices

Status: scaffold written by hand; **not compiled** (no Flutter SDK in the authoring environment). First steps on a dev machine:

```
flutter create --platforms=ios,android,macos,windows apps/parked --project-name parked   # generates platform folders only; keep our lib/ and pubspec
flutter pub get
cd packages/parked_data && dart run build_runner build
cd ../parked_core && dart test        # pure Dart, should pass first
cd ../../apps/parked && flutter test
```
Package versions in the pubspecs are best guesses; run `flutter pub upgrade --major-versions`.

## Layers (Dart pub workspace)

| Package | Depends on | Platform | Role |
|---|---|---|---|
| `parked_core` | nothing | pure Dart | Models, ports (interfaces), park-transition state machine, sweeping planner, point-in-polygon, in-memory repos |
| `parked_sensing` | core | iOS/Android only | Implements `ActivitySource` / `LocationSource` |
| `parked_data` | core | all | Drift/SQLite schema + repository impls |
| `apps/parked` | all | all | Riverpod state, flutter_map UI, composition roots |

Leak prevention: `parked_sensing` is imported only by `lib/main_mobile.dart` and `lib/bootstrap/mobile_detector.dart`. `main_desktop.dart` never touches it. `test/layering_test.dart` fails CI if that breaks or if core imports Flutter.

## Detection design

- The OS does the sensing (Android Activity Recognition, iOS Core Motion). Dart never polls accelerometer/gyro, and GPS is a **single one-shot fix** at confirmation time.
- `ParkTransitionEngine` debounces: vehicle -> walking confirms in 20 s; vehicle -> still needs 3 min (red lights). Park timestamp = last vehicle sample.
- Result is a *pending* `ParkEvent` (carId null) -> "Which car is this?" sheet.
- **Biggest risk, spike first on real devices:** `flutter_activity_recognition` streams only while the process lives. Surviving app kill needs (Android) a foreground service or Activity Transition API receiver, and (iOS) significant-location-change / CLVisit wake-ups, which have no mainstream Flutter plugin. Budget a small native module per platform. Fallback: `flutter_background_geolocation` (Transistorsoft), which does motion-triggered stationary detection robustly; its Android release license is paid.

## Background operation (app closed)

The prompt is a system notification (`ParkNotifier` port, `LocalParkNotifier` impl), so it shows with the app foreground, backgrounded, or woken headlessly. Tap opens the "Which car is this?" sheet; ignoring it discards the pending event. Making detection survive app termination is native work inside `parked_sensing` only; core, data, and UI do not change.

**Android (most reliable path)**
- Register for the Activity Recognition **Transition API** (`IN_VEHICLE` exit, `WALKING`/`STILL` enter) with a PendingIntent to a manifest-declared BroadcastReceiver. The OS delivers it even after the app is swiped away, with no always-on service and minimal battery.
- The receiver enqueues a WorkManager job (or short foreground service) that spins up a headless Flutter engine, runs `ParkTransitionEngine`, takes one fix, writes the pending event, and posts the notification. Needs the repository to be Drift (the in-memory one dies with the process).
- Permissions: `ACTIVITY_RECOGNITION`, `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION` (separate prompt on Android 10+), `POST_NOTIFICATIONS` (13+). Re-register on boot (`RECEIVE_BOOT_COMPLETED`).
- OEM battery killers (Xiaomi, Samsung, etc.) can still suppress it; surface a "battery optimization" onboarding step. A persistent foreground-service notification is the heavy fallback if testing shows missed parks.

**iOS (cannot run continuously; it gets relaunched)**
- Request **Always** location. Use significant-location-change and/or `CLVisit` monitoring: the system relaunches the app in the background when you move or dwell, even after a force-quit-free termination (a user force-quit stops relaunch until next manual open).
- On wake, query `CMMotionActivityManager.queryActivityStarting(from:to:)` for recent history to find the last automotive -> walking/stationary transition, then take one location fix and post the notification. History query means no always-on process is needed.
- Expect App Review scrutiny of "Always" location; the purpose strings must say it detects where you parked.
- Detection can lag by minutes (relaunch is system-scheduled), so the notification may arrive after you've walked away. That is a platform limit, not a bug.

Build order: (1) Drift repos, (2) Android Transition receiver + headless engine, (3) iOS Visits + Core Motion history, (4) battery onboarding. Test on physical devices; simulators cannot validate any of this.

## Package tradeoffs

**Activity recognition**
- `flutter_activity_recognition`: free, both OSes, simple stream. Foreground-bound; see risk above. Recommended starting point.
- `activity_recognition_flutter`: similar, Android-leaning; less maintained iOS path.
- `flutter_background_geolocation`: best reliability and battery tuning, paid on Android release, heavier. Pick if the spike fails.
- Custom platform channels (Core Motion/Visits, Transition API): most control and best battery, most work. Likely end state for the background-wake piece.

**Geolocation**: `geolocator` (BSD, mature, one-shot + stream, last-known) is recommended. `location` is comparable but less active. Background streaming is deliberately avoided.

**Maps**
- `flutter_map` (+`latlong2`): pure Dart, **works on desktop**, no vendor key, any tile source. Cost: you provision tiles (OSM public tiles are not for production; use MapTiler/Stadia/self-host) and polish gestures/clustering yourself. **Recommended** because of the desktop requirement.
- `google_maps_flutter`: best polish, no Windows/macOS support. Would force a second map implementation for desktop.
- `mapbox_maps_flutter`: great vector maps, mobile only, usage billing.
- `maplibre`-based plugins: vector tiles, desktop story still immature.

**Persistence**: `drift` (typed SQL, reactive streams, desktop OK) over Isar/Hive; sweeping data wants relational queries and bbox prefilter. **State**: Riverpod. **Alerts**: `flutter_local_notifications` + `timezone` (schedule locally from `SweepingPlanner`; no server push needed).

## Sweeping data plan (see research notes)

Bundled per-city snapshot -> optional server cache with ETag -> on-device bbox prefilter then point-in-polygon. Never send user location to a live API. LA candidates (unverified, could not reach them from the sandbox): Socrata `krk7-ayq2` (CC0, last modified 2020) and ArcGIS `Biweekly_Routes_2021` FeatureServer. LA moved to **biweekly** sweeping in 2021 while signs still read weekly, so `weeksOfMonth` is a first-class field. Long Beach has no confirmed open layer; may need a Public Records request or per-street table.

## Data model

`Car` -> `ParkEvent` (carId nullable = pending; `source` auto/manual; optional sweepingScheduleId) -> `SweepingSchedule` (cityCode, routeId, weekday + week-of-month sets, minute window, side, holiday skipDates, polygon). Drift tables mirror these in `parked_data/lib/src/database.dart` (bitmask columns for sets, bbox columns for prefilter).
