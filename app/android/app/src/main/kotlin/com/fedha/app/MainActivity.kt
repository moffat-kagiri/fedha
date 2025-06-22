package com.fedha.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    
    private var smsAndNotificationHandler: SmsAndNotificationHandler? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize SMS and notification handler
        smsAndNotificationHandler = SmsAndNotificationHandler(this, flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle notification taps
        handleNotificationIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationIntent(intent)
    }

    private fun handleNotificationIntent(intent: Intent?) {
        intent?.getStringExtra("notification_payload")?.let { payload ->
            // Send notification tap event to Flutter
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, "fedha_notifications")
                    .invokeMethod("onNotificationTapped", payload)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        smsAndNotificationHandler?.cleanup()
    }
}
