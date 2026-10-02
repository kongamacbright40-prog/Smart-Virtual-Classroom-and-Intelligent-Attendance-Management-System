package com.example.scra

import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smart_class/screen_capture")
            .setMethodCallHandler { call, result ->
                val intent = Intent(this, ScreenCaptureService::class.java)
                when (call.method) {
                    "start" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        // Reply once the service is in the foreground (max ~2 s),
                        // so screen capture is only requested after that.
                        val handler = Handler(Looper.getMainLooper())
                        var waited = 0
                        handler.post(object : Runnable {
                            override fun run() {
                                if (ScreenCaptureService.isRunning || waited >= 2000) {
                                    result.success(ScreenCaptureService.isRunning)
                                } else {
                                    waited += 50
                                    handler.postDelayed(this, 50)
                                }
                            }
                        })
                    }
                    "stop" -> {
                        stopService(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}