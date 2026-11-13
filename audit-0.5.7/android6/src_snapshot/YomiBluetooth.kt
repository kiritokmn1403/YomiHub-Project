package com.kodjodevf.mangayomi

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.UUID
import kotlin.concurrent.thread

/**
 * YomiHub 0.2.0: Bluetooth for "AirDrop & Quicksharing".
 *
 *  * direct YomiHub ⇄ YomiHub transfer over RFCOMM (works without Wi-Fi):
 *    one side taps "Nhận qua Bluetooth" (server socket), the other picks the
 *    paired phone and sends; frames = [int json-length][json {name,size}]
 *    [bytes]…, ended by a zero-length frame;
 *  * any other device (PC with Windows "Gửi/nhận tệp Bluetooth", old phones):
 *    the system Bluetooth share (OBEX Object Push) for sending, and the
 *    "make visible" request + the system Bluetooth folder for receiving.
 */
class YomiBluetooth(private val activity: Activity, messenger: BinaryMessenger) {
    companion object {
        val SERVICE: UUID = UUID.fromString("6f1d3c2a-9b7e-4f5a-a1c2-59a0b1d2e3f4")
        const val NAME = "YomiHub-Share"
        const val REQ_PERM = 47391
    }

    private val main = Handler(Looper.getMainLooper())
    private val channel = MethodChannel(messenger, "yomihub/bluetooth")
    @Volatile private var server: BluetoothServerSocket? = null
    @Volatile private var cancelled = false

