package com.fedha.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    
    private var smsAndNotificationHandler: SmsAndNotificationHandler? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        try {
            // Initialize SMS and notification handler
            smsAndNotificationHandler = SmsAndNotificationHandler(this, flutterEngine)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to initialize SmsAndNotificationHandler", e)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        try {
            // Handle notification taps
            handleNotificationIntent(intent)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error handling notification intent", e)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        try {
            handleNotificationIntent(intent)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error handling new intent", e)
        }
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
        try {
            smsAndNotificationHandler?.cleanup()
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error during cleanup", e)
        }
    }
}
