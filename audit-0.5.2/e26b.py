import sys; sys.path.insert(0,'.')
from edit import edit
V='lib/yomihub/vpn/vpn_service.dart'
edit(V,"""      final saved = int.tryParse('${_get('warpPort', '')}');
      final ports = <int?>[saved, if (saved != 2408) null, 500, 4500, 1701, 854]
          .where((p) => p != saved || p != null)
          .toList();
      var reached = !Platform.isAndroid;
      for (final port in Platform.isAndroid ? ports.toSet() : const <int?>{null}) {""","""      // null = the account's own endpoint port (2408); the port that worked
      // last time is tried first.
      final saved = int.tryParse('${_box?.get('warpPort', defaultValue: '') ?? ''}');
      final ports = <int?>{saved, null, 500, 4500, 1701, 854};
      var reached = !Platform.isAndroid;
      for (final port in Platform.isAndroid ? ports : const <int?>{null}) {""")
