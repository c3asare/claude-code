package app.parked

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionResult
import com.google.android.gms.location.DetectedActivity
import java.util.concurrent.TimeUnit

class ActivityTransitionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!ActivityTransitionResult.hasResult(intent)) return
        val result = ActivityTransitionResult.extractResult(intent) ?: return
        val work = WorkManager.getInstance(context)

        for (e in result.transitionEvents) {
            if (e.activityType != DetectedActivity.IN_VEHICLE) continue
            // elapsedRealTimeNanos is monotonic; convert to wall-clock for storage.
            val atMillis = System.currentTimeMillis() -
                TimeUnit.NANOSECONDS.toMillis(android.os.SystemClock.elapsedRealtimeNanos() - e.elapsedRealTimeNanos)

            if (e.transitionType == ActivityTransition.ACTIVITY_TRANSITION_ENTER) {
                // Driving again: any pending "did you park?" check is moot.
                ParkStore.setLong(context, ParkStore.KEY_VEHICLE_ENTER, atMillis)
                work.cancelUniqueWork(ParkConfirmWorker.UNIQUE_NAME)
            } else {
                ParkStore.setLong(context, ParkStore.KEY_VEHICLE_EXIT, atMillis)
                // Debounce: confirm only if no new IN_VEHICLE ENTER arrives.
                work.enqueueUniqueWork(
                    ParkConfirmWorker.UNIQUE_NAME,
                    ExistingWorkPolicy.REPLACE,
                    OneTimeWorkRequestBuilder<ParkConfirmWorker>()
                        .setInitialDelay(ParkConfirmWorker.CONFIRM_DELAY_SECONDS, TimeUnit.SECONDS)
                        .build(),
                )
            }
        }
    }
}
