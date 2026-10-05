package com.fscarel.presssure

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "presssure/reminders")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setTargets" -> {
                        val targets = call.arguments<List<Number>>().orEmpty()
                        ReminderHops.setTargets(this, targets.map { it.toLong() })
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
