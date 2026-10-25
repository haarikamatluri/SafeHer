package com.SafeHer.app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager

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

                    if (phone.isNullOrBlank() || message.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "Phone number and message must not be empty", null)
                        return@setMethodCallHandler
                    }

                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "recipient" to phone,
                                "errorCode" to "PERMISSION_DENIED",
                                "error" to "SEND_SMS permission was denied by the user. Enable SMS permission in Android settings."
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
                                "errorCode" to "NO_SIM_CARD",
                                "error" to "No SIM card detected in device. A working SIM card is required to dispatch SMS."
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

                        val uniqueId = System.currentTimeMillis()
                        val sentAction = "com.SafeHer.app.SMS_SENT_$uniqueId"
                        val deliveryAction = "com.SafeHer.app.SMS_DELIVERED_$uniqueId"

                        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_ONE_SHOT
                        } else {
                            PendingIntent.FLAG_ONE_SHOT
                        }

                        val sentIntent = PendingIntent.getBroadcast(
                            context,
                            0,
                            Intent(sentAction),
                            flags
                        )

                        val deliveryIntent = PendingIntent.getBroadcast(
                            context,
                            0,
                            Intent(deliveryAction),
                            flags
                        )

                        val parts = smsManager.divideMessage(message)
                        var resultHandled = false
                        val mainHandler = Handler(Looper.getMainLooper())

                        val sentReceiver = object : BroadcastReceiver() {
                            override fun onReceive(ctx: Context?, intent: Intent?) {
                                if (resultHandled) return
                                resultHandled = true
                                try {
                                    context.unregisterReceiver(this)
                                } catch (_: Exception) {}

                                val isOk = resultCode == Activity.RESULT_OK
                                val errorCode = when (resultCode) {
                                    Activity.RESULT_OK -> null
                                    SmsManager.RESULT_ERROR_NO_SERVICE -> "NO_SERVICE"
                                    SmsManager.RESULT_ERROR_RADIO_OFF -> "RADIO_OFF"
                                    SmsManager.RESULT_ERROR_NULL_PDU -> "NULL_PDU"
                                    else -> "GENERIC_FAILURE"
                                }

                                val errorMsg = when (resultCode) {
                                    Activity.RESULT_OK -> null
                                    SmsManager.RESULT_ERROR_NO_SERVICE -> "No cellular network service available to send SMS."
                                    SmsManager.RESULT_ERROR_RADIO_OFF -> "Cellular radio is off or Airplane mode is active."
                                    SmsManager.RESULT_ERROR_NULL_PDU -> "Null PDU format error in SMS payload."
                                    else -> "Cellular carrier rejected SMS dispatch (insufficient balance or invalid number)."
                                }

                                result.success(
                                    mapOf(
                                        "success" to isOk,
                                        "recipient" to phone,
                                        "sentStatus" to if (isOk) "sent_to_network" else "failed",
                                        "isDeliveredConfirmed" to false,
                                        "errorCode" to errorCode,
                                        "error" to errorMsg,
                                        "partsCount" to parts.size
                                    )
                                )
                            }
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            context.registerReceiver(
                                sentReceiver,
                                IntentFilter(sentAction),
                                Context.RECEIVER_NOT_EXPORTED
                            )
                        } else {
                            context.registerReceiver(
                                sentReceiver,
                                IntentFilter(sentAction)
                            )
                        }

                        // Fallback timeout in case carrier callback is delayed
                        mainHandler.postDelayed({
                            if (!resultHandled) {
                                resultHandled = true
                                try {
                                    context.unregisterReceiver(sentReceiver)
                                } catch (_: Exception) {}

                                result.success(
                                    mapOf(
                                        "success" to true,
                                        "recipient" to phone,
                                        "sentStatus" to "sent_unacknowledged",
                                        "isDeliveredConfirmed" to false,
                                        "partsCount" to parts.size,
                                        "note" to "SMS submitted to modem; network confirmation timed out."
                                    )
                                )
                            }
                        }, 5000)

                        if (parts.size > 1) {
                            val sentIntents = ArrayList<PendingIntent>()
                            val deliveryIntents = ArrayList<PendingIntent>()
                            for (i in 0 until parts.size) {
                                sentIntents.add(sentIntent)
                                deliveryIntents.add(deliveryIntent)
                            }
                            smsManager.sendMultipartTextMessage(phone, null, parts, sentIntents, deliveryIntents)
                        } else {
                            smsManager.sendTextMessage(phone, null, message, sentIntent, deliveryIntent)
                        }

                    } catch (e: Exception) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "recipient" to phone,
                                "errorCode" to "EXCEPTION",
                                "error" to (e.localizedMessage ?: e.message ?: "Unknown SMS sending failure")
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

