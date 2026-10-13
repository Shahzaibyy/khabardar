package pk.khabardar.app.alerts

/** English / Urdu copy for notifications and overlays drawn outside Flutter. */
object NativeStrings {
    private val strings = mapOf(
        "callBlockedTitle" to ("Scam call blocked" to "فراڈ کال بلاک کر دی گئی"),
        "callWarnTitle" to ("Likely scam call" to "ممکنہ فراڈ کال"),
        "callText" to ("%s is reported as a %s scam. Never share your OTP or PIN." to
            "%s کو %s فراڈ کے طور پر رپورٹ کیا گیا ہے۔ اپنا او ٹی پی یا پن کبھی نہ بتائیں۔"),
        "smsTitle" to ("Scam message from %s" to "%s کی طرف سے فراڈ پیغام"),
        "smsSuspiciousTitle" to ("Suspicious message from %s" to "%s کی طرف سے مشکوک پیغام"),
        "smsText" to ("Khabardar flagged this as a possible %s scam. Do not reply, pay or share codes." to
            "خبردار نے اسے ممکنہ %s فراڈ قرار دیا ہے۔ جواب، ادائیگی یا کوڈ شیئر نہ کریں۔"),
        "bankTitle" to ("Stop: a flagged caller is on the line" to "رکیں: مشکوک کالر لائن پر ہے"),
        "bankText" to ("Scammers keep you talking while you send money or read out a code. No real bank, BISP or police officer will ask you to do this." to
            "فراڈیے آپ کو باتوں میں لگا کر پیسے بھجواتے یا کوڈ پوچھتے ہیں۔ کوئی بینک، بی آئی ایس پی یا پولیس ایسا نہیں کہتی۔"),
        "bankClose" to ("Close wallet app" to "والٹ ایپ بند کریں"),
        "bankHelpline" to ("Call my bank's official helpline" to "بینک کی سرکاری ہیلپ لائن پر کال کریں"),
        "bankContinue" to ("I know this caller · continue in %d s" to "میں کالر کو جانتا ہوں · %d سیکنڈ"),
        "bankContinueNow" to ("I know this caller · continue" to "میں کالر کو جانتا ہوں · جاری رکھیں"),
        "bankNotifTitle" to ("Banking alert shown" to "بینکنگ الرٹ دکھایا گیا"),
        "guardTitle" to ("Banking guard is on" to "بینکنگ گارڈ آن ہے"),
        "guardText" to ("Watching for wallet apps after a scam call" to "فراڈ کال کے بعد والٹ ایپس پر نظر"),
        "dismiss" to ("Dismiss" to "بند کریں"),
        "urduWarning" to ("ہوشیار! کسی کو بھی اپنا او ٹی پی یا پن نہ بتائیں۔" to "ہوشیار! کسی کو بھی اپنا او ٹی پی یا پن نہ بتائیں۔"),
        "cat_bisp" to ("BISP / Ehsaas" to "بی آئی ایس پی / احساس"),
        "cat_bank" to ("bank / wallet" to "بینک / والٹ"),
        "cat_prize" to ("prize / lottery" to "انعام / لاٹری"),
        "cat_official" to ("police / official" to "پولیس / سرکاری"),
        "cat_courier" to ("courier / parcel" to "کوریئر / پارسل"),
        "cat_other" to ("phone" to "فون"),
        "cat_blocked_by_you" to ("blocked" to "بلاک شدہ"),
    )

    fun t(key: String, urdu: Boolean, vararg args: Any): String {
        val pair = strings[key] ?: return key
        val s = if (urdu) pair.second else pair.first
        return if (args.isEmpty()) s else String.format(s, *args)
    }

    fun category(id: String?, urdu: Boolean) = t("cat_${id ?: "other"}", urdu)
}
