package com.example.coder_flutter

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PICKER_CHANNEL = "coder_flutter/picker"
    private val SETTINGS_CHANNEL = "coder_flutter/settings"
    private var pendingResult: MethodChannel.Result? = null
    private val PICK_IMAGE_REQUEST = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PICKER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickImage") {
                pendingResult = result
                val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                    type = "image/*"
                    addCategory(Intent.CATEGORY_OPENABLE)
                }
                startActivityForResult(intent, PICK_IMAGE_REQUEST)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences("coder_flutter_settings", Activity.MODE_PRIVATE)
            when (call.method) {
                "loadSettings" -> {
                    val settings = prefs.getString("settings", null)
                    result.success(settings)
                }
                "saveSettings" -> {
                    val settings = call.argument<String>("settings")
                    prefs.edit().putString("settings", settings).apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_IMAGE_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                try {
                    contentResolver.openInputStream(data.data!!)?.use { inputStream ->
                        val bytes = inputStream.readBytes()
                        pendingResult?.success(bytes)
                    } ?: pendingResult?.success(null)
                } catch (e: Exception) {
                    pendingResult?.error("READ_ERROR", e.message, null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }
}
