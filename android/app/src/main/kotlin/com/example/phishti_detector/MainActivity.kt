package com.example.phishti_detector

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.provider.ContactsContract
import android.provider.Telephony
import android.telephony.SmsManager
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "sms_integration"
    private val SMS_EVENT_CHANNEL = "sms_events"
    private val SMS_PERMISSION_REQUEST = 1001
    private var eventSink: EventChannel.EventSink? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIncomingIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingIntent(intent)
    }

    private fun handleIncomingIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND) {
            when (intent.type) {
                "text/plain", "text/*" -> {
                    val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                    if (!sharedText.isNullOrEmpty()) {
                        // Send shared text to Flutter for analysis
                        methodChannel?.invokeMethod("analyzeSharedText", mapOf(
                            "text" to sharedText,
                            "timestamp" to System.currentTimeMillis()
                        ))
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Setup event channel for SMS events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    SmsReceiver.eventSink = events
                    MmsReceiver.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    SmsReceiver.eventSink = null
                    MmsReceiver.eventSink = null
                }
            }
        )

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getAllSms" -> {
                    if (checkSmsPermissions()) {
                        result.success(getAllSmsMessages())
                    } else {
                        result.error("PERMISSION_DENIED", "SMS permissions not granted", null)
                    }
                }
                "getSmsByThread" -> {
                    val threadId = call.argument<String>("threadId")
                    if (checkSmsPermissions() && threadId != null) {
                        result.success(getSmsByThread(threadId))
                    } else {
                        result.error("PERMISSION_DENIED", "SMS permissions not granted", null)
                    }
                }
                "getSmsThreads" -> {
                    if (checkSmsPermissions()) {
                        result.success(getSmsThreads())
                    } else {
                        result.error("PERMISSION_DENIED", "SMS permissions not granted", null)
                    }
                }
                "getAllSmsThreads" -> {
                    if (checkSmsPermissions()) {
                        result.success(getAllSmsThreads())
                    } else {
                        result.error("PERMISSION_DENIED", "SMS permissions not granted", null)
                    }
                }
                "sendSms" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")
                    if (checkSmsPermissions() && phoneNumber != null && message != null) {
                        val success = sendSms(phoneNumber, message)
                        result.success(success)
                    } else {
                        result.error("PERMISSION_DENIED", "SMS permissions not granted", null)
                    }
                }
                "sendMms" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")
                    val imagePath = call.argument<String>("imagePath")
                    if (checkSmsPermissions() && phoneNumber != null && message != null) {
                        val success = sendMms(phoneNumber, message, imagePath)
                        result.success(success)
                    } else {
                        result.error("PERMISSION_DENIED", "SMS permissions not granted", null)
                    }
                }
                "deleteSms" -> {
                    val messageId = call.argument<String>("messageId")
                    if (checkSmsPermissions() && messageId != null) {
                        val success = deleteSms(messageId)
                        result.success(success)
                    } else {
                        result.error("PERMISSION_DENIED", "SMS permissions not granted", null)
                    }
                }
                "markSmsAsRead" -> {
                    val messageId = call.argument<String>("messageId")
                    if (checkSmsPermissions() && messageId != null) {
                        val success = markSmsAsRead(messageId)
                        result.success(success)
                    } else {
                        result.error("PERMISSION_DENIED", "SMS permissions not granted", null)
                    }
                }
                "isDefaultSmsApp" -> {
                    result.success(isDefaultSmsApp())
                }
                "requestSetAsDefaultSmsApp" -> {
                    requestSetAsDefaultSmsApp()
                    result.success(true)
                }
                "getContacts" -> {
                    if (checkContactsPermissions()) {
                        result.success(getContacts())
                    } else {
                        result.error("PERMISSION_DENIED", "Contacts permissions not granted", null)
                    }
                }
                "getContactByPhone" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    if (checkContactsPermissions() && phoneNumber != null) {
                        result.success(getContactByPhone(phoneNumber))
                    } else {
                        result.error("PERMISSION_DENIED", "Contacts permissions not granted", null)
                    }
                }
                "sendMmsWithImage" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")
                    val imagePath = call.argument<String>("imagePath")
                    if (checkSmsPermissions() && phoneNumber != null && message != null && imagePath != null) {
                        val success = sendMmsWithImage(phoneNumber, message, imagePath)
                        result.success(success)
                    } else {
                        result.error("PERMISSION_DENIED", "SMS permissions not granted", null)
                    }
                }
                "pickImage" -> {
                    result.success("Image picker not implemented in native code")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkSmsPermissions(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED &&
               ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED
    }

    private fun checkContactsPermissions(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED
    }

    private fun getAllSmsMessages(): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        val cursor = contentResolver.query(
            Telephony.Sms.CONTENT_URI,
            arrayOf(
                Telephony.Sms._ID,
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE,
                Telephony.Sms.TYPE,
                Telephony.Sms.THREAD_ID,
                Telephony.Sms.READ
            ),
            null,
            null,
            "${Telephony.Sms.DATE} DESC"
        )

        cursor?.use {
            while (it.moveToNext()) {
                val id = it.getString(it.getColumnIndexOrThrow(Telephony.Sms._ID))
                val address = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS))
                val body = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.BODY))
                val date = it.getLong(it.getColumnIndexOrThrow(Telephony.Sms.DATE))
                val type = it.getInt(it.getColumnIndexOrThrow(Telephony.Sms.TYPE))
                val threadId = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.THREAD_ID))
                val read = it.getInt(it.getColumnIndexOrThrow(Telephony.Sms.READ))

                messages.add(mapOf(
                    "id" to id,
                    "sender" to address,
                    "body" to (body ?: ""),
                    "timestamp" to date,
                    "messageType" to if (type == Telephony.Sms.MESSAGE_TYPE_INBOX) "SMS" else "SMS",
                    "threadId" to threadId,
                    "isRead" to (read == 1),
                    "isPhishing" to false,
                    "phishingScore" to 0.0,
                    "reason" to ""
                ))
            }
        }

        return messages
    }

    private fun getSmsByThread(threadId: String): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        val cursor = contentResolver.query(
            Telephony.Sms.CONTENT_URI,
            arrayOf(
                Telephony.Sms._ID,
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE,
                Telephony.Sms.TYPE,
                Telephony.Sms.THREAD_ID,
                Telephony.Sms.READ
            ),
            "${Telephony.Sms.THREAD_ID} = ?",
            arrayOf(threadId),
            "${Telephony.Sms.DATE} ASC"
        )

        cursor?.use {
            while (it.moveToNext()) {
                val id = it.getString(it.getColumnIndexOrThrow(Telephony.Sms._ID))
                val address = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS))
                val body = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.BODY))
                val date = it.getLong(it.getColumnIndexOrThrow(Telephony.Sms.DATE))
                val type = it.getInt(it.getColumnIndexOrThrow(Telephony.Sms.TYPE))
                val threadId = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.THREAD_ID))
                val read = it.getInt(it.getColumnIndexOrThrow(Telephony.Sms.READ))

                messages.add(mapOf(
                    "id" to id,
                    "sender" to address,
                    "body" to (body ?: ""),
                    "timestamp" to date,
                    "messageType" to if (type == Telephony.Sms.MESSAGE_TYPE_INBOX) "SMS" else "SMS",
                    "threadId" to threadId,
                    "isRead" to (read == 1),
                    "isPhishing" to false,
                    "phishingScore" to 0.0,
                    "reason" to ""
                ))
            }
        }

        return messages
    }

    private fun getAllSmsThreads(): List<Map<String, Any>> {
        val threads = mutableListOf<Map<String, Any>>()
        val cursor = contentResolver.query(
            Telephony.Sms.CONTENT_URI,
            arrayOf(
                "DISTINCT ${Telephony.Sms.THREAD_ID}",
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE,
                "COUNT(*) as message_count"
            ),
            null,
            null,
            "${Telephony.Sms.DATE} DESC"
        )

        cursor?.use {
            while (it.moveToNext()) {
                val threadId = it.getString(0)
                val address = it.getString(1)
                val body = it.getString(2)
                val date = it.getLong(3)
                val messageCount = it.getInt(4)

                threads.add(mapOf(
                    "id" to threadId,
                    "phoneNumber" to address,
                    "contactName" to "", // TODO: Get contact name from contacts
                    "lastMessage" to (body ?: ""),
                    "lastMessageTime" to date,
                    "unreadCount" to 0, // TODO: Calculate unread count
                    "isPhishing" to false
                ))
            }
        }

        return threads
    }

    private fun sendSms(phoneNumber: String, message: String): Boolean {
        return try {
            val smsManager = SmsManager.getDefault()
            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun sendMms(phoneNumber: String, message: String, imagePath: String?): Boolean {
        // TODO: Implement MMS sending
        return false
    }

    private fun deleteSms(messageId: String): Boolean {
        return try {
            val deleted = contentResolver.delete(
                Telephony.Sms.CONTENT_URI,
                "${Telephony.Sms._ID} = ?",
                arrayOf(messageId)
            )
            deleted > 0
        } catch (e: Exception) {
            false
        }
    }

    private fun markSmsAsRead(messageId: String): Boolean {
        return try {
            val values = android.content.ContentValues().apply {
                put(Telephony.Sms.READ, 1)
            }
            val updated = contentResolver.update(
                Telephony.Sms.CONTENT_URI,
                values,
                "${Telephony.Sms._ID} = ?",
                arrayOf(messageId)
            )
            updated > 0
        } catch (e: Exception) {
            false
        }
    }

    private fun isDefaultSmsApp(): Boolean {
        return Telephony.Sms.getDefaultSmsPackage(this) == packageName
    }

    private fun requestSetAsDefaultSmsApp() {
        val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
        intent.putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, packageName)
        startActivity(intent)
    }

    private fun getContacts(): List<Map<String, Any>> {
        val contacts = mutableListOf<Map<String, Any>>()
        val cursor = contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER,
                ContactsContract.CommonDataKinds.Phone.PHOTO_URI
            ),
            null,
            null,
            "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} ASC"
        )

        cursor?.use {
            while (it.moveToNext()) {
                val contactId = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.CONTACT_ID))
                val displayName = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME))
                val phoneNumber = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER))
                val photoUri = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.PHOTO_URI))

                contacts.add(mapOf(
                    "id" to contactId,
                    "name" to (displayName ?: ""),
                    "phoneNumber" to (phoneNumber ?: ""),
                    "photoUri" to (photoUri ?: "")
                ))
            }
        }

        return contacts
    }

    private fun getContactByPhone(phoneNumber: String): Map<String, Any>? {
        val cursor = contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER,
                ContactsContract.CommonDataKinds.Phone.PHOTO_URI
            ),
            "${ContactsContract.CommonDataKinds.Phone.NUMBER} = ?",
            arrayOf(phoneNumber),
            null
        )

        cursor?.use {
            if (it.moveToFirst()) {
                val contactId = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.CONTACT_ID))
                val displayName = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME))
                val phoneNumber = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER))
                val photoUri = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.PHOTO_URI))

                return mapOf(
                    "id" to contactId,
                    "name" to (displayName ?: ""),
                    "phoneNumber" to (phoneNumber ?: ""),
                    "photoUri" to (photoUri ?: "")
                )
            }
        }

        return null
    }

    private fun sendMmsWithImage(phoneNumber: String, message: String, imagePath: String): Boolean {
        return try {
            // For MMS with image, we need to use a different approach
            // This is a simplified implementation
            val smsManager = SmsManager.getDefault()
            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun getSmsThreads(): List<Map<String, Any>> {
        val threads = mutableListOf<Map<String, Any>>()
        val cursor: Cursor? = contentResolver.query(
            Telephony.Sms.CONTENT_URI,
            arrayOf(
                Telephony.Sms.THREAD_ID,
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE,
                Telephony.Sms.READ
            ),
            null,
            null,
            "${Telephony.Sms.DATE} DESC"
        )

        val threadMap = mutableMapOf<String, MutableMap<String, Any>>()

        cursor?.use {
            val threadIdColumn = it.getColumnIndex(Telephony.Sms.THREAD_ID)
            val addressColumn = it.getColumnIndex(Telephony.Sms.ADDRESS)
            val bodyColumn = it.getColumnIndex(Telephony.Sms.BODY)
            val dateColumn = it.getColumnIndex(Telephony.Sms.DATE)
            val readColumn = it.getColumnIndex(Telephony.Sms.READ)

            while (it.moveToNext()) {
                val threadId = it.getString(threadIdColumn)
                val address = it.getString(addressColumn)
                val body = it.getString(bodyColumn)
                val date = it.getLong(dateColumn)
                val read = it.getInt(readColumn)

                if (threadMap.containsKey(threadId)) {
                    val thread = threadMap[threadId]!!
                    thread["messageCount"] = (thread["messageCount"] as Int) + 1
                    if (read == 0) {
                        thread["unreadCount"] = (thread["unreadCount"] as Int) + 1
                    }
                    if (date > (thread["timestamp"] as Long)) {
                        thread["snippet"] = body
                        thread["timestamp"] = date
                    }
                } else {
                    threadMap[threadId] = mutableMapOf(
                        "id" to threadId,
                        "contactName" to address,
                        "phoneNumber" to address,
                        "snippet" to body,
                        "timestamp" to date,
                        "messageCount" to 1,
                        "unreadCount" to if (read == 0) 1 else 0,
                        "isPhishing" to false
                    )
                }
            }
        }

        threads.addAll(threadMap.values)
        return threads
    }
}