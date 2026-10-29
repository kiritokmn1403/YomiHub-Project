/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.mozilla.gecko.process;

import androidx.annotation.Keep;

// R8 fullMode can over-optimize this. Annotate with @Keep to avoid crashes.
@Keep
public class GeckoChildProcessServices {
    /* package */ static final int MAX_NUM_ISOLATED_CONTENT_SERVICES = 40;
    public static final class gmplugin extends GeckoServiceChildProcess {}
    public static final class socket extends GeckoServiceChildProcess {}
    public static final class gpu extends GeckoServiceGpuProcess {}
    public static final class rdd extends GeckoServiceChildProcess {}
    public static final class utility extends GeckoServiceChildProcess {}
    public static final class ipdlunittest extends GeckoServiceChildProcess {}


    public static final class tab0 extends GeckoServiceChildProcess {}
    public static final class isolatedTab0 extends GeckoServiceChildProcess {}

    public static final class tab1 extends GeckoServiceChildProcess {}
    public static final class isolatedTab1 extends GeckoServiceChildProcess {}

    public static final class tab2 extends GeckoServiceChildProcess {}
    public static final class isolatedTab2 extends GeckoServiceChildProcess {}

    public static final class tab3 extends GeckoServiceChildProcess {}
    public static final class isolatedTab3 extends GeckoServiceChildProcess {}

    public static final class tab4 extends GeckoServiceChildProcess {}
    public static final class isolatedTab4 extends GeckoServiceChildProcess {}

    public static final class tab5 extends GeckoServiceChildProcess {}
    public static final class isolatedTab5 extends GeckoServiceChildProcess {}

    public static final class tab6 extends GeckoServiceChildProcess {}
    public static final class isolatedTab6 extends GeckoServiceChildProcess {}

    public static final class tab7 extends GeckoServiceChildProcess {}
    public static final class isolatedTab7 extends GeckoServiceChildProcess {}

    public static final class tab8 extends GeckoServiceChildProcess {}
    public static final class isolatedTab8 extends GeckoServiceChildProcess {}

    public static final class tab9 extends GeckoServiceChildProcess {}
    public static final class isolatedTab9 extends GeckoServiceChildProcess {}

    public static final class tab10 extends GeckoServiceChildProcess {}
    public static final class isolatedTab10 extends GeckoServiceChildProcess {}

    public static final class tab11 extends GeckoServiceChildProcess {}
    public static final class isolatedTab11 extends GeckoServiceChildProcess {}

    public static final class tab12 extends GeckoServiceChildProcess {}
    public static final class isolatedTab12 extends GeckoServiceChildProcess {}

    public static final class tab13 extends GeckoServiceChildProcess {}
    public static final class isolatedTab13 extends GeckoServiceChildProcess {}

    public static final class tab14 extends GeckoServiceChildProcess {}
    public static final class isolatedTab14 extends GeckoServiceChildProcess {}

    public static final class tab15 extends GeckoServiceChildProcess {}
    public static final class isolatedTab15 extends GeckoServiceChildProcess {}

    public static final class tab16 extends GeckoServiceChildProcess {}
    public static final class isolatedTab16 extends GeckoServiceChildProcess {}

    public static final class tab17 extends GeckoServiceChildProcess {}
    public static final class isolatedTab17 extends GeckoServiceChildProcess {}

    public static final class tab18 extends GeckoServiceChildProcess {}
    public static final class isolatedTab18 extends GeckoServiceChildProcess {}

    public static final class tab19 extends GeckoServiceChildProcess {}
    public static final class isolatedTab19 extends GeckoServiceChildProcess {}

    public static final class tab20 extends GeckoServiceChildProcess {}
    public static final class isolatedTab20 extends GeckoServiceChildProcess {}

    public static final class tab21 extends GeckoServiceChildProcess {}
    public static final class isolatedTab21 extends GeckoServiceChildProcess {}

    public static final class tab22 extends GeckoServiceChildProcess {}
    public static final class isolatedTab22 extends GeckoServiceChildProcess {}

    public static final class tab23 extends GeckoServiceChildProcess {}
    public static final class isolatedTab23 extends GeckoServiceChildProcess {}

    public static final class tab24 extends GeckoServiceChildProcess {}
    public static final class isolatedTab24 extends GeckoServiceChildProcess {}

    public static final class tab25 extends GeckoServiceChildProcess {}
    public static final class isolatedTab25 extends GeckoServiceChildProcess {}

    public static final class tab26 extends GeckoServiceChildProcess {}
    public static final class isolatedTab26 extends GeckoServiceChildProcess {}

    public static final class tab27 extends GeckoServiceChildProcess {}
    public static final class isolatedTab27 extends GeckoServiceChildProcess {}

    public static final class tab28 extends GeckoServiceChildProcess {}
    public static final class isolatedTab28 extends GeckoServiceChildProcess {}

    public static final class tab29 extends GeckoServiceChildProcess {}
    public static final class isolatedTab29 extends GeckoServiceChildProcess {}

    public static final class tab30 extends GeckoServiceChildProcess {}
    public static final class isolatedTab30 extends GeckoServiceChildProcess {}

    public static final class tab31 extends GeckoServiceChildProcess {}
    public static final class isolatedTab31 extends GeckoServiceChildProcess {}

    public static final class tab32 extends GeckoServiceChildProcess {}
    public static final class isolatedTab32 extends GeckoServiceChildProcess {}

    public static final class tab33 extends GeckoServiceChildProcess {}
    public static final class isolatedTab33 extends GeckoServiceChildProcess {}

    public static final class tab34 extends GeckoServiceChildProcess {}
    public static final class isolatedTab34 extends GeckoServiceChildProcess {}

    public static final class tab35 extends GeckoServiceChildProcess {}
    public static final class isolatedTab35 extends GeckoServiceChildProcess {}

    public static final class tab36 extends GeckoServiceChildProcess {}
    public static final class isolatedTab36 extends GeckoServiceChildProcess {}

    public static final class tab37 extends GeckoServiceChildProcess {}
    public static final class isolatedTab37 extends GeckoServiceChildProcess {}

    public static final class tab38 extends GeckoServiceChildProcess {}
    public static final class isolatedTab38 extends GeckoServiceChildProcess {}

    public static final class tab39 extends GeckoServiceChildProcess {}
    public static final class isolatedTab39 extends GeckoServiceChildProcess {}

    public static final class zygoteTab extends GeckoServiceChildProcess {}
}