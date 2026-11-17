package com.kodjodevf.mangayomi

import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.TextRecognizer
import com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
import com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * YomiHub 0.1.9: text recognition for "Dịch ảnh" in the comic reader.
 *
 * Google ML Kit through Google Play services (the recognition models are
 * downloaded by Play services, so they don't add to the APK). Returns the
 * text blocks of a page with their boxes in image pixels.
 */
object YomiOcr {
    private val main = Handler(Looper.getMainLooper())
    private val recognizers = ConcurrentHashMap<String, TextRecognizer>()

    private fun recognizer(script: String): TextRecognizer = recognizers.getOrPut(script) {
        when (script) {
            "ja" -> TextRecognition.getClient(JapaneseTextRecognizerOptions.Builder().build())
            "zh" -> TextRecognition.getClient(ChineseTextRecognizerOptions.Builder().build())
            "ko" -> TextRecognition.getClient(KoreanTextRecognizerOptions.Builder().build())
            else -> TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        }
    }

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "yomihub/ocr").setMethodCallHandler { call, result ->
            when (call.method) {
                "recognize" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val script = call.argument<String>("script") ?: "auto"
                    if (bytes == null) {
                        result.error("args", "no image", null); return@setMethodCallHandler
                    }
                    Thread {
                        val out = try {
                            recognize(bytes, script).toString()
                        } catch (e: Throwable) {
                            JSONObject().put("error", e.message ?: e.toString()).toString()
                        }
                        main.post { result.success(out) }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun run(r: TextRecognizer, img: InputImage): Text? {
        val latch = CountDownLatch(1)
        var text: Text? = null
        var err: Exception? = null
        r.process(img).addOnSuccessListener { text = it; latch.countDown() }
            .addOnFailureListener { err = it; latch.countDown() }
        latch.await(60, TimeUnit.SECONDS)
        err?.let { throw it }
        return text
    }

    private fun recognize(bytes: ByteArray, script: String): JSONObject {
        val opts = BitmapFactory.Options()
        val bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, opts)
            ?: throw IllegalArgumentException("cannot decode image")
        val img = InputImage.fromBitmap(bmp, 0)
        // "auto": CJK recognizers also read Latin text; keep the one that
        // found the most characters
        val order = if (script == "auto") listOf("ja", "ko", "zh", "latin") else listOf(script)
        var best: Text? = null
        var bestLen = -1
        val errors = ArrayList<String>()
        for (s in order) {
            val t = try {
                run(recognizer(s), img)
            } catch (e: Throwable) {
                errors += "$s: ${e.message ?: e.javaClass.simpleName}"
                null
            } ?: continue
            val len = t.text.count { !it.isWhitespace() }
            if (len > bestLen) {
                best = t; bestLen = len
            }
            if (script == "auto" && len > 40) break
        }
        if (best == null && errors.isNotEmpty()) {
            bmp.recycle()
            // typically "Waiting for the text optional module to be downloaded"
            return JSONObject().put("error", errors.joinToString("; "))
        }
        val blocks = JSONArray()
        best?.textBlocks?.forEach { b ->
            val box = b.boundingBox ?: return@forEach
            val lines = JSONArray()
            b.lines.forEach { l ->
                val lb = l.boundingBox
                lines.put(JSONObject().put("text", l.text).put("angle", l.angle.toDouble()).apply {
                    if (lb != null) put("l", lb.left).put("t", lb.top).put("r", lb.right).put("b", lb.bottom)
                })
            }
            blocks.put(
                JSONObject().put("text", b.text)
                    .put("l", box.left).put("t", box.top).put("r", box.right).put("b", box.bottom)
                    .put("lang", b.recognizedLanguage)
                    .put("lines", lines),
            )
        }
        bmp.recycle()
        return JSONObject().put("w", opts.outWidth).put("h", opts.outHeight).put("blocks", blocks)
    }
}
