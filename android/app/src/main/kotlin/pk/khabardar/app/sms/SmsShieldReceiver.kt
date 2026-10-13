package pk.khabardar.app.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import pk.khabardar.app.alerts.NativeStrings
import pk.khabardar.app.alerts.Notifier
import pk.khabardar.app.data.ShieldStore
import pk.khabardar.app.detection.Masking
import pk.khabardar.app.detection.PhoneNormalizer
import pk.khabardar.app.detection.Risk
import pk.khabardar.app.detection.ThreatEngine
import pk.khabardar.app.guard.BankingGuardService

/**
 * Checks each incoming SMS on the device. The text is scored in memory and
 * only a masked preview (codes, CNICs and account numbers removed) is kept.
 */
class SmsShieldReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val store = ShieldStore.get(context)
        if (!store.setting("smsShield")) return

        val parts = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
        // A long SMS arrives in parts; join them per sender.
        val bySender = LinkedHashMap<String, StringBuilder>()
        for (p in parts) {
            val sender = p?.displayOriginatingAddress ?: p?.originatingAddress ?: continue
            bySender.getOrPut(sender) { StringBuilder() }.append(p.displayMessageBody ?: "")
        }

        val pending = goAsync()
        Thread {
            try {
                val engine = ThreatEngine.get(context)
                val blocked = store.blockedHashes()
                for ((sender, body) in bySender) handle(context, store, engine, blocked, sender, body.toString())
            } finally {
                pending.finish()
            }
        }.start()
    }

    private fun handle(
        context: Context,
        store: ShieldStore,
        engine: ThreatEngine,
        blocked: Set<String>,
        sender: String,
        body: String,
    ) {
        val verdict = engine.checkMessage(body, sender, blocked)
        if (verdict.risk == Risk.SAFE) return

        val category = verdict.category ?: "other"
        val displaySender = if (sender.any { it.isLetter() }) sender else PhoneNormalizer.normalize(sender)
        val event = store.addEvent(
            type = "sms",
            number = displaySender,
            level = verdict.risk.id,
            category = category,
            preview = Masking.mask(body).take(400),
            reasons = verdict.reasons,
        )
        val urdu = store.urdu
        val shownSender = PhoneNormalizer.format(sender)
        val title = NativeStrings.t(
            if (verdict.risk == Risk.SCAM) "smsTitle" else "smsSuspiciousTitle", urdu, shownSender,
        )
        val text = NativeStrings.t("smsText", urdu, NativeStrings.category(category, urdu))
        Notifier.alert(context, event["id"] as String, title, text)

        if (verdict.risk == Risk.SCAM) {
            // Scam SMS are often followed by a call; guard wallet apps for a while.
            store.markRisk(displaySender, category)
            BankingGuardService.start(context)
        }
    }
}
