package friends.com

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDeveloperModeEnabled" -> {
                    result.success(isDeveloperModeEnabled())
                }

                "openDeveloperSettings" -> {
                    result.success(openDeveloperSettings())
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun isDeveloperModeEnabled(): Boolean {
        return try {
            Settings.Global.getInt(
                contentResolver,
                Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
                0,
            ) != 0
        } catch (_: Exception) {
            false
        }
    }

    private fun openDeveloperSettings(): Boolean {
        return try {
            startActivity(Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS))
            true
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_SETTINGS))
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    companion object {
        private const val CHANNEL = "friends.com/device_security"
    }
}
