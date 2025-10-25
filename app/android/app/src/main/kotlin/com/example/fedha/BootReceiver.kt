package com.example.fedha

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.WorkManager
import androidx.work.OneTimeWorkRequestBuilder
import com.example.fedha.workers.SmsListenerWorker

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Check if user is logged in
            val prefs = context.getSharedPreferences("fedha_prefs", Context.MODE_PRIVATE)
            val isLoggedIn = prefs.getBoolean("is_logged_in", false)
            val profileId = prefs.getString("profile_id", null)
            
            if (isLoggedIn && profileId != null) {
                // Start the SMS listener service
                val workRequest = OneTimeWorkRequestBuilder<SmsListenerWorker>()
                    .build()
                WorkManager.getInstance(context).enqueue(workRequest)
            }
        }
    }
}