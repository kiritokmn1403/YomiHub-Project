package eu.kanade.tachiyomi

import android.app.Application
import eu.kanade.tachiyomi.network.NetworkHelper
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.Json
import kotlinx.serialization.protobuf.ProtoBuf
import nl.adaptivity.xmlutil.serialization.XML
import uy.kohesive.injekt.api.InjektModule
import uy.kohesive.injekt.api.InjektRegistrar
import uy.kohesive.injekt.api.addSingleton
import uy.kohesive.injekt.api.addSingletonFactory

class AppModule(
    val app: Application,
) : InjektModule {
    @OptIn(ExperimentalSerializationApi::class)
    override fun InjektRegistrar.registerInjectables() {
        addSingleton(app)

        addSingletonFactory { NetworkHelper(app) }

        addSingletonFactory {
            Json {
                ignoreUnknownKeys = true
                explicitNulls = false
                coerceInputValues = true
            }
        }

        // YomiHub 0.2.1: Mihon registers these too; extensions such as
        // MANGA Plus / Manga Million (Shueisha) get ProtoBuf through Injekt
        // ("No registered instance or factory for type ProtoBuf").
        addSingletonFactory<ProtoBuf> { ProtoBuf }

        addSingletonFactory<XML> {
            XML {
                defaultPolicy { ignoreUnknownChildren() }
                autoPolymorphic = true
            }
        }
    }
}
