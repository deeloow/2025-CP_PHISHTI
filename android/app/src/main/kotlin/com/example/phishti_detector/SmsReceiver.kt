package com.example.phishti_detector

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.telephony.SmsMessage
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class SmsReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "SmsReceiver"
        private const val CHANNEL_NAME = "com.example.phishti_detector/sms"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            
            for (message in messages) {
                val sender = message.originatingAddress ?: "Unknown"
                val body = message.messageBody ?: ""
                val timestamp = message.timestampMillis
                
                Log.d(TAG, "Received SMS from $sender: $body")
                
                // Send to Flutter
                sendSmsToFlutter(context, sender, body, timestamp)
            }
        }
    }
    
    private fun sendSmsToFlutter(context: Context, sender: String, body: String, timestamp: Long) {
        try {
            val methodChannel = MethodChannel(
                context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.Activity,
                CHANNEL_NAME
            )
            
            val arguments = mapOf(
                "sender" to sender,
                "body" to body,
                "timestamp" to timestamp
            )
            
            methodChannel.invokeMethod("onSmsReceived", arguments)
        } catch (e: Exception) {
            Log.e(TAG, "Error sending SMS to Flutter: ${e.message}")
        }
    }
}
