package pk.khabardar.app.detection

import android.content.Context
import org.json.JSONObject
import java.util.regex.Pattern
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/** Verdict levels, matching `RiskLevel` in Dart. */
enum class Risk(val id: String) { SAFE("safe"), SUSPICIOUS("suspicious"), SCAM("scam") }

data class Verdict(
    val risk: Risk,
    val score: Int,
    val category: String?,
    val reasons: List<String> = emptyList(),
    val reports: Int = 0,
) {
    companion object {
        val SAFE = Verdict(Risk.SAFE, 0, null)
    }
}

/**
 * On-device detection, a port of `lib/detection/engine.dart`.
 *
 * Both sides read the same `assets/threat/threat_set.json`, so a call or SMS
 * is judged the same way whether or not the Flutter UI is running.
 */
class ThreatEngine private constructor(json: String) {

    private class Rule(val id: String, val category: String, val weight: Int, val regex: Pattern)
    private class Listed(val category: String, val reports: Int)

    val version: Int
    val bankingPackages: Set<String>
    private val mac: Mac
    private val scamThreshold: Int
    private val suspiciousThreshold: Int
    private val trustedSenders: Set<String>
    private val trustedDomains: List<String>
    private val numbers: Map<String, Listed>
    private val rules: List<Rule>

    init {
        val o = JSONObject(json)
        version = o.getInt("version")
        mac = Mac.getInstance("HmacSHA256").apply {
            init(SecretKeySpec(o.getString("hmacKey").toByteArray(Charsets.UTF_8), "HmacSHA256"))
        }
        scamThreshold = o.getInt("scamThreshold")
        suspiciousThreshold = o.getInt("suspiciousThreshold")
        trustedSenders = o.getJSONArray("trustedSenders").let { a -> (0 until a.length()).map { a.getString(it) }.toSet() }
        trustedDomains = o.getJSONArray("trustedDomains").let { a -> (0 until a.length()).map { a.getString(it) } }
        bankingPackages = o.getJSONArray("bankingPackages").let { a -> (0 until a.length()).map { a.getString(it) }.toSet() }
        numbers = o.getJSONArray("numbers").let { a ->
            (0 until a.length()).associate {
                val n = a.getJSONObject(it)
                n.getString("h") to Listed(n.optString("category", "other"), n.optInt("reports", 0))
            }
        }
        rules = o.getJSONArray("rules").let { a ->
            (0 until a.length()).map {
                val r = a.getJSONObject(it)
                Rule(
                    r.getString("id"),
                    r.optString("category", "other"),
                    r.getInt("weight"),
                    Pattern.compile(r.getString("pattern"), Pattern.CASE_INSENSITIVE or Pattern.UNICODE_CASE),
                )
            }
        }
    }

    /** HMAC-SHA-256 of the normalised number, as lowercase hex. */
    @Synchronized
    fun hashNumber(raw: String): String {
        val bytes = mac.doFinal(PhoneNormalizer.normalize(raw).toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }
    }

    fun checkNumber(raw: String, userBlocked: Set<String> = emptySet()): Verdict {
        val normalized = PhoneNormalizer.normalize(raw)
        // Only the exact official code is trusted; "8171-BISP" is a look-alike.
        if (normalized.isEmpty() || raw.trim() in trustedSenders) return Verdict.SAFE
        val h = hashNumber(raw)
        if (h in userBlocked) {
            return Verdict(Risk.SCAM, 100, "blocked_by_you", listOf("blocked_by_you"))
        }
        val listed = numbers[h] ?: return Verdict.SAFE
        return Verdict(Risk.SCAM, 100, listed.category, listOf("listed_number"), listed.reports)
    }

    fun checkMessage(text: String, sender: String = "", userBlocked: Set<String> = emptySet()): Verdict {
        if (sender.isNotEmpty()) {
            val byNumber = checkNumber(sender, userBlocked)
            if (byNumber.risk == Risk.SCAM) return byNumber
        }
        var score = 0
        val reasons = mutableListOf<String>()
        val byCategory = mutableMapOf<String, Int>()
        fun hit(id: String, category: String, weight: Int) {
            score += weight
            reasons += id
            byCategory[category] = (byCategory[category] ?: 0) + weight
        }

        val senderDigits = sender.filter { it.isDigit() }
        for (code in trustedSenders) {
            if (senderDigits.contains(code) && sender.trim() != code) hit("lookalike_sender", "bisp", 40)
        }

        val linksTrusted = allLinksTrusted(text)
        for (rule in rules) {
            if (linksTrusted && (rule.id == "link" || rule.id == "risky_domain")) continue
            if (rule.regex.matcher(text).find()) hit(rule.id, rule.category, rule.weight)
        }

        val risk = when {
            score >= scamThreshold -> Risk.SCAM
            score >= suspiciousThreshold -> Risk.SUSPICIOUS
            else -> Risk.SAFE
        }
        byCategory.remove("other")
        val top = byCategory.maxByOrNull { it.value }?.key ?: if (score > 0) "other" else null
        return Verdict(risk, minOf(score, 100), if (risk == Risk.SAFE) null else top, reasons)
    }

    private fun allLinksTrusted(text: String): Boolean {
        val m = URL_HOST.matcher(text)
        val hosts = mutableListOf<String>()
        while (m.find()) {
            val h = m.group(1)!!.lowercase().replace("[.]", ".")
            if (h.contains('.') && h.any { it in 'a'..'z' }) hosts += h
        }
        if (hosts.isEmpty()) return false
        return hosts.all { h -> trustedDomains.any { d -> h == d || h.endsWith(".$d") } }
    }

    companion object {
        /** Flutter packs app assets under `flutter_assets/` in the APK. */
        private const val ASSET = "flutter_assets/assets/threat/threat_set.json"

        private val URL_HOST = Pattern.compile(
            "(?:https?://)?(?:www\\.)?([a-z0-9-]+(?:(?:\\.|\\[\\.\\])[a-z0-9-]+)+)",
            Pattern.CASE_INSENSITIVE,
        )

        @Volatile private var instance: ThreatEngine? = null

        fun get(context: Context): ThreatEngine =
            instance ?: synchronized(this) {
                instance ?: ThreatEngine(
                    context.applicationContext.assets.open(ASSET).bufferedReader().use { it.readText() },
                ).also { instance = it }
            }

        /** For unit tests on the JVM. */
        fun fromJson(json: String) = ThreatEngine(json)
    }
}
