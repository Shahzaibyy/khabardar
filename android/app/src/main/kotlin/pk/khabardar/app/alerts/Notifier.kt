package pk.khabardar.app.alerts

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import pk.khabardar.app.MainActivity
import pk.khabardar.app.R

/** Posts scam alerts. Tapping one opens the event in the app. */
object Notifier {
    const val CHANNEL_ALERTS = "scam_alerts"
    const val CHANNEL_GUARD = "banking_guard"
    const val EXTRA_EVENT_ID = "khabardar_event_id"

    fun ensureChannels(context: Context) {
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_ALERTS, "Scam alerts", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Warnings about scam calls and messages"
            },
        )
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_GUARD, "Banking guard", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Shown while Khabardar watches for wallet apps after a scam call"
            },
        )
    }

    fun canNotify(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    fun openEventIntent(context: Context, eventId: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra(EXTRA_EVENT_ID, eventId)
        return PendingIntent.getActivity(
            context,
            eventId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun alert(context: Context, eventId: String, title: String, text: String) {
        if (!canNotify(context)) return
        ensureChannels(context)
        val n = Notification.Builder(context, CHANNEL_ALERTS)
            .setSmallIcon(R.drawable.ic_stat_khabardar)
            .setColor(0xFFC2410C.toInt())
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setCategory(Notification.CATEGORY_MESSAGE)
            .setAutoCancel(true)
            .setContentIntent(openEventIntent(context, eventId))
            .build()
        context.getSystemService(NotificationManager::class.java).notify(eventId.hashCode(), n)
    }
}
