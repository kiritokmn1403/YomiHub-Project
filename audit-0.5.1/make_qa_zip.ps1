# Builds output\YomiHub-0.5.1-QA-screenshots.zip from a reviewed list only:
# no 18+ titles/covers, no personal library/folder contents, no log lines with
# personal file names or 18+ URLs (see TECHNICAL_UPDATE_NOTES 0.5.1 H/I).
$K = "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project"
$qa = "$K\audit-0.5.1\qa"; $stage = "D:\yh\qa051_zip"
$list = @(
 '01_splash_a.png','01_splash_b.png','02_man_hinh_chinh.png',
 '04_cai_dat_tai_xuong.png','05_ds_thu_muc_cuc_bo.png','26_dang_quet.png','27_quet_xong_thu_muc.png',
 '12_gioi_thieu_051.png','32_motphim_ket_qua.png','v03_vbook_ma_hoa.mp4',
 '17_hotphim.png','18_hotphim_chi_tiet.png',
 '37_cai_dat_duyet.png','38_kiem_tra_apk.png','39_kiem_tra_apk_ket_qua.png','40_kiem_tra_apk_manifest.png',
 'tv02_man_hinh_chinh.png','tv03_duyet.png','tv04_hotphim.png','tv05_chi_tiet.png','tv07_phat_35s.png','tv08_dieu_khien.png','tv10_chi_tiet.png','tv_v02_hotphim.mp4',
 'tv14_khong_hoi_quyen.png','tv15a_dang_phat.png','tv15b_vi_tri_truoc_thoat.png','tv16_lich_su.png',
 'win01_setup_051.jpg','win03_them_goi_y_hop_nhat.jpg','win04_gioi_thieu_051.jpg','win06_du_an_github_vbook.jpg','win07_kiem_tra_apk.jpg','win08_cai_dat_duyet.jpg'
)
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force "$stage\Android","$stage\AndroidTV","$stage\Windows" | Out-Null
$n = 0
foreach ($f in $list) {
  $src = "$qa\$f"; if (-not (Test-Path $src)) { "missing: $f"; continue }
  $sub = if ($f -like 'tv*') { 'AndroidTV' } elseif ($f -like 'win*') { 'Windows' } else { 'Android' }
  Copy-Item $src "$stage\$sub\$f"; $n++
}
$zip = "$K\output\YomiHub-0.5.1-QA-screenshots.zip"
Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive -Path "$stage\*" -DestinationPath $zip -CompressionLevel Optimal
"QA zip: $n files, {0:N1} MB" -f ((Get-Item $zip).Length/1MB)