    private val adapter: BluetoothAdapter?
        get() = try {
            (activity.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
        } catch (_: Exception) { null }

    private fun perms(): Array<String> = if (Build.VERSION.SDK_INT >= 31)
        arrayOf(Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_ADVERTISE)
    else arrayOf(Manifest.permission.BLUETOOTH, Manifest.permission.BLUETOOTH_ADMIN)

    private fun granted(): Boolean = perms().all {
        ContextCompat.checkSelfPermission(activity, it) == PackageManager.PERMISSION_GRANTED
    }

    private fun emit(method: String, args: Any?) {
        main.post {
            try { channel.invokeMethod(method, args) } catch (_: Exception) {}
        }
    }

    init {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "state" -> result.success(state())
                    "requestPermissions" -> {
                        if (!granted()) ActivityCompat.requestPermissions(activity, perms(), REQ_PERM)
                        result.success(granted())
                    }
                    "enable" -> {
                        activity.startActivity(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE))
                        result.success(true)
                    }
                    "discoverable" -> {
                        activity.startActivity(Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE)
                            .putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300))
                        result.success(true)
                    }
                    "settings" -> {
                        activity.startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                        result.success(true)
                    }
                    "paired" -> result.success(paired())
                    "sendSystem" -> result.success(sendSystem(call.argument<List<String>>("paths") ?: emptyList()))
                    "listen" -> { listen(call.argument<String>("dir") ?: defaultDir()); result.success(true) }
                    "stop" -> { stop(); result.success(true) }
                    "send" -> {
                        val addr = call.argument<String>("address") ?: ""
                        val paths = call.argument<List<String>>("paths") ?: emptyList()
                        thread(name = "yh-bt-send") { send(addr, paths) }
                        result.success(true)
                    }
                    "cancel" -> { cancelled = true; result.success(true) }
                    "systemFolders" -> result.success(systemFolders())
                    else -> result.notImplemented()
                }
            } catch (e: SecurityException) {
                result.error("perm", e.message, null)
            } catch (e: Exception) {
                result.error("bt", e.message, null)
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun state(): Map<String, Any?> {
        val a = adapter
        return mapOf(
            "supported" to (a != null),
            "enabled" to (a?.isEnabled == true),
            "granted" to granted(),
            "name" to (if (granted()) try { a?.name } catch (_: Exception) { null } else null),
            "listening" to (server != null),
        )
    }

    @SuppressLint("MissingPermission")
    private fun paired(): List<Map<String, String>> {
        val a = adapter ?: return emptyList()
        if (!granted()) return emptyList()
        return a.bondedDevices.map { mapOf("name" to (it.name ?: it.address), "address" to it.address) }
    }

    private fun defaultDir(): String {
        val d = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "YomiHub/Bluetooth")
        return if (d.exists() || d.mkdirs()) d.absolutePath
        else File(activity.getExternalFilesDir(null), "Bluetooth").apply { mkdirs() }.absolutePath
    }

    /** Folders where the system Bluetooth (OBEX) service stores received files. */
    private fun systemFolders(): List<String> {
        val root = Environment.getExternalStorageDirectory()
        return listOf(
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "Bluetooth"),
            File(root, "bluetooth"), File(root, "Bluetooth"),
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
        ).filter { it.isDirectory }.map { it.absolutePath }.distinct()
    }

    private fun uri(f: File): Uri = FileProvider.getUriForFile(activity, "${activity.packageName}.fileprovider", f)

    /** OBEX push through the system Bluetooth app (any phone / PC). */
    private fun sendSystem(paths: List<String>): Boolean {
        val uris = ArrayList(paths.map { uri(File(it)) })
        if (uris.isEmpty()) return false
        val i = if (uris.size == 1) Intent(Intent.ACTION_SEND).putExtra(Intent.EXTRA_STREAM, uris[0])
        else Intent(Intent.ACTION_SEND_MULTIPLE).putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
        i.type = "*/*"
        i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        val bt = activity.packageManager.queryIntentActivities(i, 0)
            .firstOrNull { it.activityInfo.packageName.contains("bluetooth", true) }
        if (bt != null) {
            i.setClassName(bt.activityInfo.packageName, bt.activityInfo.name)
            activity.startActivity(i)
        } else {
            activity.startActivity(Intent.createChooser(i, "Bluetooth"))
        }
        return bt != null
    }

    @SuppressLint("MissingPermission")
    private fun listen(dir: String) {
        if (server != null) return
        val a = adapter ?: throw IllegalStateException("no-adapter")
        server = a.listenUsingRfcommWithServiceRecord(NAME, SERVICE)
        thread(name = "yh-bt-server") {
            while (true) {
                val s = server ?: break
                val sock = try { s.accept() } catch (_: Exception) { null } ?: break
                thread(name = "yh-bt-recv") { receive(sock, dir) }
            }
            server = null
            emit("btState", "stopped")
        }
        emit("btState", "listening")
    }

    private fun stop() {
        try { server?.close() } catch (_: Exception) {}
        server = null
    }

    @SuppressLint("MissingPermission")
    private fun receive(sock: BluetoothSocket, dir: String) {
        val from = try { sock.remoteDevice.name ?: sock.remoteDevice.address } catch (_: Exception) { "?" }
        try {
            val inp = DataInputStream(BufferedInputStream(sock.inputStream, 64 * 1024))
            val buf = ByteArray(64 * 1024)
            while (true) {
                val len = inp.readInt()
                if (len <= 0) break
                val hb = ByteArray(len); inp.readFully(hb)
                val h = JSONObject(String(hb, Charsets.UTF_8))
                val name = File(h.optString("name", "file")).name.ifEmpty { "file" }
                val size = h.optLong("size", 0)
                var out = File(dir, name)
                var n = 1
                while (out.exists()) { out = File(dir, "${out.nameWithoutExtension.substringBeforeLast(" (")} (${n++}).${File(name).extension}") }
                FileOutputStream(out).use { fo ->
                    val bo = BufferedOutputStream(fo, 64 * 1024)
                    var left = size; var done = 0L; var last = 0L
                    while (left > 0) {
                        val r = inp.read(buf, 0, minOf(buf.size.toLong(), left).toInt())
                        if (r < 0) throw java.io.EOFException()
                        bo.write(buf, 0, r); left -= r; done += r
                        if (done - last > 256 * 1024 || left == 0L) {
                            last = done
                            emit("btProgress", mapOf("dir" to "in", "name" to name, "done" to done, "size" to size, "peer" to from))
                        }
                    }
                    bo.flush()
                }
                emit("btReceived", mapOf("path" to out.absolutePath, "peer" to from))
            }
        } catch (e: Exception) {
            emit("btError", "${e.message}")
        } finally {
            try { sock.close() } catch (_: Exception) {}
        }
    }

    @SuppressLint("MissingPermission")
    private fun send(address: String, paths: List<String>) {
        cancelled = false
        val a = adapter
        if (a == null) { emit("btError", "no-adapter"); return }
        var sock: BluetoothSocket? = null
        try {
            try { a.cancelDiscovery() } catch (_: Exception) {}
            sock = a.getRemoteDevice(address).createRfcommSocketToServiceRecord(SERVICE)
            sock.connect()
            val out = DataOutputStream(BufferedOutputStream(sock.outputStream, 64 * 1024))
            val buf = ByteArray(64 * 1024)
            for (p in paths) {
                val f = File(p)
                if (!f.isFile) continue
                val h = JSONObject().put("name", f.name).put("size", f.length()).toString().toByteArray(Charsets.UTF_8)
                out.writeInt(h.size); out.write(h)
                FileInputStream(f).use { fi ->
                    var done = 0L; var last = 0L
                    while (true) {
                        if (cancelled) throw InterruptedException("cancelled")
                        val r = fi.read(buf); if (r < 0) break
                        out.write(buf, 0, r); done += r
                        if (done - last > 256 * 1024 || done == f.length()) {
                            last = done
                            emit("btProgress", mapOf("dir" to "out", "name" to f.name, "done" to done, "size" to f.length()))
                        }
                    }
                }
            }
            out.writeInt(0); out.flush()
            Thread.sleep(400)
            emit("btSent", paths.size)
        } catch (e: Exception) {
            emit("btError", "${e.message}")
        } finally {
            try { sock?.close() } catch (_: Exception) {}
        }
    }
}
