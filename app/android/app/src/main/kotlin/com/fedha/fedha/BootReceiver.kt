package com.fedha.fedha

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            intent.action == Intent.ACTION_PACKAGE_REPLACED) {
            
            // Mark that the device has booted and SMS monitoring should start
            val prefs = context.getSharedPreferences("fedha_sms", Context.MODE_PRIVATE)
            val editor = prefs.edit()
            editor.putBoolean("boot_completed", true)
            editor.putLong("boot_time", System.currentTimeMillis())
            editor.apply()
            
            // Could also start a foreground service here if needed
        }
    }
}
