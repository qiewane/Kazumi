package com.predidit.kazumi

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.view.KeyEvent
import androidx.annotation.NonNull

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.predidit.kazumi/tv"
    private var tvChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        tvChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        tvChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isTVDevice" -> {
                    result.success(isTVDevice())
                }
                "getDeviceType" -> {
                    result.success(getDeviceType())
                }
                "handleBackKey" -> {
                    // 处理返回键，由 Flutter 决定是否退出
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // 拦截特定按键传递给 Flutter
        when (keyCode) {
            KeyEvent.KEYCODE_BACK -> {
                tvChannel?.invokeMethod("onBackPressed", null)
                return true // 阻止默认返回行为，由 Flutter 处理
            }
            KeyEvent.KEYCODE_MENU -> {
                tvChannel?.invokeMethod("onMenuPressed", null)
                return true
            }
            KeyEvent.KEYCODE_GUIDE -> {
                tvChannel?.invokeMethod("onGuidePressed", null)
                return true
            }
            KeyEvent.KEYCODE_DPAD_CENTER,
            KeyEvent.KEYCODE_ENTER,
            KeyEvent.KEYCODE_NUMPAD_ENTER -> {
                tvChannel?.invokeMethod("onSelectPressed", null)
                return super.onKeyDown(keyCode, event)
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    private fun isTVDevice(): Boolean {
        val uiMode = resources.configuration.uiMode
        return (uiMode and android.content.res.Configuration.UI_MODE_TYPE_MASK) == 
               android.content.res.Configuration.UI_MODE_TYPE_TELEVISION
    }

    private fun getDeviceType(): String {
        return when {
            isTVDevice() -> "tv"
            resources.configuration.smallestScreenWidthDp >= 600 -> "tablet"
            else -> "phone"
        }
    }
}
