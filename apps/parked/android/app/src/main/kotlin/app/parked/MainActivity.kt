package app.parked

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges Dart's NativeBackgroundSource (packages/parked_sensing) to the
 * native detector. Channel name must match the Dart side.
 */
class MainActivity : FlutterActivity() {
    private var launchedFrom: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        launchedFrom = intent?.getStringExtra(ParkDetection.EXTRA_PARK_ID)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.parked/background")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> { ParkDetection.start(applicationContext); result.success(null) }
                    "stop" -> { ParkDetection.stop(applicationContext); result.success(null) }
                    "drainDetected" -> result.success(ParkStore.drain(applicationContext))
                    "launchedFromPark" -> { result.success(launchedFrom); launchedFrom = null }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        launchedFrom = intent.getStringExtra(ParkDetection.EXTRA_PARK_ID)
    }
}
