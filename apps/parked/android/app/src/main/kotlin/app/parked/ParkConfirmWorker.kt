package app.parked

import android.Manifest
import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import com.google.android.gms.tasks.Tasks
import java.util.UUID
import java.util.concurrent.TimeUnit

/**
 * Runs shortly after the OS reports leaving a vehicle. If the user has not
 * started driving again, takes one location fix, stores the park for Dart and
 * posts the "Looks like you parked" notification.
 */
class ParkConfirmWorker(private val ctx: Context, params: WorkerParameters) : Worker(ctx, params) {

    @SuppressLint("MissingPermission")
    override fun doWork(): Result {
        val exitAt = ParkStore.getLong(ctx, ParkStore.KEY_VEHICLE_EXIT)
        val enterAt = ParkStore.getLong(ctx, ParkStore.KEY_VEHICLE_ENTER)
        if (enterAt > exitAt) return Result.success() // driving again

        if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_FINE_LOCATION)
            != PackageManager.PERMISSION_GRANTED
        ) return Result.success()

        val client = LocationServices.getFusedLocationProviderClient(ctx)
        val cts = CancellationTokenSource()
        val loc = try {
            Tasks.await(
                client.getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, cts.token),
                20, TimeUnit.SECONDS,
            ) ?: Tasks.await(client.lastLocation, 5, TimeUnit.SECONDS)
        } catch (e: Exception) {
            cts.cancel()
            null
        } ?: return Result.retry()

        val id = UUID.randomUUID().toString()
        ParkStore.add(ctx, id, loc.latitude, loc.longitude, if (loc.hasAccuracy()) loc.accuracy else null, exitAt)
        notify(id)
        return Result.success()
    }

    private fun notify(parkId: String) {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Same id/name as LocalParkNotifier so both paths share one channel.
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Parking detected", NotificationManager.IMPORTANCE_HIGH)
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) return

        val open = PendingIntent.getActivity(
            ctx, parkId.hashCode(),
            Intent(ctx, MainActivity::class.java)
                .putExtra(ParkDetection.EXTRA_PARK_ID, parkId)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val n = NotificationCompat.Builder(ctx, CHANNEL_ID)
            .setSmallIcon(ctx.applicationInfo.icon)
            .setContentTitle("Looks like you parked")
            .setContentText("Tap to save this spot and pick your car.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(open)
            .build()
        nm.notify(parkId.hashCode(), n)
    }

    companion object {
        const val UNIQUE_NAME = "park_confirm"
        const val CHANNEL_ID = "park_detected"
        const val CONFIRM_DELAY_SECONDS = 45L
    }
}
