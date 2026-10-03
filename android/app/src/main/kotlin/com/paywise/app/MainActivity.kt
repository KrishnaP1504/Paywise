package com.paywise.app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Allow taking screenshots and screen recordings
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}

