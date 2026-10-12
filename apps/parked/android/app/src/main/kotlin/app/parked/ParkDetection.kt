package app.parked

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionRequest
import com.google.android.gms.location.DetectedActivity

/**
 * Registers for OS-delivered activity transitions. The OS wakes
 * [ActivityTransitionReceiver] even if the app was swiped away, so nothing
 * runs continuously and battery cost is minimal.
 */
object ParkDetection {
    const val EXTRA_PARK_ID = "park_id"

    private fun pendingIntent(c: Context): PendingIntent = PendingIntent.getBroadcast(
        c, 0,
        Intent(c, ActivityTransitionReceiver::class.java),
        // MUTABLE is required: Play Services fills in the transition result.
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
    )

    private fun request(): ActivityTransitionRequest {
        fun t(activity: Int, type: Int) = ActivityTransition.Builder()
            .setActivityType(activity).setActivityTransition(type).build()
        return ActivityTransitionRequest(
            listOf(
                t(DetectedActivity.IN_VEHICLE, ActivityTransition.ACTIVITY_TRANSITION_ENTER),
                t(DetectedActivity.IN_VEHICLE, ActivityTransition.ACTIVITY_TRANSITION_EXIT),
            )
        )
    }

    /** Safe to call on every launch and after boot; re-registering replaces. */
    @SuppressLint("MissingPermission") // ACTIVITY_RECOGNITION requested from Dart.
    fun start(c: Context) {
        ActivityRecognition.getClient(c).requestActivityTransitionUpdates(request(), pendingIntent(c))
    }

    @SuppressLint("MissingPermission")
    fun stop(c: Context) {
        ActivityRecognition.getClient(c).removeActivityTransitionUpdates(pendingIntent(c))
    }
}
