package yomihub.bridge

import java.io.File

/**
 * YomiHub JVM bridge (Windows). Started by the app with
 * `javaw -cp <lib folder> yomihub.bridge.MainKt --data <dir> [--kotatsu] [--ireader]`.
 * Exits on its own when the parent app is gone (stdin closed / --parent pid).
 */
fun main(args: Array<String>) {
    var data = File(System.getProperty("user.home"), ".yomihub-bridge")
    var kotatsu = false
    var ireader = false
    var parent = -1L
    var i = 0
    while (i < args.size) {
        when (args[i]) {
            "--data" -> data = File(args[++i])
            "--kotatsu" -> kotatsu = true
            "--ireader" -> ireader = true
            "--parent" -> parent = args[++i].toLongOrNull() ?: -1
            "--cf" -> KotatsuJvm.cfPort = args[++i].toIntOrNull() ?: 0
        }
        i++
    }
    if (!kotatsu && !ireader) {
        kotatsu = true; ireader = true
    }
    data.mkdirs()
    YomiNet.installCrashGuard()
    Store.init(data)
    if (kotatsu) try {
        KotatsuJvm.start()
    } catch (e: Throwable) {
        System.err.println("Kotatsu bridge failed: $e"); kotatsu = false
    }
    // IReader's desktop source-api needs Java 21 (the bundled JRE is 21)
    if (ireader) try {
        IReaderJvm.start()
    } catch (e: Throwable) {
        System.err.println("IReader bridge failed: $e"); ireader = false
    }
    println("YOMIHUB_BRIDGE_READY kotatsu=${if (kotatsu) KotatsuJvm.PORT else 0} ireader=${if (ireader) IReaderJvm.PORT else 0}")
    System.out.flush()
    // stop with the app
    if (parent > 0) {
        Thread {
            while (true) {
                Thread.sleep(3000)
                val alive = ProcessHandle.of(parent).map { it.isAlive }.orElse(false)
                if (!alive) {
                    Store.flush()
                    Runtime.getRuntime().halt(0)
                }
            }
        }.apply { isDaemon = true }.start()
    }
    Runtime.getRuntime().addShutdownHook(Thread { Store.flush() })
    while (true) Thread.sleep(60_000)
}
