import sys; sys.path.insert(0,'.')
from edit import edit
edit('lib/services/fetch_sources_list.dart',"""      if (t.contains('host lookup') || t.contains('socketexception') ||
          t.contains('timeout') || t.contains('connection')) {""","""      // 0.5.2: a repo whose TLS handshake fails (kohiden.xyz, logs 06/11
      // 07:15-07:21: the same ERROR + stack 5 times) is a site problem too.
      if (t.contains('host lookup') || t.contains('socketexception') ||
          t.contains('timeout') || t.contains('connection') ||
          t.contains('handshake') || t.contains('certificate')) {""")
