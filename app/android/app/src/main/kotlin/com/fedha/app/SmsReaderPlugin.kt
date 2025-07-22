package com.fedha.app;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Looper;
import android.telephony.SmsMessage;
import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.EventChannel;

import java.util.HashMap;
import java.util.Map;

public class SmsReaderPlugin implements FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private MethodChannel methodChannel;
    private EventChannel eventChannel;
    private EventChannel.EventSink eventSink;
    private Context context;
    private BroadcastReceiver smsReceiver;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        
        methodChannel = new MethodChannel(binding.getBinaryMessenger(), "sms_listener");
        methodChannel.setMethodCallHandler(this);
        
        eventChannel = new EventChannel(binding.getBinaryMessenger(), "sms_listener_events");
        eventChannel.setStreamHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "initialize":
                result.success(true);
                break;
            case "startListening":
                registerSmsReceiver();
                result.success(true);
                break;
            case "stopListening":
                unregisterSmsReceiver();
                result.success(true);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void registerSmsReceiver() {
        // Register a broadcast receiver for incoming SMS
        if (smsReceiver == null && context != null) {
            smsReceiver = new BroadcastReceiver() {
                @Override
                public void onReceive(Context context, Intent intent) {
                    if (intent.getAction() != null && intent.getAction().equals("android.provider.Telephony.SMS_RECEIVED")) {
                        Object[] pdus = (Object[]) intent.getExtras().get("pdus");
                        if (pdus != null) {
                            for (Object pdu : pdus) {
                                SmsMessage smsMessage = SmsMessage.createFromPdu((byte[]) pdu);
                                String sender = smsMessage.getDisplayOriginatingAddress();
                                String body = smsMessage.getMessageBody();
                                long timestamp = System.currentTimeMillis();
                                
                                // Send to Flutter
                                Map<String, Object> messageMap = new HashMap<>();
                                messageMap.put("sender", sender);
                                messageMap.put("body", body);
                                messageMap.put("timestamp", timestamp);
                                messageMap.put("address", sender);
                                
                                Handler handler = new Handler(Looper.getMainLooper());
                                handler.post(() -> {
                                    if (eventSink != null) {
                                        eventSink.success(messageMap);
                                    }
                                    methodChannel.invokeMethod("onSmsReceived", messageMap);
                                });
                            }
                        }
                    }
                }
            };
            
            IntentFilter filter = new IntentFilter("android.provider.Telephony.SMS_RECEIVED");
            filter.setPriority(IntentFilter.SYSTEM_HIGH_PRIORITY);
            context.registerReceiver(smsReceiver, filter);
        }
    }

    private void unregisterSmsReceiver() {
        if (smsReceiver != null && context != null) {
            context.unregisterReceiver(smsReceiver);
            smsReceiver = null;
        }
    }
    
    // EventChannel implementation
    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        eventSink = null;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        unregisterSmsReceiver();
        methodChannel.setMethodCallHandler(null);
        eventChannel.setStreamHandler(null);
        methodChannel = null;
        eventChannel = null;
        context = null;
    }
}
