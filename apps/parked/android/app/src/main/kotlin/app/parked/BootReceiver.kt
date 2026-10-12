package app.parked

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Transition registrations are cleared on reboot and app update; redo them. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED ->
                ParkDetection.start(context.applicationContext)
        }
    }
}
