package com.kodjodevf.mangayomi

import android.app.Activity
import android.content.Context
import android.os.Build
import android.view.View
import android.widget.TextView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.mozilla.geckoview.ContentBlocking
import org.mozilla.geckoview.GeckoResult
import org.mozilla.geckoview.GeckoRuntime
import org.mozilla.geckoview.GeckoRuntimeSettings
import org.mozilla.geckoview.GeckoSession
import org.mozilla.geckoview.GeckoSessionSettings
import org.mozilla.geckoview.GeckoView
import org.mozilla.geckoview.WebExtension
import org.mozilla.geckoview.WebExtensionController

/**
 * YomiHub 0.1.4: Firefox (Gecko) engine for the in-app browser, next to the
 * system Chromium WebView. Each tab is a platform view `yomihub/gecko` with
 * its own method channel `yomihub/gecko_<id>`.
 *
 * Ad blocking in Gecko: Enhanced Tracking Protection (strict) plus the real
 * uBlock Origin add-on, installed from addons.mozilla.org on first use.
 */
object YomiGecko {
    const val MIN_SDK = 26
    private var runtime: GeckoRuntime? = null
    private var ublockTried = false

    val supported: Boolean get() = Build.VERSION.SDK_INT >= MIN_SDK

    fun runtime(ctx: Context): GeckoRuntime {
        runtime?.let { return it }
        val settings = GeckoRuntimeSettings.Builder()
            .contentBlocking(
                ContentBlocking.Settings.Builder()
                    .antiTracking(ContentBlocking.AntiTracking.STRICT)
                    .safeBrowsing(ContentBlocking.SafeBrowsing.DEFAULT)
                    .cookieBehavior(ContentBlocking.CookieBehavior.ACCEPT_NON_TRACKERS)
                    .enhancedTrackingProtectionLevel(ContentBlocking.EtpLevel.STRICT)
                    .build(),
            )
            .consoleOutput(false)
            .aboutConfigEnabled(true)
            .build()
        val r = GeckoRuntime.create(ctx.applicationContext, settings)
        runtime = r
        return r
    }

    /** Installs uBlock Origin into Gecko once (auto-accepting its prompt). */
    fun ensureUblock(ctx: Context) {
        if (ublockTried) return
        ublockTried = true
        val r = runtime(ctx)
        val ctl = r.webExtensionController
        ctl.promptDelegate = object : WebExtensionController.PromptDelegate {
            override fun onInstallPromptRequest(
                extension: WebExtension,
                permissions: Array<String>,
                origins: Array<String>,
                dataCollectionPermissions: Array<String>,
            ): GeckoResult<WebExtension.PermissionPromptResponse> =
                GeckoResult.fromValue(WebExtension.PermissionPromptResponse(true, false, false))
        }
        ctl.list().accept({ list ->
            val has = list?.any { it.id == "uBlock0@raymondhill.net" } == true
            if (!has) {
                ctl.install(
                    "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi",
                ).accept({ }, { })
            }
        }, { })
    }

    fun register(activity: Activity, engine: FlutterEngine) {
        engine.platformViewsController.registry.registerViewFactory(
            "yomihub/gecko",
            Factory(activity, engine.dartExecutor.binaryMessenger),
        )
        MethodChannel(engine.dartExecutor.binaryMessenger, "yomihub/gecko").setMethodCallHandler { call, result ->
            when (call.method) {
                "supported" -> result.success(supported)
                else -> result.notImplemented()
            }
        }
    }

