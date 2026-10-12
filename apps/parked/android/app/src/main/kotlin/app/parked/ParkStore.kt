package app.parked

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Parks detected while Flutter was not running, awaiting pickup by Dart. */
object ParkStore {
    private const val PREFS = "parked_native"
    private const val KEY_PENDING = "pending"
    const val KEY_VEHICLE_ENTER = "last_vehicle_enter_ms"
    const val KEY_VEHICLE_EXIT = "last_vehicle_exit_ms"

    private fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    @Synchronized
    fun add(c: Context, id: String, lat: Double, lng: Double, accuracy: Float?, parkedAtMillis: Long) {
        val arr = JSONArray(prefs(c).getString(KEY_PENDING, "[]"))
        arr.put(JSONObject().apply {
            put("id", id); put("lat", lat); put("lng", lng)
            if (accuracy != null) put("accuracy", accuracy.toDouble())
            put("parkedAtMillis", parkedAtMillis)
        })
        prefs(c).edit().putString(KEY_PENDING, arr.toString()).apply()
    }

    /** Returns pending parks as maps for the MethodChannel and clears them. */
    @Synchronized
    fun drain(c: Context): List<Map<String, Any?>> {
        val arr = JSONArray(prefs(c).getString(KEY_PENDING, "[]"))
        prefs(c).edit().remove(KEY_PENDING).apply()
        return (0 until arr.length()).map { i ->
            val o = arr.getJSONObject(i)
            mapOf(
                "id" to o.getString("id"),
                "lat" to o.getDouble("lat"),
                "lng" to o.getDouble("lng"),
                "accuracy" to if (o.has("accuracy")) o.getDouble("accuracy") else null,
                "parkedAtMillis" to o.getLong("parkedAtMillis"),
            )
        }
    }

    fun setLong(c: Context, key: String, v: Long) = prefs(c).edit().putLong(key, v).apply()
    fun getLong(c: Context, key: String): Long = prefs(c).getLong(key, 0L)
}
