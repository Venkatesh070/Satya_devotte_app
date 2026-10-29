package com.satya_devotte_app

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.CalendarContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val ADD_CALENDAR_EVENT_REQUEST = 9912
        private const val CALENDAR_CHANNEL = "com.sathya.app/calendar"
        // Calendar apps often finish with RESULT_CANCELED even after Save.
        // We verify by checking whether a matching event was newly written.
        private const val VERIFY_DELAY_MS = 450L
    }

    private lateinit var updateManager: UpdateManager
    private var pendingCalendarResult: MethodChannel.Result? = null
    private var pendingTitle: String = ""
    private var pendingStartMs: Long = 0L
    private var pendingEndMs: Long = 0L
    private var existingEventIds: Set<Long> = emptySet()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        updateManager = UpdateManager(this)
        updateManager.checkForFlexibleUpdate()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALENDAR_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "addEvent") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (pendingCalendarResult != null) {
                result.error("BUSY", "A calendar add is already in progress.", null)
                return@setMethodCallHandler
            }

            val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
            val title = args["title"] as? String ?: ""
            val description = args["description"] as? String ?: ""
            val location = args["location"] as? String ?: "Sathya App"
            val startMs = (args["startDate"] as? Number)?.toLong() ?: 0L
            val endMs = (args["endDate"] as? Number)?.toLong() ?: 0L
            val allDay = args["allDay"] as? Boolean ?: true

            pendingTitle = title
            pendingStartMs = startMs
            pendingEndMs = if (endMs > startMs) endMs else startMs + 86_400_000L
            existingEventIds = findMatchingEventIds(title, pendingStartMs, pendingEndMs)

            val intent = Intent(Intent.ACTION_INSERT).apply {
                data = CalendarContract.Events.CONTENT_URI
                putExtra(CalendarContract.Events.TITLE, title)
                putExtra(CalendarContract.Events.DESCRIPTION, description)
                putExtra(CalendarContract.Events.EVENT_LOCATION, location)
                putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startMs)
                putExtra(CalendarContract.EXTRA_EVENT_END_TIME, pendingEndMs)
                putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, allDay)
            }

            pendingCalendarResult = result
            try {
                @Suppress("DEPRECATION")
                startActivityForResult(intent, ADD_CALENDAR_EVENT_REQUEST)
            } catch (e: Exception) {
                clearPendingCalendarAdd()
                result.success(false)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        if (::updateManager.isInitialized) {
            updateManager.checkResumeUpdate()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::updateManager.isInitialized) {
            updateManager.unregisterListener()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == ADD_CALENDAR_EVENT_REQUEST) {
            val pending = pendingCalendarResult
            val title = pendingTitle
            val startMs = pendingStartMs
            val endMs = pendingEndMs
            val before = existingEventIds
            clearPendingCalendarAdd()

            // Delay briefly so the calendar provider can commit the write.
            Handler(Looper.getMainLooper()).postDelayed({
                val saved = hasNewMatchingEvent(title, startMs, endMs, before)
                pending?.success(saved)
            }, VERIFY_DELAY_MS)
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
        if (::updateManager.isInitialized) {
            updateManager.handleUpdateResult(requestCode, resultCode)
        }
    }

    private fun clearPendingCalendarAdd() {
        pendingCalendarResult = null
        pendingTitle = ""
        pendingStartMs = 0L
        pendingEndMs = 0L
        existingEventIds = emptySet()
    }

    private fun hasNewMatchingEvent(
        title: String,
        startMs: Long,
        endMs: Long,
        beforeIds: Set<Long>,
    ): Boolean {
        if (title.isBlank()) return false
        val afterIds = findMatchingEventIds(title, startMs, endMs)
        return afterIds.any { it !in beforeIds }
    }

    private fun findMatchingEventIds(title: String, startMs: Long, endMs: Long): Set<Long> {
        // All-day / timezone quirks: widen the window around the requested range.
        val windowStart = startMs - 12L * 60L * 60L * 1000L
        val windowEnd = endMs + 12L * 60L * 60L * 1000L
        val ids = mutableSetOf<Long>()
        try {
            contentResolver.query(
                CalendarContract.Events.CONTENT_URI,
                arrayOf(CalendarContract.Events._ID, CalendarContract.Events.DTSTART),
                "${CalendarContract.Events.TITLE}=? AND ${CalendarContract.Events.DTSTART}>=? AND ${CalendarContract.Events.DTSTART}<=?",
                arrayOf(title, windowStart.toString(), windowEnd.toString()),
                null,
            )?.use { cursor ->
                val idIdx = cursor.getColumnIndex(CalendarContract.Events._ID)
                if (idIdx < 0) return emptySet()
                while (cursor.moveToNext()) {
                    ids.add(cursor.getLong(idIdx))
                }
            }
        } catch (_: SecurityException) {
            // READ_CALENDAR not granted — cannot verify.
        } catch (_: Exception) {
        }
        return ids
    }
}
