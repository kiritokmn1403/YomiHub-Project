import sys; sys.path.insert(0,'audit-0.5.1'); from edit import edit
edit('lib/services/fetch_sources_list.dart', """        // offline / DNS: not an app error, once per repo is enough
        AppLogger.logOnce('repo-net:$url', 'fetchSourcesList: $url unreachable: ${YomiExtErrors.short(e)}');""", """        // offline / DNS: not an app error. 0.5.1: once per HOST and session
        // (logs 03/11 14:15: 45 lines in 13 s, one per repo, while the
        // device was offline – github.com, codeberg.org, api.github.com and
        // the jsDelivr mirrors all failed at the same time).
        final host = Uri.tryParse(url)?.host ?? url;
        AppLogger.logOnce('repo-net:$host', 'fetchSourcesList: $host unreachable (vd. $url): ${YomiExtErrors.short(e)} – sẽ thử lại khi có mạng');""")
