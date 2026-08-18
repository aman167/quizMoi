package com.quizmoi.quiz_moi_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val sourceImportChannel = "com.quizmoi.quiz_moi/source_import"
    private val pickPdfRequestCode = 7001
    private var pendingPickerResult: MethodChannel.Result? = null
    private var maximumPdfBytes = 10 * 1024 * 1024

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sourceImportChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "pickPdf") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingPickerResult != null) {
                    result.error("picker_busy", "A document picker is already open.", null)
                    return@setMethodCallHandler
                }
                maximumPdfBytes = call.argument<Int>("maxBytes") ?: maximumPdfBytes
                pendingPickerResult = result
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "application/pdf"
                }
                try {
                    startActivityForResult(intent, pickPdfRequestCode)
                } catch (error: Exception) {
                    pendingPickerResult = null
                    result.error("picker_unavailable", "The Android document picker is unavailable.", null)
                }
            }
    }

    @Deprecated("Deprecated in Android; retained for FlutterActivity picker compatibility.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickPdfRequestCode) return

        val result = pendingPickerResult ?: return
        pendingPickerResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }
        readSelectedPdf(data.data!!, result)
    }

    private fun readSelectedPdf(uri: Uri, result: MethodChannel.Result) {
        try {
            val fileName = queryDisplayName(uri) ?: "Imported PDF.pdf"
            val output = ByteArrayOutputStream()
            contentResolver.openInputStream(uri).use { input ->
                if (input == null) {
                    result.error("unreadable", "Android could not open the selected PDF.", null)
                    return
                }
                val buffer = ByteArray(8192)
                var totalBytes = 0
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    totalBytes += count
                    if (totalBytes > maximumPdfBytes) {
                        result.error("file_too_large", "The selected PDF exceeds the size limit.", null)
                        return
                    }
                    output.write(buffer, 0, count)
                }
            }
            result.success(mapOf("fileName" to fileName, "bytes" to output.toByteArray()))
        } catch (error: Exception) {
            result.error("unreadable", "Android could not read the selected PDF.", null)
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null).use { cursor ->
            if (cursor == null || !cursor.moveToFirst()) return null
            val nameColumn = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            return if (nameColumn >= 0) cursor.getString(nameColumn) else null
        }
    }
}
