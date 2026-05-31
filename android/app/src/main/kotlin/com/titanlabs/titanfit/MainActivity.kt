package com.titanlabs.titanfit

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "titanfit/link")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialUri" -> {
                        val uri = intent?.data?.toString()
                        result.success(uri)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
