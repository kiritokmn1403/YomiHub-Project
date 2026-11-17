package com.kodjodevf.mangayomi

import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

// YomiHub 0.5.6.1 A6 (chỉ build23): thay CompletableFuture (API 24) cho GoBackend của wireguard-android
// trên Android 6 (wg/RemapCompletableFuture.java). Chỉ có các hàm GoBackend dùng.
class YhA6Future<T> {
    private val latch = CountDownLatch(1)
    @Volatile private var value: T? = null

    fun complete(v: T): Boolean = synchronized(this) {
        if (latch.count == 0L) return false
        value = v
        latch.countDown()
        true
    }

    fun isDone(): Boolean = latch.count == 0L

    @Suppress("UNCHECKED_CAST")
    @Throws(InterruptedException::class, TimeoutException::class)
    fun get(timeout: Long, unit: TimeUnit): T {
        if (!latch.await(timeout, unit)) throw TimeoutException()
        return value as T
    }

    fun newIncompleteFuture(): YhA6Future<T> = YhA6Future()
}
