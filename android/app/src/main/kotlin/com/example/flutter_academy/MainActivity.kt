package com.example.flutter_academy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "vn.flutteracademy/metamask",
        ).setMethodCallHandler { call, result ->
            if (call.method != "open") {
                result.notImplemented()
            } else {
                val intent = packageManager.getLaunchIntentForPackage("io.metamask")
                if (intent == null) {
                    result.success(false)
                } else {
                    startActivity(intent)
                    result.success(true)
                }
            }
        }
    }
}
