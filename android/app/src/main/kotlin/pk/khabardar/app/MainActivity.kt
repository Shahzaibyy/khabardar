package pk.khabardar.app

import android.Manifest
import android.app.role.RoleManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import pk.khabardar.app.alerts.Notifier
import pk.khabardar.app.alerts.OverlayController
import pk.khabardar.app.data.ShieldStore
import pk.khabardar.app.guard.BankingGuardService

/**
 * Hosts the Flutter UI and answers its calls on `pk.khabardar/native`
 * (see `lib/native/bridge.dart`).
 */
class MainActivity : FlutterActivity() {

    private val store by lazy { ShieldStore.get(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Notifier.ensureChannels(this)
        rememberLaunchEvent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        rememberLaunchEvent(intent)
    }

    private fun rememberLaunchEvent(intent: Intent?) {
        intent?.getStringExtra(Notifier.EXTRA_EVENT_ID)?.let {
            store.setLaunchEvent(it)
            intent.removeExtra(Notifier.EXTRA_EVENT_ID)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "pk.khabardar/native").setMethodCallHandler(::onCall)
        EventChannel(messenger, "pk.khabardar/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    ShieldStore.listener = { events.success(it) }
                }

                override fun onCancel(arguments: Any?) {
                    ShieldStore.listener = null
                }
            },
        )
    }

    private fun onCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPermissionStatus" -> result.success(permissionStatus())
            "requestCallScreeningRole" -> { requestCallScreeningRole(); result.success(null) }
            "requestSmsPermission" -> {
                requestRuntime(Manifest.permission.RECEIVE_SMS)
                result.success(null)
            }
            "requestNotificationPermission" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    requestRuntime(Manifest.permission.POST_NOTIFICATIONS)
                }
                result.success(null)
            }
            "openOverlaySettings" -> {
                open(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
                result.success(null)
            }
            "openUsageAccessSettings" -> {
                open(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                result.success(null)
            }
            "getSettings" -> result.success(store.settings())
            "saveSettings" -> {
                (call.arguments as? Map<*, *>)?.let(store::saveSettings)
                result.success(null)
            }
            "getEvents" -> result.success(store.events())
            "deleteEvent" -> { store.deleteEvent(call.argument<String>("id") ?: ""); result.success(null) }
            "getBlockedHashes" -> result.success(store.blockedHashes().toList())
            "blockHash" -> { call.argument<String>("hash")?.let(store::block); result.success(null) }
            "unblockHash" -> { call.argument<String>("hash")?.let(store::unblock); result.success(null) }
            "queueReport" -> {
                (call.arguments as? Map<*, *>)?.let(store::queueReport)
                result.success(null)
            }
            "pendingReportCount" -> result.success(store.pendingReports())
            "deleteAllData" -> { store.deleteAll(); result.success(null) }
            "consumeLaunchEvent" -> result.success(store.consumeLaunchEvent())
            "showTestCallAlert" -> {
                OverlayController.showCallBanner(this, "+923000000111", "bisp", 214)
                result.success(null)
            }
            "showTestBankingAlert" -> {
                OverlayController.showBankingAlert(this, "+923000000111")
                result.success(null)
            }
            "dial" -> {
                val n = call.argument<String>("number").orEmpty()
                open(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$n")))
                result.success(null)
            }
            "shareText" -> {
                val send = Intent(Intent.ACTION_SEND)
                    .setType("text/plain")
                    .putExtra(Intent.EXTRA_TEXT, call.argument<String>("text").orEmpty())
                open(Intent.createChooser(send, null))
                result.success(null)
            }
            "openUrl" -> {
                open(Intent(Intent.ACTION_VIEW, Uri.parse(call.argument<String>("url").orEmpty())))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun permissionStatus(): Map<String, Boolean> {
        val screeningSupported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
        val screening = screeningSupported &&
            getSystemService(RoleManager::class.java).isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
        return mapOf(
            "callScreening" to screening,
            "callScreeningSupported" to screeningSupported,
            "sms" to granted(Manifest.permission.RECEIVE_SMS),
            "notifications" to Notifier.canNotify(this),
            "overlay" to OverlayController.canDraw(this),
            "usageAccess" to BankingGuardService.hasUsageAccess(this),
        )
    }

    private fun requestCallScreeningRole() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        val rm = getSystemService(RoleManager::class.java)
        if (!rm.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING) || rm.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) return
        @Suppress("DEPRECATION")
        startActivityForResult(rm.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING), REQUEST_ROLE)
    }

    private fun granted(permission: String) =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun requestRuntime(permission: String) {
        if (!granted(permission)) requestPermissions(arrayOf(permission), REQUEST_PERMISSION)
    }

    private fun open(intent: Intent) {
        try {
            startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            // Some phones hide these settings screens; fall back to app details.
            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
        }
    }

    companion object {
        private const val REQUEST_ROLE = 41
        private const val REQUEST_PERMISSION = 42
    }
}
