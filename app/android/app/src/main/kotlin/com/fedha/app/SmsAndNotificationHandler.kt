package com.fedha.app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsMessage
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SmsAndNotificationHandler(private val context: Context, private val flutterEngine: FlutterEngine) : MethodCallHandler {
    
    companion object {
        private const val SMS_CHANNEL = "fedha_sms_listener"
        private const val SMS_EVENT_CHANNEL = "fedha_sms_events"
        private const val NOTIFICATION_CHANNEL = "fedha_notifications"
        private const val DEFAULT_NOTIFICATION_CHANNEL_ID = "fedha_transactions"
    }

    private var smsEventSink: EventChannel.EventSink? = null
    private var smsReceiver: BroadcastReceiver? = null
    private var isListening = false

    init {
        try {
            setupChannels()
        } catch (e: Exception) {
            android.util.Log.e("SmsAndNotificationHandler", "Failed to setup channels", e)
        }
    }

    private fun setupChannels() {
        try {
            // Setup method channels
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler(this)
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler(this)
            
            // Setup event channel for SMS
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_EVENT_CHANNEL)
                .setStreamHandler(object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        smsEventSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        smsEventSink = null
                    }
                })
        } catch (e: Exception) {
            android.util.Log.e("SmsAndNotificationHandler", "Error setting up channels", e)
            throw e
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                // SMS Methods
                "startSmsListener" -> startSmsListener(result)
                "stopSmsListener" -> stopSmsListener(result)
                "getRecentSms" -> getRecentSms(call, result)
                
                // Notification Methods
                "initializeNotifications" -> initializeNotifications(call, result)
                "showNotification" -> showNotification(call, result)
                "cancelNotification" -> cancelNotification(call, result)
                "cancelAllNotifications" -> cancelAllNotifications(result)
                "areNotificationsEnabled" -> areNotificationsEnabled(result)
                "openNotificationSettings" -> openNotificationSettings(result)
                "scheduleNotification" -> scheduleNotification(call, result)
                "getPendingNotifications" -> getPendingNotifications(result)
                
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            android.util.Log.e("SmsAndNotificationHandler", "Error in onMethodCall: ${call.method}", e)
            result.error("METHOD_CALL_ERROR", "Failed to execute ${call.method}: ${e.message}", null)
        }
    }

    // ===========================================
    // SMS LISTENER METHODS
    // ===========================================

    private fun startSmsListener(result: Result) {
        if (!hasRequiredPermissions()) {
            result.error("PERMISSION_DENIED", "SMS permissions not granted", null)
            return
        }

        if (isListening) {
            result.success(true)
            return
        }

        try {
            smsReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
                        processSmsIntent(intent)
                    }
                }
            }

            val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
            filter.priority = 1000 // High priority to receive SMS quickly
            context.registerReceiver(smsReceiver, filter)
            
            isListening = true
            result.success(true)
        } catch (e: Exception) {
            result.error("SMS_LISTENER_ERROR", "Failed to start SMS listener: ${e.message}", null)
        }
    }

    private fun stopSmsListener(result: Result) {
        try {
            smsReceiver?.let {
                context.unregisterReceiver(it)
                smsReceiver = null
            }
            isListening = false
            result.success(true)
        } catch (e: Exception) {
            result.error("SMS_LISTENER_ERROR", "Failed to stop SMS listener: ${e.message}", null)
        }
    }

    private fun processSmsIntent(intent: Intent) {
        try {
            val bundle = intent.extras ?: return
            val pdus = bundle.get("pdus") as Array<*>? ?: return
            val format = bundle.getString("format")

            for (pdu in pdus) {
                val smsMessage = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    SmsMessage.createFromPdu(pdu as ByteArray, format)
                } else {
                    @Suppress("DEPRECATION")
                    SmsMessage.createFromPdu(pdu as ByteArray)
                }

                val sender = smsMessage.displayOriginatingAddress
                val message = smsMessage.messageBody
                val timestamp = smsMessage.timestampMillis

                // Send to Flutter via event channel
                val smsData = mapOf(
                    "sender" to sender,
                    "message" to message,
                    "timestamp" to timestamp
                )

                smsEventSink?.success(smsData)
            }
        } catch (e: Exception) {
            // Log error but don't crash
            android.util.Log.e("SmsHandler", "Error processing SMS: ${e.message}")
        }
    }

    private fun getRecentSms(call: MethodCall, result: Result) {
        if (!hasRequiredPermissions()) {
            result.error("PERMISSION_DENIED", "SMS permissions not granted", null)
            return
        }

        try {
            val limit = call.argument<Int>("limit") ?: 50
            val smsList = mutableListOf<Map<String, Any>>()

            val cursor: Cursor? = context.contentResolver.query(
                Uri.parse("content://sms/inbox"),
                arrayOf("_id", "address", "body", "date"),
                null,
                null,
                "date DESC LIMIT $limit"
            )

            cursor?.use {
                val addressIndex = it.getColumnIndex("address")
                val bodyIndex = it.getColumnIndex("body")
                val dateIndex = it.getColumnIndex("date")

                while (it.moveToNext()) {
                    val sms = mapOf(
                        "sender" to it.getString(addressIndex),
                        "message" to it.getString(bodyIndex),
                        "timestamp" to it.getLong(dateIndex)
                    )
                    smsList.add(sms)
                }
            }

            result.success(smsList)
        } catch (e: Exception) {
            result.error("SMS_READ_ERROR", "Failed to read SMS: ${e.message}", null)
        }
    }

    // ===========================================
    // NOTIFICATION METHODS
    // ===========================================

    private fun initializeNotifications(call: MethodCall, result: Result) {
        try {
            val channelId = call.argument<String>("channelId") ?: DEFAULT_NOTIFICATION_CHANNEL_ID
            val channelName = call.argument<String>("channelName") ?: "Fedha Notifications"
            val channelDescription = call.argument<String>("channelDescription") ?: "Notifications from Fedha app"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val importance = NotificationManager.IMPORTANCE_DEFAULT
                val channel = NotificationChannel(channelId, channelName, importance).apply {
                    description = channelDescription
                }

                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
            }

            result.success(true)
        } catch (e: Exception) {
            result.error("NOTIFICATION_INIT_ERROR", "Failed to initialize notifications: ${e.message}", null)
        }
    }

    private fun showNotification(call: MethodCall, result: Result) {
        try {
            val id = call.argument<Int>("id") ?: return
            val title = call.argument<String>("title") ?: return
            val body = call.argument<String>("body") ?: return
            val payload = call.argument<String>("payload") ?: ""
            val channelId = call.argument<String>("channelId") ?: DEFAULT_NOTIFICATION_CHANNEL_ID

            // Create intent for when notification is tapped
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                putExtra("notification_payload", payload)
            }

            val pendingIntent = PendingIntent.getActivity(
                context, 
                id, 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notification = NotificationCompat.Builder(context, channelId)
                .setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(android.R.drawable.ic_dialog_info) // Use system icon to avoid resource issues
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .build()

            if (ActivityCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
                NotificationManagerCompat.from(context).notify(id, notification)
                result.success(true)
            } else {
                result.error("PERMISSION_DENIED", "Notification permission not granted", null)
            }
        } catch (e: Exception) {
            result.error("NOTIFICATION_ERROR", "Failed to show notification: ${e.message}", null)
        }
    }

    private fun cancelNotification(call: MethodCall, result: Result) {
        try {
            val id = call.argument<Int>("id") ?: return
            NotificationManagerCompat.from(context).cancel(id)
            result.success(true)
        } catch (e: Exception) {
            result.error("NOTIFICATION_ERROR", "Failed to cancel notification: ${e.message}", null)
        }
    }

    private fun cancelAllNotifications(result: Result) {
        try {
            NotificationManagerCompat.from(context).cancelAll()
            result.success(true)
        } catch (e: Exception) {
            result.error("NOTIFICATION_ERROR", "Failed to cancel all notifications: ${e.message}", null)
        }
    }

    private fun areNotificationsEnabled(result: Result) {
        val enabled = NotificationManagerCompat.from(context).areNotificationsEnabled()
        result.success(enabled)
    }

    private fun openNotificationSettings(result: Result) {
        try {
            val intent = Intent().apply {
                when {
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.O -> {
                        action = android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS
                        putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, context.packageName)
                    }
                    else -> {
                        action = android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                        data = Uri.parse("package:${context.packageName}")
                    }
                }
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("SETTINGS_ERROR", "Failed to open notification settings: ${e.message}", null)
        }
    }

    private fun scheduleNotification(call: MethodCall, result: Result) {
        // For simplicity, we'll just show the notification immediately
        // In a full implementation, you'd use AlarmManager or WorkManager
        showNotification(call, result)
    }

    private fun getPendingNotifications(result: Result) {
        // This would require storing scheduled notifications in a database
        // For now, return empty list
        result.success(emptyList<Map<String, Any>>())
    }

    // ===========================================
    // HELPER METHODS
    // ===========================================

    private fun hasRequiredPermissions(): Boolean {
        val hasSms = ActivityCompat.checkSelfPermission(context, Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED &&
                   ActivityCompat.checkSelfPermission(context, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
        
        val hasNotification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }

        return hasSms && hasNotification
    }

    fun cleanup() {
        try {
            stopSmsListener(object : Result {
                override fun success(result: Any?) {}
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
                override fun notImplemented() {}
            })
            smsEventSink = null
        } catch (e: Exception) {
            android.util.Log.e("SmsAndNotificationHandler", "Error during cleanup", e)
        }
    }
}
