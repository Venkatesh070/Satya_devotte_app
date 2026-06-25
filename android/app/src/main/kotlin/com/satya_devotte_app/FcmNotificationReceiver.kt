package com.satya_devotte_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingStore

class FcmNotificationReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "FcmNotifRcvr"
        private const val PUSH_CHANNEL_ID = "satya_default"
        private const val PUSH_CHANNEL_NAME = "Satya notifications"
        private const val PUSH_CHANNEL_DESC = "General app notifications"
        private const val BASE_NOTIFICATION_ID = 1001
    }

    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras ?: run {
            Log.w(TAG, "No extras")
            return
        }
        try {
            val remoteMessage = RemoteMessage(extras)
            val data: Map<String, String> = remoteMessage.data
            val notif = remoteMessage.notification

            val title = data["title"] ?: notif?.title ?: "Satya"
            val body = data["body"] ?: notif?.body ?: ""
            if (body.isEmpty() && title == "Satya") {
                Log.d(TAG, "No content, skipping")
                return
            }

            Log.d(TAG, "title=$title body=${body.take(30)} hasNotif=${notif != null} dataSz=${data.size}")

            if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) {
                Log.w(TAG, "Permission denied")
                return
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    PUSH_CHANNEL_ID,
                    PUSH_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = PUSH_CHANNEL_DESC
                    enableVibration(true)
                    setShowBadge(true)
                }
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.createNotificationChannel(channel)
            }

            val tapIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                tapIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notifId = BASE_NOTIFICATION_ID + (remoteMessage.messageId?.hashCode() ?: 0)
            val notification = NotificationCompat.Builder(context, PUSH_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_popup_reminder)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .build()

            NotificationManagerCompat.from(context).notify(notifId, notification)
            Log.d(TAG, "Shown id=$notifId")

            FlutterFirebaseMessagingStore.getInstance().storeFirebaseMessage(remoteMessage)

            try {
                java.io.File("/data/local/tmp/satya_pending.json").delete()
            } catch (_: Exception) {}
        } catch (e: Exception) {
            Log.e(TAG, "Error", e)
        }
    }
}
