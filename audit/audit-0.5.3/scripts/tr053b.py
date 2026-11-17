import json, os
ROOT = os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project/overlay')
L = ['en','ar','as','de','es','es_419','fr','hi','id','it','ja','ko','pt','pt_BR','ru','th','tr','zh']
T = {
'Thư mục này không còn tồn tại – bản tự sao lưu được lưu vào thư mục mặc định. Chọn lại vị trí sao lưu.': [
 'This folder no longer exists – automatic backups go to the default folder. Choose the backup location again.',
 'لم يعد هذا المجلد موجودًا – تُحفظ النسخ الاحتياطية التلقائية في المجلد الافتراضي. اختر موقع النسخ الاحتياطي مرة أخرى.',
 'এই ফোল্ডাৰটো আৰু নাই – স্বয়ংক্ৰিয় বেকআপ ডিফল্ট ফোল্ডাৰত সংৰক্ষিত হয়। বেকআপৰ স্থান পুনৰ বাছক।',
 'Dieser Ordner existiert nicht mehr – automatische Sicherungen landen im Standardordner. Wähle den Sicherungsort neu.',
 'Esta carpeta ya no existe: las copias automáticas se guardan en la carpeta predeterminada. Vuelve a elegir la ubicación.',
 'Esta carpeta ya no existe: los respaldos automáticos se guardan en la carpeta predeterminada. Vuelve a elegir la ubicación.',
 "Ce dossier n'existe plus – les sauvegardes automatiques vont dans le dossier par défaut. Choisissez à nouveau l'emplacement.",
 'यह फ़ोल्डर अब मौजूद नहीं है – स्वचालित बैकअप डिफ़ॉल्ट फ़ोल्डर में सहेजे जाते हैं। बैकअप स्थान फिर से चुनें।',
 'Folder ini sudah tidak ada – cadangan otomatis disimpan di folder bawaan. Pilih lagi lokasi cadangan.',
 'Questa cartella non esiste più – i backup automatici vanno nella cartella predefinita. Scegli di nuovo la posizione.',
 'このフォルダーはもう存在しません。自動バックアップは既定のフォルダーに保存されます。保存先を選び直してください。',
 '이 폴더가 더 이상 없습니다. 자동 백업은 기본 폴더에 저장됩니다. 백업 위치를 다시 선택하세요.',
 'Esta pasta já não existe – as cópias automáticas vão para a pasta predefinida. Escolha de novo a localização.',
 'Esta pasta não existe mais – os backups automáticos vão para a pasta padrão. Escolha o local de backup novamente.',
 'Эта папка больше не существует – автокопии сохраняются в папку по умолчанию. Выберите место заново.',
 'โฟลเดอร์นี้ไม่มีอยู่แล้ว – ข้อมูลสำรองอัตโนมัติจะบันทึกในโฟลเดอร์เริ่มต้น เลือกตำแหน่งสำรองข้อมูลใหม่',
 'Bu klasör artık yok – otomatik yedekler varsayılan klasöre kaydedilir. Yedekleme konumunu yeniden seçin.',
 '此文件夹已不存在 —— 自动备份将保存到默认文件夹。请重新选择备份位置。'],
'Không có mục nào đang theo dõi trên MyAnimeList hoặc AniList để xuất': [
 'Nothing tracked on MyAnimeList or AniList to export',
 'لا توجد عناوين متابَعة على MyAnimeList أو AniList لتصديرها',
 'ৰপ্তানি কৰিবলৈ MyAnimeList বা AniList-ত কোনো ট্ৰেক কৰা শিৰোনাম নাই',
 'Keine auf MyAnimeList oder AniList verfolgten Titel zum Exportieren',
 'No hay títulos seguidos en MyAnimeList ni AniList para exportar',
 'No hay títulos seguidos en MyAnimeList ni AniList para exportar',
 "Aucun titre suivi sur MyAnimeList ou AniList à exporter",
 'निर्यात करने के लिए MyAnimeList या AniList पर कोई ट्रैक किया गया शीर्षक नहीं है',
 'Tidak ada judul yang dilacak di MyAnimeList atau AniList untuk diekspor',
 'Nessun titolo seguito su MyAnimeList o AniList da esportare',
 '書き出せる MyAnimeList / AniList の記録がありません',
 '내보낼 MyAnimeList 또는 AniList 추적 항목이 없습니다',
 'Não há títulos acompanhados no MyAnimeList ou AniList para exportar',
 'Não há títulos acompanhados no MyAnimeList ou AniList para exportar',
 'Нет тайтлов из MyAnimeList или AniList для экспорта',
 'ไม่มีรายการที่ติดตามบน MyAnimeList หรือ AniList ให้ส่งออก',
 "Dışa aktarılacak MyAnimeList veya AniList kaydı yok",
 '没有可导出的 MyAnimeList 或 AniList 追踪条目'],
}
d = os.path.join(ROOT, 'assets/yomihub_i18n')
files = sorted(f for f in os.listdir(d) if f.endswith('.json'))
assert set(f[:-5] for f in files) == set(L)
for k, v in T.items():
    assert len(v) == 18, (k, len(v))
for f in files:
    p = os.path.join(d, f)
    j = json.load(open(p, encoding='utf-8'))
    for k, v in T.items():
        j[k] = v[L.index(f[:-5])]
    json.dump(j, open(p, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    open(p, 'a', encoding='utf-8').write('\n')
print('ok', len(files), len(T))
