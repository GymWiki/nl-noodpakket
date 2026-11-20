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
        // Welke hardware heeft dit toestel? De app staat in Google Play ook voor toestellen zonder camera of wifi (die features zijn
        // niet verplicht); Dart vraagt hier of ze er zijn, zodat het scannen en delen rustig melden dat het niet kan.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nl.mijnnoodpakket/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasSystemFeature" -> {
                        val name = call.arguments as? String
                        result.success(name != null && packageManager.hasSystemFeature(name))
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
