package com.fedha.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import android.telephony.SmsMessage
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.EventChannel.EventSink
import java.util.HashMap

class SmsReaderPlugin: FlutterPlugin, MethodCallHandler, StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventSink? = null
    private lateinit var context: Context
    private var smsReceiver: BroadcastReceiver? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        
        methodChannel = MethodChannel(binding.binaryMessenger, "sms_listener")
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(binding.binaryMessenger, "sms_listener_events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> {
                result.success(true)
            }
            "startListening" -> {
                registerSmsReceiver()
                result.success(true)
            }
            "stopListening" -> {
                unregisterSmsReceiver()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun registerSmsReceiver() {
        // Register a broadcast receiver for incoming SMS
        if (smsReceiver == null && ::context.isInitialized) {
            smsReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    if (intent.action != null && intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
                        val bundle = intent.extras
                        if (bundle != null) {
                            val pdus = bundle["pdus"] as Array<*>?
                            if (pdus != null) {
                                for (pdu in pdus) {
                                    val smsMessage = SmsMessage.createFromPdu(pdu as ByteArray)
                                    val sender = smsMessage.displayOriginatingAddress
                                    val body = smsMessage.messageBody
                                    val timestamp = System.currentTimeMillis()
                                    
                                    // Send to Flutter
                                    val messageMap = HashMap<String, Any>()
                                    messageMap["sender"] = sender
                                    messageMap["body"] = body
                                    messageMap["timestamp"] = timestamp
                                    messageMap["address"] = sender
                                    
                                    val handler = Handler(Looper.getMainLooper())
                                    handler.post {
                                        eventSink?.success(messageMap)
                                        methodChannel.invokeMethod("onSmsReceived", messageMap)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
            filter.priority = 999
            context.registerReceiver(smsReceiver, filter)
        }
    }

    private fun unregisterSmsReceiver() {
        if (smsReceiver != null && ::context.isInitialized) {
            context.unregisterReceiver(smsReceiver)
            smsReceiver = null
        }
    }
    
    // EventChannel implementation
    override fun onListen(arguments: Any?, events: EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        unregisterSmsReceiver()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}