    private class Factory(val activity: Activity, val messenger: BinaryMessenger) :
        PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
            @Suppress("UNCHECKED_CAST")
            val params = args as? Map<String, Any?> ?: emptyMap()
            return if (supported) GeckoTab(activity, messenger, viewId, params) else Unsupported(context)
        }
    }

    private class Unsupported(ctx: Context) : PlatformView {
        private val v = TextView(ctx).apply {
            text = "Nhân Firefox (Gecko) cần Android 8.0 trở lên."
            setPadding(48, 48, 48, 48)
        }

        override fun getView(): View = v
        override fun dispose() {}
    }

    private class GeckoTab(
        activity: Activity,
        messenger: BinaryMessenger,
        id: Int,
        params: Map<String, Any?>,
    ) : PlatformView {
        private val channel = MethodChannel(messenger, "yomihub/gecko_$id")
        private val view = GeckoView(activity)
        private val session: GeckoSession

        init {
            val desktop = params["desktop"] == true
            session = GeckoSession(
                GeckoSessionSettings.Builder()
                    .usePrivateMode(params["private"] == true)
                    .userAgentMode(
                        if (desktop) GeckoSessionSettings.USER_AGENT_MODE_DESKTOP else GeckoSessionSettings.USER_AGENT_MODE_MOBILE,
                    )
                    .viewportMode(
                        if (desktop) GeckoSessionSettings.VIEWPORT_MODE_DESKTOP else GeckoSessionSettings.VIEWPORT_MODE_MOBILE,
                    )
                    .build(),
            )
            session.navigationDelegate = object : GeckoSession.NavigationDelegate {
                override fun onLocationChange(
                    session: GeckoSession,
                    url: String?,
                    perms: MutableList<GeckoSession.PermissionDelegate.ContentPermission>,
                    hasUserGesture: Boolean,
                ) {
                    channel.invokeMethod("url", url ?: "")
                }

                override fun onCanGoBack(session: GeckoSession, canGoBack: Boolean) {
                    channel.invokeMethod("canBack", canGoBack)
                }

                override fun onCanGoForward(session: GeckoSession, canGoForward: Boolean) {
                    channel.invokeMethod("canForward", canGoForward)
                }

                override fun onNewSession(session: GeckoSession, uri: String): GeckoResult<GeckoSession>? {
                    // pop-ups become a new YomiHub tab (the Dart side applies ad blocking)
                    channel.invokeMethod("newWindow", uri)
                    return null
                }
            }
            session.progressDelegate = object : GeckoSession.ProgressDelegate {
                override fun onProgressChange(session: GeckoSession, progress: Int) {
                    channel.invokeMethod("progress", progress)
                }

                override fun onPageStop(session: GeckoSession, success: Boolean) {
                    channel.invokeMethod("pageStop", success)
                }
            }
            session.contentDelegate = object : GeckoSession.ContentDelegate {
                override fun onTitleChange(session: GeckoSession, title: String?) {
                    channel.invokeMethod("title", title ?: "")
                }
            }
            val rt = runtime(activity)
            if (params["adblock"] != false) ensureUblock(activity)
            session.open(rt)
            view.setSession(session)
            val url = params["url"] as? String
            if (!url.isNullOrEmpty()) session.loadUri(url)
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "load" -> {
                        session.loadUri(call.arguments as String); result.success(null)
                    }
                    "back" -> {
                        session.goBack(); result.success(null)
                    }
                    "forward" -> {
                        session.goForward(); result.success(null)
                    }
                    "reload" -> {
                        session.reload(); result.success(null)
                    }
                    "stop" -> {
                        session.stop(); result.success(null)
                    }
                    "clearHistory" -> {
                        session.purgeHistory(); result.success(null)
                    }
                    "desktop" -> {
                        val d = call.arguments == true
                        session.settings.userAgentMode =
                            if (d) GeckoSessionSettings.USER_AGENT_MODE_DESKTOP else GeckoSessionSettings.USER_AGENT_MODE_MOBILE
                        session.settings.viewportMode =
                            if (d) GeckoSessionSettings.VIEWPORT_MODE_DESKTOP else GeckoSessionSettings.VIEWPORT_MODE_MOBILE
                        session.reload()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        override fun getView(): View = view

        override fun dispose() {
            try {
                session.close()
            } catch (_: Throwable) {
            }
            channel.setMethodCallHandler(null)
        }
    }
}
