# NOTES QA3 (Sonnet) - 3 sua loi tu QA APK phat hanh 0.5.7 (15/11/2026)

## 1. Reader treo spinner (anh MangaDex)
Nguyen nhan trong ma: CustomExtendedNetworkImageProvider._getResponse/_tryGetResponse khong co thoi gian cho; neu host khong tra loi thi Future treo mai. Nut Thu lai -> evict -> _loadFromProvider -> provider moi nhung _inFlightRequests[md5] tro lai dung Future dang treo => "thu lai khong lam gi". Loi bi nuot (return null) nen khong co dong log.
Sua:
- lib/utils/image_load_timeout.dart (moi): kImageLoadTimeout=30s, kImageLoadBackstop=45s, ImageLoadTimeoutException, withImageTimeout, classifyImageLoadError, describeImageLoadError (ly do tieng Viet, qua tr()), ImageFailWarnLog (moi host 1 dong WARNING / phut, dung LogBurstAggregator).
- custom_extended_image_provider.dart: han 30 s tong (deadline) cho ket noi+header (khong thu lai sau khi het han), 30 s giua cac chunk khi nhan than; timeout duoc nem len (giai phong in-flight), khong thu lan 2 sau timeout; log WARNING moi host/phut; nguyen nhan di vao thong bao loi.
- subsampling_scale_image_view.dart + min_subsampling_image_view.dart: backstop 45 s (khong bao gio quay vo han), luu ly do, SubsamplingImageState.errorMessage moi.
- reader_page_content.dart, double_page_view.dart, min_subsampling (UI loi): them dong ly do duoi "Khong tai duoc anh nay"; Thu lai goi lai reLoad (that su request lai vi in-flight da giai phong).
- ffi_image_decoder.dart khong dong den.
- i18n_QA3.json: 5 khoa x 18 ngon ngu da gop (merge_i18n.py: da them 90).
Test: test/yh_057_qa3_test.dart.

## 2. Nhan bi cat
- shiori_nav_bar.dart: Text trong FittedBox(scaleDown), softWrap false, padding ngang 10->6.
- play_books_screen.dart: nhan 'Yeu thich' + tooltip 'Danh sach yeu thich' (khoa da co san trong 18 ngon ngu, khong them moi).

## 3. Video Note 9
- logcat (job qa3_0571_b, evidence/phone/qa3/full_logcat.txt 67423 dong, filtered_logcat.txt): KHONG co dong mpv/media_kit/ffmpeg/MediaCodec nao cua app (ban release khong day log mpv ra logcat); khong co FATAL/exception. Thu muc /sdcard/Android/data/com.yomihub.app/files rong; nhat ky ung dung nam trong bo nho rieng (chi doc duoc qua man hinh Nhat ky: anh r13c chi thay canh bao kohiden.xyz CERTIFICATE_VERIFY_FAILED, phan video luc 08:11-08:14 nam ngoai khung anh).
- Cung luc: ping api.mangadex.org luc QA1 = unknown host, nhung luc 09:28 phan giai duoc (dxlb.mangadex.org 45.129.229.1, 60 ms) => DNS mang chap chon. Ngoai ra vDM he thong bao SocketTimeout toi dmc.nate.com (khong lien quan app).
- Ma: video mang mo o 0:00 (openStart=Duration.zero), seek resume (_yhResumeTo) chi chay SAU khi stream thuc su phat, khong chan open(); P3b khong the gay man den/spinner. hwdec mac dinh 'auto', vo gpu tren Android; khong co dau hieu loi khoi tao mpv (neu hong se co stream.error -> log ERROR + doi may chu).
- r09g_t22.png: man hinh DOC (portrait) den thuis + spinner mo, khong thanh dieu khien => chua toi giai doan khung hinh mpv; nhieu kha nang dang cho danh sach nguon/URL (cung mang chap chon) hoac mpv dang cho CDN.
- KET LUAN: khong chung minh duoc loi app; nghieng ve nguon/mang (DNS chap chon cung luc), khong sua ma. De xac minh: chay lai Flow 9 khi mang on dinh + bat "Bat nhat ky" de log; neu van den, lay `adb logcat` voi media_kit log level (can ban debug).
