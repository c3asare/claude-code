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
