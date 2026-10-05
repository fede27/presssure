package com.fscarel.presssure

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver

/**
 * Brings reminders closer to their time without the exact alarm permission.
 *
 * Android delivers an inexact alarm within a window after its time: 75% of
 * how far ahead it was set, at most one hour. A reminder set days ahead can
 * come up to an hour late. A "hop" wakes up before each reminder, closer
 * every time; once within [CLOSE_MS] it sets the reminders again, so their
 * window shrinks to about ten minutes. All with the app closed.
 */
object ReminderHops {
    /** Within this, reminders are set again: window at most ~10 minutes. */
    const val CLOSE_MS = 13 * 60_000L

    /** First hop on Android 12+, where a window is at most an hour. */
    const val LEAD_MS = 75 * 60_000L

    private const val PREFS = "reminder_hops"
    private const val TARGETS = "targets"
    private const val REQUEST_CODE = 0x4f50

    /**
     * When to wake up next on the way to [target], or null when it is close
     * enough to set the reminders again now. A hop set at the returned time
     * goes off by [target] at the latest, whatever the window.
     */
    fun nextHop(now: Long, target: Long, windowCappedAtHour: Boolean): Long? {
        val left = target - now
        if (left <= CLOSE_MS) return null
        // Set far ahead, the hour cap brings it by target - 15 minutes.
        if (windowCappedAtHour && left > LEAD_MS + 60_000L) return target - LEAD_MS
        // Set at now + left / 1.75: its window (0.75 of that) ends at target.
        return now + (left / 1.75).toLong()
    }

    /** The times of the reminders now scheduled, from the app. */
    fun setTargets(context: Context, targets: List<Long>) {
        prefs(context).edit()
            .putString(TARGETS, targets.sorted().joinToString(","))
            .apply()
        arm(context)
    }

    /** Sets the reminders again if one is close, then the next hop. */
    fun arm(context: Context) {
        val now = System.currentTimeMillis()
        val targets = load(context).filter { it > now }
        prefs(context).edit().putString(TARGETS, targets.joinToString(",")).apply()

        val capped = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
        var refresh = false
        var hop: Long? = null
        for (target in targets) {
            hop = nextHop(now, target, capped)
            if (hop != null) break
            refresh = true
        }
        // The notification plugin sets all its alarms again from now: the
        // close ones get a short window, the others stay as they were.
        if (refresh) {
            ScheduledNotificationBootReceiver().onReceive(
                context,
                Intent(Intent.ACTION_MY_PACKAGE_REPLACED),
            )
        }

        val alarms = context.getSystemService(AlarmManager::class.java)
        val pending = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            Intent(context, ReminderHopReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        if (hop == null) {
            alarms.cancel(pending)
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, hop, pending)
        }
    }

    private fun load(context: Context): List<Long> =
        prefs(context).getString(TARGETS, "").orEmpty()
            .split(",")
            .mapNotNull { it.toLongOrNull() }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}

/** A hop, or the phone restarted / the app updated: hops are set again. */
class ReminderHopReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        ReminderHops.arm(context)
    }
}
