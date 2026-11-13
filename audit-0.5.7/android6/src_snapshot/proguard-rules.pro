# YomiHub: libraries whose native (JNI) code looks up Java classes, fields and
# methods by name. R8 must not rename or strip them.
-keep class org.torproject.jni.** { *; }
-keep class net.freehaven.tor.control.** { *; }
-keep class com.wireguard.** { *; }
-dontwarn org.torproject.**
-dontwarn net.freehaven.**
-dontwarn com.wireguard.**

# YomiHub 0.1.4: OpenVPN (ics-openvpn), libXray (gomobile), GeckoView
-keep class de.blinkt.openvpn.** { *; }
-dontwarn de.blinkt.openvpn.**
-keep class org.mozilla.geckoview.** { *; }
-dontwarn org.mozilla.**
# YomiHub 0.1.4: Kotatsu parsers (reflection for forks, enum lookups)
-keep class org.koitharu.kotatsu.parsers.** { *; }
-dontwarn org.koitharu.kotatsu.parsers.**
-keep class fi.iki.elonen.** { *; }
-dontwarn org.jsoup.**
-dontwarn okhttp3.**

# YomiHub 0.1.6: hev-socks5-tunnel registers natives on this class by name
-keep class com.kodjodevf.mangayomi.TProxyService { *; }

# YomiHub 0.1.9: IReader extension APKs (and Kotatsu fork jars) are loaded at
# run time and link against these libraries by name - R8 must keep them whole.
-keep class ireader.** { *; }
-keep class tachiyomix.** { *; }
-keep class io.ktor.** { *; }
-keep class com.fleeksoft.ksoup.** { *; }
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class co.touchlab.kermit.** { *; }
-keep class org.koin.** { *; }
-dontwarn ireader.**
-dontwarn io.ktor.**
-dontwarn com.fleeksoft.**
-dontwarn kotlinx.**
-dontwarn org.koin.**
-dontwarn co.touchlab.**
-dontwarn org.slf4j.**
-dontwarn java.lang.management.**

# YomiHub 0.2.1: runtime libraries for Mihon/Aniyomi extension APKs
-keep class app.cash.quickjs.** { *; }
-dontwarn app.cash.quickjs.**
-keep class nl.adaptivity.** { *; }
-dontwarn nl.adaptivity.**
