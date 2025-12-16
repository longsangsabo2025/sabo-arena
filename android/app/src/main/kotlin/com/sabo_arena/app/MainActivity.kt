package com.sabo_arena.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.inputmethod.InputMethodManager
import android.content.Context
import android.view.View
import android.view.inputmethod.EditorInfo

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.sabo_arena.app/vietnamese_input"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableVietnameseInput" -> {
                    enableVietnameseInput()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun enableVietnameseInput() {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        val currentFocus = currentFocus
        if (currentFocus != null) {
            // Force restart input connection to properly handle Vietnamese
            imm.restartInput(currentFocus)
        }
    }
}