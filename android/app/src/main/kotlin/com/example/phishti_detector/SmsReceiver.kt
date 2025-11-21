package com.example.phishti_detector

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.telephony.SmsMessage
import io.flutter.plugin.common.EventChannel

class SmsReceiver : BroadcastReceiver() {
    companion object {
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            
            for (message in messages) {
                val smsData = hashMapOf<String, Any>(
                    "id" to System.currentTimeMillis().toString(),
                    "sender" to (message.originatingAddress ?: ""),
                    "body" to (message.messageBody ?: ""),
                    "timestamp" to message.timestampMillis,
                    "messageType" to "SMS",
                    "threadId" to "",
                    "isRead" to false,
                    "isPhishing" to false,
                    "phishingScore" to 0.0,
                    "reason" to ""
                )
                
                eventSink?.success(smsData)
            }
        }
    }
}
