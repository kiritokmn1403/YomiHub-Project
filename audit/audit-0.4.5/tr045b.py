import json
from pathlib import Path
K=["Tor chưa kết nối được sau 90 giây (dừng ở {p0}%{p1}) – YomiHub đang thử cầu nối (Snowflake/obfs4/meek) ở nền và sẽ tự dùng Tor khi kết nối xong.",
"Tự động: kết nối thẳng, nếu bị chặn thì thử Snowflake → obfs4 → meek","đang dùng: {p0}"]
T={
'en':["Tor did not connect within 90 seconds (stopped at {p0}%{p1}) – YomiHub is trying bridges (Snowflake/obfs4/meek) in the background and will use Tor as soon as it connects.","Automatic: connect directly; if blocked, try Snowflake → obfs4 → meek","in use: {p0}"],
'de':["Tor hat sich nicht innerhalb von 90 Sekunden verbunden (gestoppt bei {p0}%{p1}) – YomiHub versucht im Hintergrund Brücken (Snowflake/obfs4/meek) und nutzt Tor, sobald es verbunden ist.","Automatisch: direkt verbinden; bei Sperre Snowflake → obfs4 → meek versuchen","aktiv: {p0}"],
'fr':["Tor ne s'est pas connecté en 90 secondes (arrêté à {p0}%{p1}) – YomiHub essaie des ponts (Snowflake/obfs4/meek) en arrière-plan et utilisera Tor dès la connexion.","Automatique : connexion directe ; si bloquée, essayer Snowflake → obfs4 → meek","utilisé : {p0}"],
'es':["Tor no se conectó en 90 segundos (se detuvo en {p0}%{p1}) – YomiHub está probando puentes (Snowflake/obfs4/meek) en segundo plano y usará Tor en cuanto conecte.","Automático: conectar directamente; si está bloqueado, probar Snowflake → obfs4 → meek","en uso: {p0}"],
'it':["Tor non si è connesso entro 90 secondi (fermo a {p0}%{p1}) – YomiHub sta provando i bridge (Snowflake/obfs4/meek) in background e userà Tor appena connesso.","Automatico: connessione diretta; se bloccata, prova Snowflake → obfs4 → meek","in uso: {p0}"],
'pt':["O Tor não ligou em 90 segundos (parou em {p0}%{p1}) – o YomiHub está a tentar pontes (Snowflake/obfs4/meek) em segundo plano e usará o Tor assim que ligar.","Automático: ligar diretamente; se bloqueado, tentar Snowflake → obfs4 → meek","em uso: {p0}"],
'pt_BR':["O Tor não conectou em 90 segundos (parou em {p0}%{p1}) – o YomiHub está tentando pontes (Snowflake/obfs4/meek) em segundo plano e usará o Tor assim que conectar.","Automático: conectar direto; se bloqueado, tentar Snowflake → obfs4 → meek","em uso: {p0}"],
'ru':["Tor не подключился за 90 секунд (остановился на {p0}%{p1}) – YomiHub пробует мосты (Snowflake/obfs4/meek) в фоне и включит Tor, как только он подключится.","Автоматически: прямое подключение; при блокировке – Snowflake → obfs4 → meek","используется: {p0}"],
'tr':["Tor 90 saniyede bağlanamadı ({p0}%{p1} noktasında durdu) – YomiHub arka planda köprüleri (Snowflake/obfs4/meek) deniyor ve bağlanınca Tor'u kullanacak.","Otomatik: doğrudan bağlan; engellenirse Snowflake → obfs4 → meek dene","kullanılan: {p0}"],
'id':["Tor tidak terhubung dalam 90 detik (berhenti di {p0}%{p1}) – YomiHub sedang mencoba bridge (Snowflake/obfs4/meek) di latar belakang dan akan memakai Tor begitu terhubung.","Otomatis: sambung langsung; jika diblokir, coba Snowflake → obfs4 → meek","dipakai: {p0}"],
'ja':["Tor が 90 秒以内に接続できませんでした（{p0}%{p1} で停止）– YomiHub はバックグラウンドでブリッジ（Snowflake/obfs4/meek）を試し、接続でき次第 Tor を使います。","自動：直接接続し、ブロックされたら Snowflake → obfs4 → meek を試す","使用中: {p0}"],
'ko':["Tor가 90초 안에 연결되지 않았습니다({p0}%{p1}에서 멈춤) – YomiHub가 백그라운드에서 브리지(Snowflake/obfs4/meek)를 시도하며 연결되면 바로 Tor를 사용합니다.","자동: 직접 연결, 차단되면 Snowflake → obfs4 → meek 시도","사용 중: {p0}"],
'zh':["Tor 在 90 秒内未能连接（停在 {p0}%{p1}）– YomiHub 正在后台尝试网桥（Snowflake/obfs4/meek），连接成功后会自动使用 Tor。","自动：直接连接；若被封锁则依次尝试 Snowflake → obfs4 → meek","正在使用：{p0}"],
'th':["Tor เชื่อมต่อไม่ได้ภายใน 90 วินาที (หยุดที่ {p0}%{p1}) – YomiHub กำลังลองบริดจ์ (Snowflake/obfs4/meek) อยู่เบื้องหลัง และจะใช้ Tor ทันทีที่เชื่อมต่อได้","อัตโนมัติ: เชื่อมต่อโดยตรง หากถูกบล็อกจะลอง Snowflake → obfs4 → meek","กำลังใช้: {p0}"],
'ar':["لم يتصل Tor خلال 90 ثانية (توقف عند {p0}%{p1}) – يجرّب YomiHub الجسور (Snowflake/obfs4/meek) في الخلفية وسيستخدم Tor فور الاتصال.","تلقائي: اتصال مباشر، وإن حُظر فجرّب Snowflake → obfs4 → meek","قيد الاستخدام: {p0}"],
'hi':["Tor 90 सेकंड में कनेक्ट नहीं हुआ ({p0}%{p1} पर रुका) – YomiHub पृष्ठभूमि में ब्रिज (Snowflake/obfs4/meek) आज़मा रहा है और कनेक्ट होते ही Tor का उपयोग करेगा।","स्वचालित: सीधे कनेक्ट करें; ब्लॉक होने पर Snowflake → obfs4 → meek आज़माएँ","उपयोग में: {p0}"],
'as':["৯০ ছেকেণ্ডত Tor সংযোগ নহ'ল ({p0}%{p1} ত ৰ'ল) – YomiHub এ পটভূমিত ব্ৰিজ (Snowflake/obfs4/meek) চেষ্টা কৰি আছে আৰু সংযোগ হোৱাৰ লগে লগে Tor ব্যৱহাৰ কৰিব।","স্বয়ংক্ৰিয়: পোনপটীয়াকৈ সংযোগ; অৱৰোধ হ'লে Snowflake → obfs4 → meek চেষ্টা","ব্যৱহাৰত: {p0}"],
}
T['es_419']=T['es']
root=Path(__file__).resolve().parent.parent/'overlay/assets/yomihub_i18n'
for f in root.glob('*.json'):
    d=json.loads(f.read_text(encoding='utf-8'))
    for k,v in zip(K,T[f.stem]): d[k]=v
    f.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('ok')
