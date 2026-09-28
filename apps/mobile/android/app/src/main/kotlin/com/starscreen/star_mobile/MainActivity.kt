package com.starscreen.star_mobile

import com.starscreen.jar.JarSpiderRuntime
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var jarRuntime: JarSpiderRuntime? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val rt = JarSpiderRuntime(applicationContext)
        jarRuntime = rt
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "starscreen/jar",
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "available" -> result.success(true)
                    "load" -> {
                        val path = call.argument<String>("jarPath") ?: ""
                        val className = call.argument<String>("className") ?: ""
                        val md5 = call.argument<String>("md5")
                        rt.load(path, className, md5)
                        result.success(true)
                    }
                    "call" -> {
                        val method = call.argument<String>("method") ?: ""
                        @Suppress("UNCHECKED_CAST")
                        val args = call.argument<Map<String, Any?>>("args") ?: emptyMap()
                        result.success(rt.call(method, args))
                    }
                    "dispose" -> {
                        rt.dispose()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Throwable) {
                result.error("jar", e.message ?: e.toString(), null)
            }
        }
    }

    override fun onDestroy() {
        jarRuntime?.dispose()
        super.onDestroy()
    }
}
