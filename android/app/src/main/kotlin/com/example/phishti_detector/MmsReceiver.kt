package com.example.phishti_detector

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.telephony.SmsMessage
import io.flutter.plugin.common.EventChannel

class MmsReceiver : BroadcastReceiver() {
    companion object {
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.WAP_PUSH_DELIVER_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            
            for (message in messages) {
                val mmsData = hashMapOf<String, Any>(
                    "id" to System.currentTimeMillis().toString(),
                    "sender" to (message.originatingAddress ?: ""),
                    "body" to (message.messageBody ?: ""),
                    "timestamp" to message.timestampMillis,
                    "messageType" to "MMS",
                    "threadId" to "",
                    "isRead" to false,
                    "isPhishing" to false,
                    "phishingScore" to 0.0,
                    "reason" to ""
                )
                
                eventSink?.success(mmsData)
            }
        }
    }
}
