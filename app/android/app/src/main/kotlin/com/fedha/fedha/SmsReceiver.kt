package com.fedha.fedha

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.telephony.SmsMessage
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterMain

class SmsReceiver : BroadcastReceiver() {
    companion object {
        private const val CHANNEL = "fedha_background_sms"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            
            for (smsMessage in messages) {
                val sender = smsMessage.displayOriginatingAddress
                val messageBody = smsMessage.messageBody
                val timestamp = smsMessage.timestampMillis
                
                // Check if this looks like a financial SMS
                if (isFinancialSms(sender, messageBody)) {
                    // Send to Flutter via method channel
                    sendToFlutter(context, sender, messageBody, timestamp)
                }
            }
        }
    }
    
    private fun isFinancialSms(sender: String?, message: String?): Boolean {
        if (sender == null || message == null) return false
        
        val financialKeywords = listOf(
            "MPESA", "M-PESA", "M_PESA", "KCB", "EQUITY", "COOP", "NCBA",
            "STANCHART", "ABSA", "FAMILY", "DTB", "BARCLAYS", "transaction",
            "debit", "credit", "balance", "withdraw", "deposit", "transfer"
        )
        
        val normalizedSender = sender.uppercase().replace(Regex("[^A-Z0-9]"), "")
        val normalizedMessage = message.uppercase()
        
        return financialKeywords.any { keyword ->
            normalizedSender.contains(keyword) || normalizedMessage.contains(keyword)
        }
    }
    
    private fun sendToFlutter(context: Context, sender: String, message: String, timestamp: Long) {
        // Store SMS data in JSON format for the Flutter app to process
        val prefs = context.getSharedPreferences("fedha_sms", Context.MODE_PRIVATE)
        val editor = prefs.edit()
        
        val smsData = mapOf(
            "sender" to sender,
            "message" to message,
            "timestamp" to timestamp
        )
        
        // Get existing pending SMS list
        val pendingSmsJson = prefs.getString("pending_sms", "[]") ?: "[]"
        val pendingSmsList = mutableListOf<Map<String, Any>>()
        
        try {
            // Parse existing SMS list (simplified JSON parsing)
            // In production, use a proper JSON library
            if (pendingSmsJson != "[]") {
                // For now, just add to a simple list
                pendingSmsList.add(smsData)
            } else {
                pendingSmsList.add(smsData)
            }
        } catch (e: Exception) {
            // If parsing fails, start with new list
            pendingSmsList.clear()
            pendingSmsList.add(smsData)
        }
        
        // Keep only last 20 SMS messages
        if (pendingSmsList.size > 20) {
            pendingSmsList.removeAt(0)
        }
        
        // Store as JSON string (simplified)
        val jsonString = "[${pendingSmsList.joinToString(",") { 
            "{\"sender\":\"${it["sender"]}\",\"message\":\"${it["message"]}\",\"timestamp\":${it["timestamp"]}}"
        }}]"
        
        editor.putString("pending_sms", jsonString)
        editor.apply()
    }
}
