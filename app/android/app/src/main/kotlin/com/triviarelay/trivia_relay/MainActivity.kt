package com.triviarelay.trivia_relay

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // The lobby's "Share" (lib/shared/platform/platform_io.dart): Android's own share
    // sheet for an invite's text, with no plugin for it.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "trivia_relay/share")
            .setMethodCallHandler { call, result ->
                val text = call.argument<String>("text")
                if (call.method != "share" || text.isNullOrEmpty()) {
                    result.notImplemented()
                } else {
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                    startActivity(Intent.createChooser(send, null))
                    result.success(true)
                }
            }
    }
}
