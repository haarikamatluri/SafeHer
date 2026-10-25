package com.SafeHer.app

import android.Manifest
import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.telephony.SmsManager
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.SafeHer.app/native_sms"
    private val SMS_PERMISSION_REQUEST_CODE = 9001
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasSmsPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.SEND_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }
                "requestSmsPermission" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED) {
                        result.success(true)
                    } else {
                        pendingPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.SEND_SMS),
                            SMS_PERMISSION_REQUEST_CODE
                        )
                    }
                }
                "sendDirectSms" -> {
                    val phone = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")
                    val incidentId = call.argument<String>("incidentId") ?: "inc"

                    if (phone.isNullOrBlank() || message.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "Phone number and message must not be empty", null)
                        return@setMethodCallHandler
                    }

                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "recipient" to phone,
                                "sentStatus" to "failed",
                                "errorCode" to "PERMISSION_DENIED",
                                "error" to "SEND_SMS permission was denied. Please grant SMS permission in Android settings."
                            )
                        )
                        return@setMethodCallHandler
                    }

                    // Check SIM card presence
                    val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                    val simState = telephonyManager?.simState ?: TelephonyManager.SIM_STATE_UNKNOWN
                    if (simState == TelephonyManager.SIM_STATE_ABSENT) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "recipient" to phone,
                                "sentStatus" to "failed",
                                "errorCode" to "NO_SIM_CARD",
                                "error" to "No active SIM card detected in device. A working SIM is required to send emergency SMS."
                            )
                        )
                        return@setMethodCallHandler
                    }

                    // Check airplane mode
                    val isAirplaneModeOn = try {
                        Settings.Global.getInt(contentResolver, Settings.Global.AIRPLANE_MODE_ON, 0) != 0
                    } catch (_: Exception) {
                        false
                    }
                    if (isAirplaneModeOn) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "recipient" to phone,
                                "sentStatus" to "failed",
                                "errorCode" to "RADIO_OFF",
                                "error" to "Airplane mode is active. Disable Airplane mode to allow emergency cellular SMS dispatch."
                            )
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            applicationContext.getSystemService(SmsManager::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }

                        val parts = smsManager.divideMessage(message)
                        val partsCount = parts.size
                        val uniqueSeed = System.currentTimeMillis()
                        val sentIntents = ArrayList<PendingIntent>()
                        val deliveryIntents = ArrayList<PendingIntent>()

                        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        } else {
                            PendingIntent.FLAG_UPDATE_CURRENT
                        }

                        val resultHandled = AtomicBoolean(false)
                        val mainHandler = Handler(Looper.getMainLooper())
                        val partsReported = AtomicInteger(0)
                        val partsSucceeded = AtomicInteger(0)
                        var firstErrorCode: String? = null
                        var firstErrorMessage: String? = null

                        val sentActionPrefix = "com.SafeHer.app.SMS_SENT_${uniqueSeed}_${incidentId}"
                        val deliveryActionPrefix = "com.SafeHer.app.SMS_DELIVERED_${uniqueSeed}_${incidentId}"

                        var sentReceiver: BroadcastReceiver? = null
                        var deliveryReceiver: BroadcastReceiver? = null

                        fun safeUnregisterReceivers() {
                            try {
                                sentReceiver?.let { context.unregisterReceiver(it) }
                            } catch (_: Exception) {}
                            sentReceiver = null

                            try {
                                deliveryReceiver?.let { context.unregisterReceiver(it) }
                            } catch (_: Exception) {}
                            deliveryReceiver = null
                        }

                        val sentFilter = IntentFilter()
                        val deliveryFilter = IntentFilter()

                        for (i in 0 until partsCount) {
                            val partSentAction = "${sentActionPrefix}_$i"
                            val partDeliveryAction = "${deliveryActionPrefix}_$i"
                            sentFilter.addAction(partSentAction)
                            deliveryFilter.addAction(partDeliveryAction)

                            val requestCode = ((uniqueSeed % 100000).toInt() * 10) + i
                            val sIntent = PendingIntent.getBroadcast(
                                context,
                                requestCode,
                                Intent(partSentAction),
                                flags
                            )
                            val dIntent = PendingIntent.getBroadcast(
                                context,
                                requestCode + 1000,
                                Intent(partDeliveryAction),
                                flags
                            )
                            sentIntents.add(sIntent)
                            deliveryIntents.add(dIntent)
                        }

                        sentReceiver = object : BroadcastReceiver() {
                            override fun onReceive(ctx: Context?, intent: Intent?) {
                                val currentCount = partsReported.incrementAndGet()
                                val isOk = resultCode == Activity.RESULT_OK
                                if (isOk) {
                                    partsSucceeded.incrementAndGet()
                                } else if (firstErrorCode == null) {
                                    firstErrorCode = when (resultCode) {
                                        SmsManager.RESULT_ERROR_NO_SERVICE -> "NO_SERVICE"
                                        SmsManager.RESULT_ERROR_RADIO_OFF -> "RADIO_OFF"
                                        SmsManager.RESULT_ERROR_NULL_PDU -> "NULL_PDU"
                                        else -> "GENERIC_FAILURE"
                                    }
                                    firstErrorMessage = when (resultCode) {
                                        SmsManager.RESULT_ERROR_NO_SERVICE -> "No cellular network service available to dispatch SMS."
                                        SmsManager.RESULT_ERROR_RADIO_OFF -> "Cellular radio is offline or powered down."
                                        SmsManager.RESULT_ERROR_NULL_PDU -> "Null PDU format error in SMS payload."
                                        else -> "Cellular carrier rejected SMS dispatch (insufficient balance or invalid number)."
                                    }
                                }

                                if (currentCount >= partsCount && !resultHandled.get()) {
                                    if (resultHandled.compareAndSet(false, true)) {
                                        safeUnregisterReceivers()
                                        val allOk = partsSucceeded.get() == partsCount
                                        result.success(
                                            mapOf(
                                                "success" to allOk,
                                                "recipient" to phone,
                                                "sentStatus" to if (allOk) "sent_to_network" else "failed",
                                                "isDeliveredConfirmed" to false,
                                                "errorCode" to if (allOk) null else (firstErrorCode ?: "SEND_FAILED"),
                                                "error" to if (allOk) null else (firstErrorMessage ?: "SMS dispatch rejected by radio"),
                                                "partsCount" to partsCount
                                            )
                                        )
                                    }
                                }
                            }
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            context.registerReceiver(
                                sentReceiver,
                                sentFilter,
                                Context.RECEIVER_NOT_EXPORTED
                            )
                        } else {
                            context.registerReceiver(
                                sentReceiver,
                                sentFilter
                            )
                        }

                        // Fallback timeout in case carrier callback is delayed beyond 5 seconds
                        mainHandler.postDelayed({
                            if (resultHandled.compareAndSet(false, true)) {
                                safeUnregisterReceivers()
                                val partsOk = partsSucceeded.get()
                                val isAccepted = partsOk > 0 || partsReported.get() == 0
                                result.success(
                                    mapOf(
                                        "success" to isAccepted,
                                        "recipient" to phone,
                                        "sentStatus" to if (isAccepted) "sent_unacknowledged" else "failed",
                                        "isDeliveredConfirmed" to false,
                                        "partsCount" to partsCount,
                                        "note" to "SMS submitted to cellular radio; carrier response timed out."
                                    )
                                )
                            }
                        }, 5000)

                        if (partsCount > 1) {
                            smsManager.sendMultipartTextMessage(phone, null, parts, sentIntents, deliveryIntents)
                        } else {
                            smsManager.sendTextMessage(phone, null, message, sentIntents[0], deliveryIntents[0])
                        }

                    } catch (e: Exception) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "recipient" to phone,
                                "sentStatus" to "failed",
                                "errorCode" to "EXCEPTION",
                                "error" to (e.localizedMessage ?: e.message ?: "Unknown SMS dispatch exception")
                            )
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }
}
