import json, os
ROOT = os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project/overlay')
K = 'WARP đã bật nhưng không bắt tay được với máy chủ Cloudflare – mạng hiện tại có thể chặn UDP (cổng 2408, 500, 4500, 1701, 854). Hãy thử mạng khác, hoặc dùng Tor / WireGuard.'
T = {
 'en': 'WARP was turned on but could not complete a handshake with the Cloudflare server – this network may block UDP (ports 2408, 500, 4500, 1701, 854). Try another network, or use Tor / WireGuard.',
 'ar': 'تم تشغيل WARP لكن تعذّر إتمام المصافحة مع خادم Cloudflare – قد تحظر هذه الشبكة UDP (المنافذ 2408 و500 و4500 و1701 و854). جرّب شبكة أخرى أو استخدم Tor / WireGuard.',
 'as': 'WARP অন কৰা হ\'ল কিন্তু Cloudflare চাৰ্ভাৰৰ সৈতে হেণ্ডশ্বেক সম্পূৰ্ণ নহ\'ল – এই নেটৱৰ্কে UDP (প\'ৰ্ট 2408, 500, 4500, 1701, 854) বন্ধ কৰিব পাৰে। আন নেটৱৰ্ক চেষ্টা কৰক, বা Tor / WireGuard ব্যৱহাৰ কৰক।',
 'de': 'WARP wurde eingeschaltet, aber der Handshake mit dem Cloudflare-Server kam nicht zustande – dieses Netzwerk blockiert möglicherweise UDP (Ports 2408, 500, 4500, 1701, 854). Versuche ein anderes Netzwerk oder nutze Tor / WireGuard.',
 'es': 'WARP se activó pero no pudo completar el handshake con el servidor de Cloudflare: esta red puede bloquear UDP (puertos 2408, 500, 4500, 1701, 854). Prueba otra red o usa Tor / WireGuard.',
 'es_419': 'WARP se activó pero no pudo completar el handshake con el servidor de Cloudflare: esta red puede bloquear UDP (puertos 2408, 500, 4500, 1701, 854). Prueba otra red o usa Tor / WireGuard.',
 'fr': 'WARP a été activé mais la poignée de main avec le serveur Cloudflare a échoué – ce réseau bloque peut-être l\'UDP (ports 2408, 500, 4500, 1701, 854). Essayez un autre réseau ou utilisez Tor / WireGuard.',
 'hi': 'WARP चालू हुआ लेकिन Cloudflare सर्वर के साथ हैंडशेक पूरा नहीं हो सका – यह नेटवर्क UDP (पोर्ट 2408, 500, 4500, 1701, 854) ब्लॉक कर सकता है। कोई दूसरा नेटवर्क आज़माएँ, या Tor / WireGuard का उपयोग करें।',
 'id': 'WARP sudah dinyalakan tetapi handshake dengan server Cloudflare gagal – jaringan ini mungkin memblokir UDP (port 2408, 500, 4500, 1701, 854). Coba jaringan lain, atau gunakan Tor / WireGuard.',
 'it': 'WARP è stato attivato ma l\'handshake con il server Cloudflare non è riuscito – questa rete potrebbe bloccare l\'UDP (porte 2408, 500, 4500, 1701, 854). Prova un\'altra rete oppure usa Tor / WireGuard.',
 'ja': 'WARP をオンにしましたが、Cloudflare サーバーとのハンドシェイクが完了しませんでした。このネットワークは UDP(ポート 2408、500、4500、1701、854)をブロックしている可能性があります。別のネットワークを試すか、Tor / WireGuard を使用してください。',
 'ko': 'WARP를 켰지만 Cloudflare 서버와 핸드셰이크를 완료하지 못했습니다. 이 네트워크에서 UDP(포트 2408, 500, 4500, 1701, 854)를 차단하고 있을 수 있습니다. 다른 네트워크를 사용하거나 Tor / WireGuard를 사용하세요.',
 'pt': 'O WARP foi ativado mas não foi possível concluir o handshake com o servidor da Cloudflare – esta rede pode bloquear UDP (portas 2408, 500, 4500, 1701, 854). Experimente outra rede ou use Tor / WireGuard.',
 'pt_BR': 'O WARP foi ativado, mas não conseguiu concluir o handshake com o servidor da Cloudflare – esta rede pode bloquear UDP (portas 2408, 500, 4500, 1701, 854). Tente outra rede ou use Tor / WireGuard.',
 'ru': 'WARP включён, но установить соединение (handshake) с сервером Cloudflare не удалось – эта сеть, возможно, блокирует UDP (порты 2408, 500, 4500, 1701, 854). Попробуйте другую сеть или используйте Tor / WireGuard.',
 'th': 'เปิด WARP แล้วแต่ไม่สามารถแฮนด์เชกกับเซิร์ฟเวอร์ Cloudflare ได้ – เครือข่ายนี้อาจบล็อก UDP (พอร์ต 2408, 500, 4500, 1701, 854) ลองใช้เครือข่ายอื่น หรือใช้ Tor / WireGuard',
 'tr': 'WARP açıldı ancak Cloudflare sunucusuyla el sıkışma tamamlanamadı – bu ağ UDP\'yi engelliyor olabilir (2408, 500, 4500, 1701, 854 numaralı portlar). Başka bir ağ deneyin veya Tor / WireGuard kullanın.',
 'zh': 'WARP 已开启,但未能与 Cloudflare 服务器完成握手 —— 当前网络可能屏蔽了 UDP(端口 2408、500、4500、1701、854)。请尝试其他网络,或使用 Tor / WireGuard。',
}
d = os.path.join(ROOT, 'assets/yomihub_i18n')
files = sorted(f for f in os.listdir(d) if f.endswith('.json'))
assert len(files) == 18 and set(f[:-5] for f in files) == set(T), set(f[:-5] for f in files) ^ set(T)
for f in files:
    p = os.path.join(d, f)
    j = json.load(open(p, encoding='utf-8'))
    j[K] = T[f[:-5]]
    json.dump(j, open(p, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    open(p, 'a', encoding='utf-8').write('\n')
sp = os.path.join(ROOT, 'test/yh_052_strings.txt')
s = open(sp, encoding='utf-8').read()
if K not in s:
    open(sp, 'a', encoding='utf-8').write(('' if s.endswith('\n') else '\n') + K + '\n')
print('ok', len(files))
