package com.fscarel.presssure

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ReminderHopsTest {
    private val minute = 60_000L
    private val hour = 60 * minute

    /** Latest delivery of an inexact alarm set at [now] for [at]. */
    private fun latest(now: Long, at: Long, capped: Boolean): Long {
        val window = ((at - now) * 0.75).toLong()
        return at + if (capped) minOf(window, hour) else window
    }

    /** Follows the hops, each one delivered as late as Android may. */
    private fun worstCase(start: Long, target: Long, capped: Boolean): Pair<Long, Int> {
        var now = start
        var hops = 0
        while (true) {
            val hop = ReminderHops.nextHop(now, target, capped) ?: break
            assertTrue("a hop is in the future", hop > now)
            now = latest(now, hop, capped)
            assertTrue("a hop never goes off after the reminder", now <= target)
            hops++
            assertTrue("hops end", hops < 60)
        }
        return now to hops
    }

    @Test
    fun closeToTheReminder_setsItAgainNow() {
        assertNull(ReminderHops.nextHop(0, 13 * minute, true))
        assertNull(ReminderHops.nextHop(0, 5 * minute, false))
    }

    @Test
    fun daysAhead_firstHopAnHourAndAQuarterBefore() {
        val target = 3 * 24 * hour
        assertEquals(target - 75 * minute, ReminderHops.nextHop(0, target, true))
    }

    @Test
    fun theReminderEndsWithAWindowOfTenMinutesAtMost() {
        for (capped in listOf(true, false)) {
            for (ahead in listOf(14 * minute, 40 * minute, 76 * minute, 3 * hour, 7 * 24 * hour)) {
                val (last, _) = worstCase(0, ahead, capped)
                val left = ahead - last
                assertTrue("at most 13 minutes left", left <= ReminderHops.CLOSE_MS)
                assertTrue("window at most 10 minutes", left * 0.75 <= 10 * minute)
            }
        }
    }

    @Test
    fun fewHops_onAndroid12() {
        val (_, hops) = worstCase(0, 24 * hour, true)
        assertTrue("hops: $hops", hops <= 2)
    }
}
