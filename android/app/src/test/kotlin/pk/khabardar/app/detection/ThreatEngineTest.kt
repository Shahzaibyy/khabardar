package pk.khabardar.app.detection

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * Keeps the Kotlin engine in step with `test/detection_test.dart`: the same
 * inputs must give the same verdicts and the same hashes on both sides.
 */
class ThreatEngineTest {
    private val engine = ThreatEngine.fromJson(File("../../assets/threat/threat_set.json").readText())

    @Test fun normalizesPakistaniNumbers() {
        assertEquals("+923000000111", PhoneNormalizer.normalize("0300 0000111"))
        assertEquals("+923000000111", PhoneNormalizer.normalize("0092-300-0000111"))
        assertEquals("+923000000111", PhoneNormalizer.normalize("3000000111"))
        assertEquals("8171", PhoneNormalizer.normalize("8171"))
        assertEquals("0300 0000111", PhoneNormalizer.format("+923000000111"))
    }

    @Test fun hashMatchesDart() {
        assertEquals(
            "18ac14f2fc86b5350ac63c5e1e12516f03e4bc76a7ec7b2f23fef63d8cf12d1a",
            engine.hashNumber("0300 0000111"),
        )
    }

    @Test fun listedNumberIsScam() {
        val v = engine.checkNumber("0300-0000111")
        assertEquals(Risk.SCAM, v.risk)
        assertEquals("bisp", v.category)
        assertEquals(214, v.reports)
    }

    @Test fun unknownAndOfficialNumbersAreSafe() {
        assertEquals(Risk.SAFE, engine.checkNumber("0300 1234567").risk)
        assertEquals(Risk.SAFE, engine.checkNumber("8171").risk)
    }

    @Test fun userBlockedNumberIsScam() {
        val h = engine.hashNumber("03001234567")
        val v = engine.checkNumber("+923001234567", setOf(h))
        assertEquals("blocked_by_you", v.category)
    }

    @Test fun fakeBispSmsIsScam() {
        val v = engine.checkMessage(
            "Mubarak! Aap ki BISP raqam Rs 25,000 jari ho gayi hai. Wasooli ke liye Rs 500 fee " +
                "is link par jama karwayen: bisp-payment.xyz",
            "8171-BISP",
        )
        assertEquals(Risk.SCAM, v.risk)
        assertEquals("bisp", v.category)
        assertTrue(v.reasons.containsAll(listOf("lookalike_sender", "fee_request")))
    }

    @Test fun otpHarvestingIsScam() {
        val v = engine.checkMessage(
            "Your account will be blocked today. Share the code you received to verify immediately.",
        )
        assertEquals(Risk.SCAM, v.risk)
        assertEquals("bank", v.category)
    }

    @Test fun urduOtpRequestIsFlagged() {
        assertFalse(engine.checkMessage("آپ کا اکاؤنٹ بند ہو جائے گا، کوڈ بتائیں").risk == Risk.SAFE)
    }

    @Test fun ordinaryMessageIsSafe() {
        val v = engine.checkMessage("Kal shaam 7 baje milte hain, theek hai?")
        assertEquals(Risk.SAFE, v.risk)
        assertTrue(v.reasons.isEmpty())
    }

    @Test fun trustedGovLinksAreNotPenalised() {
        assertFalse("link" in engine.checkMessage("Details: https://bisp.gov.pk/").reasons)
    }

    @Test fun maskingHidesSecrets() {
        val out = Masking.mask("Code 482913, CNIC 35202-1234567-1, acct 01234567890123, from 8171")
        assertFalse(out.contains("482913"))
        assertFalse(out.contains("35202"))
        assertFalse(out.contains("01234567890123"))
        assertTrue(out.contains("8171"))
    }
}
