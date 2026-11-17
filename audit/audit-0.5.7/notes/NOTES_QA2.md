# NOTES QA2 - bo giai ma anh tren Android < 11 (15/11/2026)

## Duong di cua anh trang (MangaDex / CBZ / tep cuc bo)
Viewer (subsampling_scale_image_view.dart:963 `_initImage`, min_subsampling_image_view.dart:252 `_loadFromPath`)
-> `ffiImageDecoder.getImageDimensionsAsync` -> isolate C -> `init_decoder` (image_decoder.cpp, Android: AImageDecoder qua dlsym,
~594-640, chi co tu API 30; bo BMP 32-bit doc duoc moi nen tang) -> `decodeRegionAsync` (tile RGBA) -> `ui.decodeImageFromPixels`.
Loi "Khong tai duoc anh nay" = `outSize == null` (subsampling_scale_image_view.dart ~985) -> `failedToLoadImage`.

## Truoc khi sua (overlay 0.5.7 sau P7F, 14/11 ~16:03)
- API 30+: native OK, khong doi.
- API 24-29 (Note 9 Android 10) va API 23: AImageDecoder thieu -> `init_decoder` NULL -> dims null -> nhanh "legacy BMP"
  (Flutter codec -> BMP 32-bit trong cache -> native doc BMP) -> chay duoc NEU thu vien .so nap duoc. Ban APK dev 14:35 chua co nhanh nay.
- CON HONG: (a) thu vien .so khong nap/khong tim ham (dylib throw trong isolate) -> `_sendPort` null -> `_dimensionsJob` tra null
  -> khong co du phong; (b) chuyen BMP loi (anh qua lon, file la BMP...) -> het duong; (c) khong co log WARNING nao.

## Da sua (overlay/lib/modules/manga/reader/subsampling_scale_image_view/src/ffi_image_decoder.dart)
- Them nhanh cuoi cung "Flutter codec thuan Dart": `ui.instantiateImageCodec` -> RGBA giu trong bo nho (toi da 3 trang, <=80 Mpx),
  `_dartRegion` cat tile bang lay mau gan nhat (cung con tro calloc nhu native nen noi goi khong doi).
- Thu tu: native (API 30+) -> legacy BMP (Android, khi native tra null) -> Dart codec. Neu `.so` khong nap duoc / isolate khong chay
  (`nativeAvailable` == false) -> Dart ngay. API 30+ khong doi hieu nang (chi vao nhanh moi khi native that bai).
- Log: 1 dong WARNING moi phien `[Reader] Image decoder fallback: <ly do> ...` (AppLogger.logOnce-kieu, co co `_fallbackLogged`).
- Han che: che do Dart khong cat vien (cropBorders) va ton RAM hon (anh dai webtoon). Khong co chuoi tr() moi => khong can i18n.
- `nextDecodePath` la ham quyet dinh thuan (de test); luong that dung cung thu tu nhung viet truc tiep trong getImageDimensionsAsync.
- Sao luu: audit-0.5.7/backup/src_0571/.../ffi_image_decoder.dart.qa2 (ban truoc khi QA2 sua; goc 0.5.6.1 = ban `.dart`).

## Con lai / de nghi
- min_subsampling_image_view.dart `_loadFromPath`: dims null thi return im lang (khong bao loi) - neu ca Dart cung that bai se quay vong. Chua sua (ngoai pham vi hep).
- Can thu tren Note 9 bang APK moi (x4_build057 dang giu).
- Ket qua test/analyze: xem job qa2_dec1 (cap nhat ben duoi).
