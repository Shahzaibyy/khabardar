package pk.khabardar.app.detection

/** E.164 normalisation for Pakistan. Must match `lib/detection/normalizer.dart`. */
object PhoneNormalizer {
    fun normalize(raw: String): String {
        val trimmed = raw.trim()
        val digits = trimmed.filter { it in '0'..'9' }
        if (digits.isEmpty()) return ""
        if (digits.startsWith("0092")) return "+92" + digits.substring(4)
        if (digits.startsWith("92") && digits.length == 12) return "+$digits"
        if (digits.startsWith("03") && digits.length == 11) return "+92" + digits.substring(1)
        if (digits.startsWith("3") && digits.length == 10) return "+92$digits"
        // Short codes (8171) and foreign numbers keep their digits.
        return if (trimmed.startsWith("+")) "+$digits" else digits
    }

    /** 0300 1234567 for Pakistani mobiles, otherwise the input. */
    fun format(raw: String): String {
        val n = normalize(raw)
        if (n.startsWith("+92") && n.length == 13) {
            val local = "0" + n.substring(3)
            return local.substring(0, 4) + " " + local.substring(4)
        }
        return raw
    }
}

/** Removes secrets before message text is stored. Must match `masking.dart`. */
object Masking {
    private val CNIC = Regex("\\b\\d{5}-?\\d{7}-?\\d\\b")
    private val IBAN = Regex("\\bPK\\d{2}[A-Z]{4}\\d{16}\\b", RegexOption.IGNORE_CASE)
    private val LONG_NUMBER = Regex("\\b\\d{10,19}\\b")
    private val CODE = Regex("\\b\\d{4,8}\\b")

    fun mask(text: String): String {
        var out = CNIC.replace(text, "•••••-•••••••-•")
        out = IBAN.replace(out, "PK•• •••• ••••")
        out = LONG_NUMBER.replace(out) { "•".repeat(it.value.length) }
        out = CODE.replace(out) { if (it.value == "8171") it.value else "•".repeat(it.value.length) }
        return out
    }
}
