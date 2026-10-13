package pk.khabardar.app.data

import android.content.Context
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Everything the shield keeps on the phone: settings, history, the user's
 * blocked hashes and queued reports.
 *
 * Kept in app-private storage, so other apps cannot read it, and excluded
 * from backups (see `res/xml/backup_rules.xml`). Only hashes and masked text
 * are stored, never raw contacts, call logs or full messages.
 */
class ShieldStore private constructor(context: Context) {

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences("khabardar_store", Context.MODE_PRIVATE)

    // ---- Settings -------------------------------------------------------

    fun settings(): Map<String, Any> {
        val o = JSONObject(prefs.getString(KEY_SETTINGS, "{}")!!)
        return mapOf(
            "blockScamCalls" to o.optBoolean("blockScamCalls", true),
            "warnSuspiciousCalls" to o.optBoolean("warnSuspiciousCalls", true),
            "smsShield" to o.optBoolean("smsShield", true),
            "bankingAlerts" to o.optBoolean("bankingAlerts", true),
            "wifiOnlyUpdates" to o.optBoolean("wifiOnlyUpdates", false),
            "language" to o.optString("language", "en"),
            "onboarded" to o.optBoolean("onboarded", false),
        )
    }

    fun saveSettings(values: Map<*, *>) {
        val o = JSONObject()
        values.forEach { (k, v) -> if (k is String) o.put(k, v) }
        prefs.edit().putString(KEY_SETTINGS, o.toString()).apply()
    }

    fun setting(key: String): Boolean = settings()[key] as? Boolean ?: true

    val urdu: Boolean get() = settings()["language"] == "ur"

    // ---- Events ---------------------------------------------------------

    fun events(): List<Map<String, Any>> {
        val a = JSONArray(prefs.getString(KEY_EVENTS, "[]")!!)
        return (0 until a.length()).map { toMap(a.getJSONObject(it)) }
    }

    fun event(id: String): Map<String, Any>? = events().firstOrNull { it["id"] == id }

    /** Records an event, newest first, and pushes it to the UI if open. */
    fun addEvent(
        type: String,
        number: String,
        level: String,
        category: String,
        preview: String = "",
        reasons: List<String> = emptyList(),
        blocked: Boolean = false,
    ): Map<String, Any> {
        val o = JSONObject()
            .put("id", UUID.randomUUID().toString())
            .put("type", type)
            .put("number", number)
            .put("level", level)
            .put("category", category)
            .put("timestamp", System.currentTimeMillis())
            .put("preview", preview)
            .put("reasons", JSONArray(reasons))
            .put("blocked", blocked)
        synchronized(this) {
            val old = JSONArray(prefs.getString(KEY_EVENTS, "[]")!!)
            val next = JSONArray().put(o)
            for (i in 0 until minOf(old.length(), MAX_EVENTS - 1)) next.put(old.getJSONObject(i))
            prefs.edit().putString(KEY_EVENTS, next.toString()).apply()
        }
        val map = toMap(o)
        main.post { listener?.invoke(map) }
        return map
    }

    fun deleteEvent(id: String) = synchronized(this) {
        val old = JSONArray(prefs.getString(KEY_EVENTS, "[]")!!)
        val next = JSONArray()
        for (i in 0 until old.length()) {
            val e = old.getJSONObject(i)
            if (e.optString("id") != id) next.put(e)
        }
        prefs.edit().putString(KEY_EVENTS, next.toString()).apply()
    }

    // ---- Blocked numbers (hashes only) ---------------------------------

    fun blockedHashes(): Set<String> = prefs.getStringSet(KEY_BLOCKED, emptySet())!!.toSet()

    fun block(hash: String) = prefs.edit().putStringSet(KEY_BLOCKED, blockedHashes() + hash).apply()

    fun unblock(hash: String) = prefs.edit().putStringSet(KEY_BLOCKED, blockedHashes() - hash).apply()

    // ---- Reports waiting for the backend --------------------------------

    fun queueReport(report: Map<*, *>) = synchronized(this) {
        val a = JSONArray(prefs.getString(KEY_REPORTS, "[]")!!)
        val o = JSONObject()
        report.forEach { (k, v) -> if (k is String) o.put(k, v) }
        a.put(o)
        prefs.edit().putString(KEY_REPORTS, a.toString()).apply()
    }

    fun pendingReports(): Int = JSONArray(prefs.getString(KEY_REPORTS, "[]")!!).length()

    // ---- Risk window for the banking guard ------------------------------

    /** Marks that a scam call or SMS just happened, opening the guard window. */
    fun markRisk(number: String, category: String) {
        prefs.edit()
            .putLong(KEY_RISK_AT, System.currentTimeMillis())
            .putString(KEY_RISK_NUMBER, number)
            .putString(KEY_RISK_CATEGORY, category)
            .apply()
    }

    fun riskAt(): Long = prefs.getLong(KEY_RISK_AT, 0)
    fun riskNumber(): String = prefs.getString(KEY_RISK_NUMBER, "") ?: ""
    fun riskCategory(): String = prefs.getString(KEY_RISK_CATEGORY, "other") ?: "other"

    // ---- Notification tap -> open the event in the app ------------------

    fun setLaunchEvent(id: String?) = prefs.edit().putString(KEY_LAUNCH, id).apply()

    fun consumeLaunchEvent(): Map<String, Any>? {
        val id = prefs.getString(KEY_LAUNCH, null) ?: return null
        setLaunchEvent(null)
        return event(id)
    }

    fun deleteAll() {
        val keepSettings = prefs.getString(KEY_SETTINGS, "{}")
        prefs.edit().clear().putString(KEY_SETTINGS, keepSettings).apply()
    }

    private fun toMap(o: JSONObject): Map<String, Any> {
        val reasons = o.optJSONArray("reasons") ?: JSONArray()
        return mapOf(
            "id" to o.optString("id"),
            "type" to o.optString("type"),
            "number" to o.optString("number"),
            "level" to o.optString("level"),
            "category" to o.optString("category"),
            "timestamp" to o.optLong("timestamp"),
            "preview" to o.optString("preview"),
            "reasons" to (0 until reasons.length()).map { reasons.getString(it) },
            "blocked" to o.optBoolean("blocked"),
        )
    }

    companion object {
        private const val KEY_SETTINGS = "settings"
        private const val KEY_EVENTS = "events"
        private const val KEY_BLOCKED = "blocked_hashes"
        private const val KEY_REPORTS = "pending_reports"
        private const val KEY_RISK_AT = "risk_at"
        private const val KEY_RISK_NUMBER = "risk_number"
        private const val KEY_RISK_CATEGORY = "risk_category"
        private const val KEY_LAUNCH = "launch_event"
        private const val MAX_EVENTS = 200

        private val main = Handler(Looper.getMainLooper())

        /** Set by the Flutter event channel while the UI is listening. */
        @Volatile var listener: ((Map<String, Any>) -> Unit)? = null

        @Volatile private var instance: ShieldStore? = null

        fun get(context: Context): ShieldStore =
            instance ?: synchronized(this) {
                instance ?: ShieldStore(context).also { instance = it }
            }
    }
}
