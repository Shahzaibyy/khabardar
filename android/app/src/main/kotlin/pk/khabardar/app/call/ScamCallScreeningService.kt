package pk.khabardar.app.call

import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import pk.khabardar.app.alerts.NativeStrings
import pk.khabardar.app.alerts.Notifier
import pk.khabardar.app.alerts.OverlayController
import pk.khabardar.app.data.ShieldStore
import pk.khabardar.app.detection.PhoneNormalizer
import pk.khabardar.app.detection.Risk
import pk.khabardar.app.detection.ThreatEngine
import pk.khabardar.app.guard.BankingGuardService

/**
 * Screens incoming calls before they ring. Android binds this service once
 * the user gives Khabardar the Call Screening role (Android 10+).
 *
 * The number is checked against the offline threat set in memory; nothing
 * is sent over the network.
 */
class ScamCallScreeningService : CallScreeningService() {

    override fun onScreenCall(details: Call.Details) {
        val allow = CallResponse.Builder().build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            details.callDirection != Call.Details.DIRECTION_INCOMING
        ) {
            respondToCall(details, allow)
            return
        }
        val number = details.handle?.schemeSpecificPart.orEmpty()
        if (number.isEmpty()) {
            respondToCall(details, allow)
            return
        }

        val store = ShieldStore.get(this)
        val verdict = runCatching {
            ThreatEngine.get(this).checkNumber(number, store.blockedHashes())
        }.getOrNull()
        if (verdict == null || verdict.risk != Risk.SCAM) {
            respondToCall(details, allow)
            return
        }

        val block = store.setting("blockScamCalls")
        val response = if (block) {
            CallResponse.Builder()
                .setDisallowCall(true)
                .setRejectCall(true)
                .setSkipCallLog(false)
                .setSkipNotification(true)
                .build()
        } else {
            allow
        }
        respondToCall(details, response)

        val category = verdict.category ?: "other"
        val event = store.addEvent(
            type = "call",
            number = PhoneNormalizer.normalize(number),
            level = verdict.risk.id,
            category = category,
            reasons = verdict.reasons,
            blocked = block,
        )
        val urdu = store.urdu
        val title = NativeStrings.t(if (block) "callBlockedTitle" else "callWarnTitle", urdu)
        val text = NativeStrings.t(
            "callText", urdu, PhoneNormalizer.format(number), NativeStrings.category(category, urdu),
        )
        Notifier.alert(this, event["id"] as String, title, text)

        if (!block) {
            if (store.setting("warnSuspiciousCalls")) {
                OverlayController.showCallBanner(this, number, category, verdict.reports)
            }
            // The call may connect: watch for wallet apps for a while.
            store.markRisk(PhoneNormalizer.normalize(number), category)
            BankingGuardService.start(this)
        }
    }
}
