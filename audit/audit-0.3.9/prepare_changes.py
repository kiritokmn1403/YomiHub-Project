from pathlib import Path
import json,re,shutil
ROOT=Path(__file__).resolve().parent
OVERLAY=ROOT.parent/'overlay'
path=OVERLAY/'lib/modules/more/data_and_storage/providers/delete_source.dart'
text=path.read_text(encoding='utf-8')
start=text.index('// Groups items into clusters')
end=text.index('class DuplicateMangaCluster',start)
path.write_text(text[:start]+text[end:],encoding='utf-8')

# Keep a complete reference catalogue without claiming all links are bundled code.
path=OVERLAY/'lib/yomihub/about/github_projects.dart'
text=path.read_text(encoding='utf-8')
rows=json.loads((ROOT/'github-reference-coverage.json').read_text(encoding='utf-8'))
missing=list(dict.fromkeys(r['url'] for r in rows if not r['listed_in_about']))
quote=lambda s: json.dumps(s,ensure_ascii=False).replace('$',r'\$')
items=[]
for url in missing:
 name=url.split('#')[0].split('?')[0].rstrip('/').split('/')[-1]
 items.append('    YomiGhProject('+quote(name)+', ['+quote(url)+']),')
group="  YomiGhGroup('Tài liệu và dự án tham khảo bổ sung', [\n"+'\n'.join(items)+'\n  ]),\n'
text=text.replace('];\n\nclass GithubProjectsScreen',group+'];\n\nclass GithubProjectsScreen')
text=text.replace('YomiHub được xây dựng dựa trên, hoặc tham khảo tính năng từ {p0} dự án mã nguồn mở dưới đây. Cảm ơn các tác giả!',
                  'Danh mục {p0} dự án và tài liệu tích hợp hoặc tham khảo. Các liên kết tham khảo không đồng nghĩa với tính năng đã được tích hợp.')
path.write_text(text,encoding='utf-8')

# Preserve URL query parameters and decode Drive's filename before asset selection.
path=OVERLAY/'lib/modules/more/about/providers/download_file_screen.dart'
text=path.read_text(encoding='utf-8')
text=text.replace('final lower = a.toLowerCase();','final lower = YomiDriveUpdate.fileName(a).toLowerCase();')
path.write_text(text,encoding='utf-8')

translations={
'en':'Unable to check for updates. Check your connection and try again.',
'fr':'Impossible de rechercher les mises à jour. Vérifiez votre connexion et réessayez.',
'de':'Updates konnten nicht geprüft werden. Prüfen Sie Ihre Verbindung und versuchen Sie es erneut.',
'es':'No se pudieron buscar actualizaciones. Comprueba tu conexión e inténtalo de nuevo.',
'es_419':'No se pudieron buscar actualizaciones. Revisa tu conexión e inténtalo de nuevo.',
'it':'Impossibile verificare gli aggiornamenti. Controlla la connessione e riprova.',
'pt':'Não foi possível procurar atualizações. Verifique a ligação e tente novamente.',
'pt_BR':'Não foi possível verificar atualizações. Verifique a conexão e tente novamente.',
'ja':'更新を確認できません。接続を確認して、もう一度お試しください。',
'ko':'업데이트를 확인할 수 없습니다. 연결을 확인하고 다시 시도하세요.',
'zh':'无法检查更新。请检查网络连接后重试。',
'ru':'Не удалось проверить обновления. Проверьте подключение и повторите попытку.',
'ar':'تعذر التحقق من التحديثات. تحقق من اتصالك وحاول مرة أخرى.',
'hi':'अपडेट की जाँच नहीं हो सकी। अपना कनेक्शन जाँचें और फिर से प्रयास करें।',
'as':'আপডেট পৰীক্ষা কৰিব পৰা নগ’ল। সংযোগ পৰীক্ষা কৰি পুনৰ চেষ্টা কৰক।',
'id':'Tidak dapat memeriksa pembaruan. Periksa koneksi Anda dan coba lagi.',
'th':'ไม่สามารถตรวจสอบการอัปเดตได้ โปรดตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง',
'tr':'Güncellemeler denetlenemedi. Bağlantınızı kontrol edip tekrar deneyin.',
}
for lang,value in translations.items():
 path=OVERLAY/f'assets/yomihub_i18n/{lang}.json'
 data=json.loads(path.read_text(encoding='utf-8-sig'))
 data['Không thể kiểm tra cập nhật. Vui lòng kiểm tra kết nối và thử lại.']=value
 path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Updated references:',len(missing),'and update-error translations:',len(translations))
