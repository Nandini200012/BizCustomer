package com.Bizatom.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "dialer.channel/call"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "makeCall") {
                val number = call.argument<String>("number")
                if (!number.isNullOrBlank()) {
                    val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number"))
                    try {
                        startActivity(intent)
                        result.success("Calling $number")
                    } catch (e: Exception) {
                        result.error("CALL_FAILED", "Call failed: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_NUMBER", "Phone number is empty or null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}