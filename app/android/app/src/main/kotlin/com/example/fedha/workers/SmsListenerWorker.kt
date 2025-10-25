package com.example.fedha.workers

import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.Telephony
import androidx.work.Worker
import androidx.work.WorkerParameters

class SmsListenerWorker(private val appContext: Context, workerParams: WorkerParameters)
    : Worker(appContext, workerParams) {

    override fun doWork(): Result {
        try {
            // Get the profile ID from parameters
            val profileId = inputData.getString("profileId")
            
            // Get the SMS messages
            val cursor = getSmsInbox()
            cursor?.use { c ->
                if (c.moveToFirst()) {
                    do {
                        // Extract SMS data
                        val address = c.getString(c.getColumnIndexOrThrow(Telephony.Sms.Inbox.ADDRESS))
                        val body = c.getString(c.getColumnIndexOrThrow(Telephony.Sms.Inbox.BODY))
                        val date = c.getLong(c.getColumnIndexOrThrow(Telephony.Sms.Inbox.DATE))

                        // Process SMS and send back to Flutter
                        processSms(address, body, date, profileId)
                    } while (c.moveToNext())
                }
            }
            return Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            return Result.failure()
        }
    }

    private fun getSmsInbox(): Cursor? {
        val uri = Uri.parse("content://sms/inbox")
        val projection = arrayOf(
            Telephony.Sms.Inbox.ADDRESS,
            Telephony.Sms.Inbox.BODY,
            Telephony.Sms.Inbox.DATE
        )
        return appContext.contentResolver.query(
            uri,
            projection,
            null,
            null,
            Telephony.Sms.Inbox.DEFAULT_SORT_ORDER
        )
    }

    private fun processSms(address: String, body: String, date: Long, profileId: String?) {
        // TODO: Send SMS data back to Flutter
        // You'll need to implement a method to communicate with Flutter
        // This could be through a shared preferences, local database, or method channel
    }
}