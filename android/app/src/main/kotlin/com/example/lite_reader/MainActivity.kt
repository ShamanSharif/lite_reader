package com.example.lite_reader

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// Bridges Android "Open with…" intents into Flutter.
///
/// When the app is launched (or resumed) with a VIEW intent for a PDF/EPUB, we
/// copy the (possibly `content://`) stream into our cache directory and hand the
/// resulting real file path to Dart over a [MethodChannel]. Dart can then import
/// it with plain `dart:io` — no need to teach the Dart side about content URIs.
///
/// Uses only APIs available since API 21 (no scoped-storage / MediaStore calls).
class MainActivity : FlutterActivity() {
    private val channelName = "com.example.lite_reader/intents"
    private var channel: MethodChannel? = null

    // Path captured from the intent that cold-started the app.
    private var initialFilePath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initialFilePath = resolveIntentToCachedPath(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialFile" -> {
                    result.success(initialFilePath)
                    initialFilePath = null
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val path = resolveIntentToCachedPath(intent)
        if (path != null) {
            channel?.invokeMethod("openFile", path)
        }
    }

    /// Copies the VIEW intent's data URI into cache and returns its path, or null.
    private fun resolveIntentToCachedPath(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_VIEW) return null
        val uri = intent.data ?: return null
        return try {
            copyUriToCache(uri)
        } catch (e: Exception) {
            null
        }
    }

    private fun copyUriToCache(uri: Uri): String? {
        val fileName = queryDisplayName(uri) ?: "imported_${System.currentTimeMillis()}"
        val safeName = ensureSupportedExtension(fileName, uri)
        val outFile = File(cacheDir, safeName)

        contentResolver.openInputStream(uri)?.use { input ->
            outFile.outputStream().use { output ->
                input.copyTo(output)
            }
        } ?: return null

        return outFile.absolutePath
    }

    private fun queryDisplayName(uri: Uri): String? {
        if (uri.scheme == "file") return uri.lastPathSegment
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) {
                return cursor.getString(index)
            }
        }
        return null
    }

    /// Guarantees the cached file ends in .pdf/.epub so the Dart side can detect
    /// its format from the path, falling back to the MIME type when needed.
    private fun ensureSupportedExtension(name: String, uri: Uri): String {
        val lower = name.lowercase()
        if (lower.endsWith(".pdf") || lower.endsWith(".epub")) return name
        val mime = contentResolver.getType(uri)
        val ext = when (mime) {
            "application/pdf" -> ".pdf"
            "application/epub+zip" -> ".epub"
            else -> ""
        }
        return "$name$ext"
    }
}
