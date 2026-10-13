package pk.khabardar.app.alerts

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import pk.khabardar.app.R
import pk.khabardar.app.data.ShieldStore
import pk.khabardar.app.detection.PhoneNormalizer

/**
 * Warnings drawn over other apps ("Display over other apps" permission):
 * a banner over the incoming-call screen, and a blocking sheet over a
 * banking or wallet app while a flagged caller may be on the line.
 *
 * The overlay never reads or captures what the other app shows.
 */
object OverlayController {
    private const val SCAM = 0xFFC2410C.toInt()
    private const val SCAM_DARK = 0xFFA3360A.toInt()
    private const val INK = 0xFF10201A.toInt()
    private const val INK2 = 0xFF3A4B44.toInt()
    private const val LINE = 0xFFD5DED9.toInt()
    private const val SCAM_TINT = 0xFFFFF4EC.toInt()
    private const val SCAM_INK = 0xFF7C2D12.toInt()

    private val main = Handler(Looper.getMainLooper())
    private var callBanner: View? = null
    private var bankSheet: View? = null

    fun canDraw(context: Context) = Settings.canDrawOverlays(context)

    // ---- Incoming call banner -------------------------------------------

    fun showCallBanner(context: Context, number: String, category: String?, reports: Int) = main.post {
        val ctx = context.applicationContext
        if (!canDraw(ctx)) return@post
        hideCallBanner(ctx)
        val urdu = ShieldStore.get(ctx).urdu
        val card = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(ctx, 18), dp(ctx, 16), dp(ctx, 18), dp(ctx, 14))
            background = rounded(SCAM, dp(ctx, 22).toFloat())
            elevation = dp(ctx, 8).toFloat()
        }
        val header = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        header.addView(logo(ctx, 40))
        header.addView(
            LinearLayout(ctx).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dp(ctx, 12), 0, 0, 0)
                layoutParams = LinearLayout.LayoutParams(0, -2, 1f)
                addView(text(ctx, "KHABARDAR", 11f, Color.WHITE, bold = true))
                addView(text(ctx, NativeStrings.t("callWarnTitle", urdu), 20f, Color.WHITE, bold = true, urdu = urdu))
            },
        )
        card.addView(header)
        val detail = NativeStrings.t(
            "callText", urdu, PhoneNormalizer.format(number), NativeStrings.category(category, urdu),
        )
        card.addView(text(ctx, detail, 14f, Color.WHITE, urdu = urdu).apply { setPadding(0, dp(ctx, 10), 0, 0) })
        card.addView(
            text(ctx, NativeStrings.t("urduWarning", true), 15f, Color.WHITE, urdu = true).apply {
                background = rounded(SCAM_DARK, dp(ctx, 12).toFloat())
                setPadding(dp(ctx, 12), dp(ctx, 4), dp(ctx, 12), dp(ctx, 4))
                layoutParams = LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(ctx, 10) }
                gravity = Gravity.END
            },
        )
        card.addView(
            Button(ctx).apply {
                text = NativeStrings.t("dismiss", urdu)
                setTextColor(Color.WHITE)
                isAllCaps = false
                background = null
                setOnClickListener { hideCallBanner(ctx) }
            },
        )
        val wrapper = LinearLayout(ctx).apply {
            setPadding(dp(ctx, 12), dp(ctx, 36), dp(ctx, 12), 0)
            addView(card, LinearLayout.LayoutParams(-1, -2))
        }
        val params = baseParams(modal = false).apply {
            width = WindowManager.LayoutParams.MATCH_PARENT
            height = WindowManager.LayoutParams.WRAP_CONTENT
            gravity = Gravity.TOP
        }
        runCatching { wm(ctx).addView(wrapper, params) }.onSuccess {
            callBanner = wrapper
            main.postDelayed({ hideCallBanner(ctx) }, 25_000)
        }
    }

    fun hideCallBanner(context: Context) {
        callBanner?.let { v -> runCatching { wm(context.applicationContext).removeView(v) } }
        callBanner = null
    }

    // ---- Banking sheet --------------------------------------------------

    fun showBankingAlert(context: Context, number: String) = main.post {
        val ctx = context.applicationContext
        if (!canDraw(ctx) || bankSheet != null) return@post
        val urdu = ShieldStore.get(ctx).urdu

        val root = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.BOTTOM
            setBackgroundColor(0xB810201A.toInt())
            isClickable = true // swallow taps meant for the wallet app behind
        }
        if (number.isNotEmpty()) {
            root.addView(
                text(ctx, "● " + PhoneNormalizer.format(number), 13f, Color.WHITE, bold = true).apply {
                    background = rounded(INK, dp(ctx, 999).toFloat())
                    setPadding(dp(ctx, 16), dp(ctx, 10), dp(ctx, 16), dp(ctx, 10))
                    layoutParams = LinearLayout.LayoutParams(-2, -2).apply {
                        gravity = Gravity.CENTER_HORIZONTAL
                        bottomMargin = dp(ctx, 16)
                    }
                },
            )
        }
        val sheet = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(ctx, 24), dp(ctx, 24), dp(ctx, 24), dp(ctx, 32))
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                val r = dp(ctx, 28).toFloat()
                cornerRadii = floatArrayOf(r, r, r, r, 0f, 0f, 0f, 0f)
            }
        }
        val header = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        header.addView(
            LinearLayout(ctx).apply {
                gravity = Gravity.CENTER
                background = rounded(SCAM, dp(ctx, 16).toFloat())
                addView(logo(ctx, 36))
                layoutParams = LinearLayout.LayoutParams(dp(ctx, 56), dp(ctx, 56))
            },
        )
        header.addView(
            text(ctx, NativeStrings.t("bankTitle", urdu), 20f, INK, bold = true, urdu = urdu).apply {
                setPadding(dp(ctx, 14), 0, 0, 0)
                layoutParams = LinearLayout.LayoutParams(0, -2, 1f)
            },
        )
        sheet.addView(header)
        sheet.addView(
            text(ctx, NativeStrings.t("bankText", urdu), 15f, INK2, urdu = urdu).apply {
                setPadding(0, dp(ctx, 14), 0, dp(ctx, 12))
            },
        )
        sheet.addView(
            text(ctx, NativeStrings.t("urduWarning", true), 15f, SCAM_INK, urdu = true).apply {
                background = rounded(SCAM_TINT, dp(ctx, 14).toFloat())
                setPadding(dp(ctx, 14), dp(ctx, 4), dp(ctx, 14), dp(ctx, 4))
                gravity = Gravity.END
            },
        )
        val close = button(ctx, NativeStrings.t("bankClose", urdu), SCAM, Color.WHITE) {
            hideBankingAlert(ctx)
            ctx.startActivity(
                Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
        val helpline = button(ctx, NativeStrings.t("bankHelpline", urdu), Color.WHITE, INK, border = LINE) {
            hideBankingAlert(ctx)
            ctx.startActivity(Intent(Intent.ACTION_DIAL).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
        val proceed = button(ctx, NativeStrings.t("bankContinue", urdu, 5), Color.TRANSPARENT, 0xFF4A5C55.toInt()) {
            hideBankingAlert(ctx)
        }.apply { isEnabled = false }
        sheet.addView(close, buttonParams(ctx, 16))
        sheet.addView(helpline, buttonParams(ctx, 10))
        sheet.addView(proceed, buttonParams(ctx, 6))
        root.addView(sheet, LinearLayout.LayoutParams(-1, -2))

        // A short forced pause breaks the scammer's rhythm.
        for (s in 4 downTo 1) {
            main.postDelayed({ proceed.text = NativeStrings.t("bankContinue", urdu, s) }, (5 - s) * 1000L)
        }
        main.postDelayed({
            proceed.isEnabled = true
            proceed.text = NativeStrings.t("bankContinueNow", urdu)
        }, 5000)

        val params = baseParams(modal = true).apply {
            width = WindowManager.LayoutParams.MATCH_PARENT
            height = WindowManager.LayoutParams.MATCH_PARENT
        }
        runCatching { wm(ctx).addView(root, params) }.onSuccess { bankSheet = root }
    }

    fun hideBankingAlert(context: Context) {
        bankSheet?.let { v -> runCatching { wm(context.applicationContext).removeView(v) } }
        bankSheet = null
    }

    // ---- Helpers --------------------------------------------------------

    private fun wm(ctx: Context) = ctx.getSystemService(WindowManager::class.java)

    private fun baseParams(modal: Boolean) = WindowManager.LayoutParams(
        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            (if (modal) 0 else WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL),
        PixelFormat.TRANSLUCENT,
    )

    private fun dp(ctx: Context, v: Int) =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), ctx.resources.displayMetrics).toInt()

    private fun rounded(color: Int, radius: Float, border: Int? = null) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = radius
        if (border != null) setStroke(2, border)
    }

    private val fonts = mutableMapOf<String, Typeface?>()

    /** Uses the fonts bundled with the Flutter app, falling back to system. */
    private fun font(ctx: Context, file: String): Typeface? = fonts.getOrPut(file) {
        runCatching { Typeface.createFromAsset(ctx.assets, "flutter_assets/assets/fonts/$file") }.getOrNull()
    }

    private fun text(
        ctx: Context,
        value: String,
        sp: Float,
        color: Int,
        bold: Boolean = false,
        urdu: Boolean = false,
    ) = TextView(ctx).apply {
        text = value
        setTextColor(color)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, sp)
        typeface = if (urdu) {
            font(ctx, if (bold) "NotoNastaliqUrdu-Bold.ttf" else "NotoNastaliqUrdu-Regular.ttf")
        } else {
            font(ctx, if (bold) "Manrope-ExtraBold.ttf" else "Manrope-Medium.ttf")
        } ?: if (bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        if (urdu) {
            textDirection = View.TEXT_DIRECTION_RTL
            setLineSpacing(0f, 1.25f)
        }
    }

    private fun logo(ctx: Context, sizeDp: Int) = ImageView(ctx).apply {
        setImageResource(R.drawable.ic_khabardar_on_color)
        layoutParams = LinearLayout.LayoutParams(dp(ctx, sizeDp), dp(ctx, sizeDp))
        contentDescription = "Khabardar"
    }

    private fun button(
        ctx: Context,
        label: String,
        bg: Int,
        fg: Int,
        border: Int? = null,
        onClick: () -> Unit,
    ) = Button(ctx).apply {
        text = label
        isAllCaps = false
        setTextColor(fg)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
        typeface = font(ctx, "Manrope-ExtraBold.ttf") ?: Typeface.DEFAULT_BOLD
        background = rounded(bg, dp(ctx, 16).toFloat(), border)
        minHeight = dp(ctx, 52)
        stateListAnimator = null
        setOnClickListener { onClick() }
    }

    private fun buttonParams(ctx: Context, top: Int) =
        LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(ctx, top) }
}
