import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mangayomi/yomihub/ebook/ebook_converter.dart';

import 'package:file_picker/file_picker.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/modules/manga/archive_reader/models/models.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/modules/manga/archive_reader/providers/archive_reader_providers.dart';
import 'package:mangayomi/src/rust/api/epub.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'local_archive.g.dart';

@riverpod
Future importArchivesFromFile(
  Ref ref,
  Manga? mManga, {
  required ItemType itemType,
  required bool init,
  bool splitChapters = true,
}) async {
  final keepAlile = ref.keepAlive();
  try {
    // YomiHub: Android pickers grey out unknown types such as .azw3, so
    // novels use the "any file" picker and are filtered here instead.
    List<PlatformFile> files = await FilePicker.pickFiles(
      type: itemType == ItemType.novel ? FileType.any : FileType.custom,
      allowedExtensions: switch (itemType) {
        ItemType.manga => ['cbz', 'zip'],
        ItemType.anime => ['mp4', 'mov', 'avi', 'flv', 'wmv', 'mpeg', 'mkv'],
        ItemType.novel => null,
      },
      linuxOptions: const LinuxOptions(lockParentWindow: true),
    );
    if (itemType == ItemType.novel) {
      files = files
          .where((f) {
            final path = f.path?.toLowerCase() ?? '';
            return YomiEbook.isSupported(path);
          })
          .toList();
    }
    if (files.isNotEmpty) {
      final dateNow = DateTime.now().millisecondsSinceEpoch;
      final manga =
          mManga ??
          Manga(
            favorite: true,
            source: 'archive',
            author: '',
            itemType: itemType,
            genre: [],
            imageUrl: '',
            lang: '',
            link: '',
            name: _getName(files.first.path!),
            dateAdded: dateNow,
            lastUpdate: dateNow,
            status: Status.unknown,
            description: '',
            isLocalArchive: true,
            artist: '',
            updatedAt: dateNow,
            sourceId: null,
          );

      for (var file in files.reversed) {
        (String, LocalExtensionType, Uint8List, String)? data =
            itemType == ItemType.manga
            ? await ref.watch(
                getArchivesDataFromFileProvider(file.path!).future,
              )
            : null;
        String name = _getName(file.path!);

        if (init) {
          if (itemType == ItemType.manga) {
            manga.customCoverImage = data!.$3.getCoverImage;
          }
        }
        await mangaRepository.writeTransactionAsync(() async {
          final mangaId = await mangaRepository.putAsync(manga);
          final List<Chapter> chapters = [];
          if (itemType == ItemType.novel) {
            // YomiHub: Kindle books are converted to EPUB once, kept in the
            // app's documents folder, and read from there.
            var epubPath = file.path!;
            if (YomiEbook.isConvertible(epubPath)) {
              final docs = await getApplicationDocumentsDirectory();
              epubPath = await YomiEbook.convertFile(
                epubPath,
                Directory(p.join(docs.path, 'yomihub_converted')),
              );
            }
            final book = await parseEpubFromPath(
              epubPath: epubPath,
              fullData: splitChapters,
            );

            if (book.cover != null) {
              await mangaRepository.putAsync(
                manga..customCoverImage = book.cover!.getCoverImage,
              );
            }
            final chaps = book.chapters;

            if (splitChapters && chaps.isNotEmpty) {
              for (int i = 0; i < chaps.length; i++) {
                final epubChapter = chaps[i];
                chapters.add(
                  Chapter(
                    mangaId: mangaId,
                    name: epubChapter.name,
                    archivePath: epubPath,
                    url: epubChapter.path,
                    updatedAt: DateTime.now().millisecondsSinceEpoch,
                  )..manga.value = manga,
                );
              }
            } else {
              // Fallback: single chapter if no spine chapters found
              chapters.add(
                Chapter(
                  mangaId: mangaId,
                  name: book.name,
                  archivePath: epubPath,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                )..manga.value = manga,
              );
            }
          } else {
            chapters.add(
              Chapter(
                name: itemType == ItemType.manga ? data!.$1 : name,
                archivePath: itemType == ItemType.manga ? data!.$4 : file.path,
                mangaId: manga.id,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              )..manga.value = manga,
            );
          }
          for (final chapter in chapters) {
            await chapterRepository.putAsync(chapter);
            await chapter.manga.save();
          }
        });
      }
    }
    keepAlile.close();
    return "";
  } catch (e) {
    keepAlile.close();
    rethrow;
  }
}

String _getName(String path) {
  return path
      .split('/')
      .last
      .split("\\")
      .last
      .replaceAll(
        RegExp(r'\.(mp4|mov|avi|flv|wmv|mpeg|mkv|cbz|zip|cbt|tar|epub)'),
        '',
      );
}

extension Uint8ListExtensions on Uint8List {
  Uint8List? get getCoverImage {
    final length = lengthInBytes / (1024 * 1024);
    if (length < 5) {
      return this;
    }
    botToast(
      "Cover image is larger than 5MB (${length.toStringAsFixed(2)}MB). Skipping cover image.",
    );
    return null;
  }
}
