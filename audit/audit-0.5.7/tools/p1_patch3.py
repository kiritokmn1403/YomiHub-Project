from ed import *
rel = 'lib/modules/manga/detail/manga_details_view.dart'
s = read(rel)
assert 'manga_extensions.dart' not in s and 'chapter_origins.dart' not in s
sub(rel, """import 'package:mangayomi/utils/extensions/chapter_extensions.dart';
""", """import 'package:mangayomi/utils/extensions/chapter_extensions.dart';
import 'package:mangayomi/utils/extensions/manga_extensions.dart';
import 'package:mangayomi/yomihub/merge/chapter_origins.dart';
""")
sub(rel, """                      onPressed: () {
                        widget.manga.chapters.toList().first.pushToReaderView(
                          context,
                        );
                      },
""", """                      onPressed: () {
                        final all = widget.manga.chapters.toList();
                        // 0.5.7 (Feature Check 37): a merged title with a
                        // remembered read source starts with that source's
                        // copy of the first chapter
                        final first =
                            ChapterOrigins.preferredSource(widget.manga.id) == null
                            ? all.first
                            : (widget.manga.getChapterListForReading().firstOrNull ?? all.first);
                        first.pushToReaderView(context);
                      },
""")
print('ok')
