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
