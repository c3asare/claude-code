# Mac mini handoff

Everything that can be built without a Mac or a phone is done. This file lists what is verified, what is not, and the exact steps to finish.

## Verified in the cloud container (Flutter 3.47, Linux)
- `parked_core`: 10 unit tests pass (park-transition debounce, sweeping planner, alert service, GeoJSON parser, point-in-polygon).
- `parked_data`: Drift schema, codegen, and 4 repository tests pass against real SQLite.
- `apps/parked`: `flutter analyze` clean in all 4 packages; 5 widget tests pass (layering guard, car icon, golden gallery, full flow: pending park -> pick car -> sweeping status -> Left).

## NOT verified (written blind, never compiled or run)
| Item | Where | Risk |
|---|---|---|
| Android Kotlin detector (Transition API receiver, WorkManager worker, boot receiver, MethodChannel) | `apps/parked/android/app/src/main/kotlin/app/parked/` | Could not install Android SDK (dl.google.com blocked). May not compile first try. |
| Android manifest + Gradle deps | `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts` | Core-library desugaring + play-services-location + work-runtime added; versions are current-as-of-writing guesses. |
| iOS Swift detector + Xcode project edit | `ios/Runner/ParkDetector.swift`, `AppDelegate.swift`, `Runner.xcodeproj/project.pbxproj` | The file was added to the pbxproj by script. If Xcode complains, drag it into the Runner group. |
| Real-world detection accuracy / battery | everything native | Needs physical devices and real drives. Simulators cannot test any of it. |
| macOS/Windows desktop run | `lib/main_desktop.dart` | Not built. macOS network entitlement added for map tiles. |

## Steps on the Mac mini
```
brew install --cask flutter   # or the SDK from flutter.dev; also install Xcode + CocoaPods
git clone <repo> && git checkout claude/parked-scaffold
flutter pub get
(cd packages/parked_data && dart run build_runner build --delete-conflicting-outputs)
(cd packages/parked_core && dart test)
(cd apps/parked && flutter test)      # golden test runs on Linux only
```
1. **iOS**: `open apps/parked/ios/Runner.xcworkspace`. Set Team and a unique Bundle ID. Confirm `ParkDetector.swift` appears under Runner and compiles. Capabilities: Background Modes -> Location updates is already in Info.plist. Run on a **physical iPhone**: `cd apps/parked && flutter run -t lib/main_mobile.dart -d <device-id>`.
2. **Android**: plug in a phone, `flutter run -t lib/main_mobile.dart`. Fix any Kotlin compile errors first. Grant "Allow all the time" location when prompted.
3. **macOS companion**: `flutter run -d macos -t lib/main_desktop.dart` (empty local DB until sync exists).
4. `pod install` issues: run `cd ios && pod repo update && pod install`.

## Device test checklist
- [ ] Permission flow: notifications, motion/activity, when-in-use, then Always. Denying Always must not crash; closed-app detection simply stays off.
- [ ] Add a car (shape + color + stripe); marker matches on the map.
- [ ] "I parked here" drops a pin, asks "Which car?", shows sweeping status.
- [ ] Foreground auto-detect: drive, park, walk away; notification appears; tap -> picker.
- [ ] **Closed-app detection (the key spike)**: swipe app away, drive, park, walk 1 min. Notification should arrive. Then open the app: the pending park appears and the sheet shows.
- [ ] Android: repeat after reboot (BootReceiver) and with battery saver on.
- [ ] iOS: expect delayed notifications (minutes) and possibly ~100-500 m position error; note real numbers.
- [ ] Sweeping alert fires at the scheduled time (use the dev sample route, Tue 2nd/4th, 8-10am; temporarily edit the JSON to today).
- [ ] "Left" cancels pending reminders.

## Known gaps / next work
1. **Real sweeping data.** `assets/sweeping/long_beach_dev_sample.geojson` is FAKE. Next: write per-city converters into the normalized GeoJSON format (see `parseSweepingGeoJson`). LA candidates are in `docs/RESEARCH.md` (unverified; need network access to data.lacity.org / ArcGIS). Long Beach needs a source.
2. **Map tiles**: OSM public tiles are dev-only. Pick MapTiler/Stadia/self-hosted before release.
3. ~~Pin adjust~~ Done: "Adjust pin" on each parked car lets you drag the map and re-plans alerts. Needs a device check.
4. **Auto "Left" detection** (departure when you start driving again). Currently manual button.
5. **Desktop sync**: companion needs a data source (cloud or file export).
6. **Exact-time alerts**: scheduler uses inexact alarms (can slip minutes in Doze). Revisit for the 1-hour reminder.
7. **Store compliance**: Google Play background-location declaration + video, Apple "Always" justification, privacy policy.
8. **Monetization**: paywall (multi-car + auto-detect paid; see `docs/RESEARCH.md`). Not started.
9. **Holiday list**: skipDates data per city.
