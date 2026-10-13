package pk.khabardar.app.guard

import android.app.AppOpsManager
import android.app.Notification
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Process
import android.util.Log
import pk.khabardar.app.R
import pk.khabardar.app.alerts.NativeStrings
import pk.khabardar.app.alerts.Notifier
import pk.khabardar.app.alerts.OverlayController
import pk.khabardar.app.data.ShieldStore
import pk.khabardar.app.detection.ThreatEngine

/**
 * Runs for a short window after a scam call or SMS. If a banking or wallet
 * app comes to the foreground in that window, it shows the warning sheet.
 *
 * Only the package name of the foreground app is read (Usage access); the
 * screen content of the banking app is never read.
 */
class BankingGuardService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var lastAlertedAt = 0L

    private val tick = object : Runnable {
        override fun run() {
            if (!check()) {
                stopSelf()
                return
            }
            handler.postDelayed(this, POLL_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val store = ShieldStore.get(this)
        val urdu = store.urdu
        Notifier.ensureChannels(this)
        val n = Notification.Builder(this, Notifier.CHANNEL_GUARD)
            .setSmallIcon(R.drawable.ic_stat_khabardar)
            .setContentTitle(NativeStrings.t("guardTitle", urdu))
            .setContentText(NativeStrings.t("guardText", urdu))
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, n)
        }
        handler.removeCallbacks(tick)
        handler.post(tick)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        super.onDestroy()
    }

    /** Returns false when the guard window is over. */
    private fun check(): Boolean {
        val store = ShieldStore.get(this)
        val riskAt = store.riskAt()
        if (System.currentTimeMillis() - riskAt > WINDOW_MS) return false
        if (lastAlertedAt >= riskAt) return true // one sheet per risk window

        val pkg = foregroundPackage() ?: return true
        val banking = ThreatEngine.get(this).bankingPackages
        if (pkg !in banking) return true

        lastAlertedAt = System.currentTimeMillis()
        val number = store.riskNumber()
        OverlayController.showBankingAlert(this, number)
        val event = store.addEvent(
            type = "bank_alert",
            number = number,
            level = "scam",
            category = store.riskCategory(),
            reasons = listOf("listed_number"),
        )
        Notifier.alert(
            this,
            event["id"] as String,
            NativeStrings.t("bankNotifTitle", store.urdu),
            NativeStrings.t("bankText", store.urdu),
        )
        return true
    }

    private fun foregroundPackage(): String? {
        val usm = getSystemService(UsageStatsManager::class.java) ?: return null
        val now = System.currentTimeMillis()
        val events = usm.queryEvents(now - 10_000, now)
        val e = UsageEvents.Event()
        var latest: String? = null
        while (events.hasNextEvent()) {
            events.getNextEvent(e)
            if (e.eventType == UsageEvents.Event.ACTIVITY_RESUMED) latest = e.packageName
        }
        return latest
    }

    companion object {
        private const val NOTIFICATION_ID = 7171
        private const val POLL_MS = 1_000L

        /** How long after a scam call or SMS wallet apps are guarded. */
        const val WINDOW_MS = 10 * 60 * 1000L

        fun hasUsageAccess(context: Context): Boolean {
            val ops = context.getSystemService(AppOpsManager::class.java)
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ops.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
            } else {
                @Suppress("DEPRECATION")
                ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
            }
            return mode == AppOpsManager.MODE_ALLOWED
        }

        /** Starts the guard if banking alerts are on and permitted. */
        fun start(context: Context) {
            val store = ShieldStore.get(context)
            if (!store.setting("bankingAlerts")) return
            if (!OverlayController.canDraw(context) || !hasUsageAccess(context)) return
            runCatching {
                context.startForegroundService(Intent(context, BankingGuardService::class.java))
            }.onFailure {
                // Android may refuse a background start; the alert notification still went out.
                Log.w("Khabardar", "Banking guard could not start", it)
            }
        }
    }
}
