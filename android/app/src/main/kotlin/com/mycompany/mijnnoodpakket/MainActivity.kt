package com.mycompany.mijnnoodpakket

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity is nodig voor BiometricPrompt (flutter_secure_storage / local_auth).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Documentenkluis: FLAG_SECURE blokkeert screenshots, schermopnames en de
        // preview in het recente-appsscherm zolang een kluisscherm open staat.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nl.mijnnoodpakket/secure")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val on = call.arguments as? Boolean ?: false
                        runOnUiThread {
                            if (on) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
