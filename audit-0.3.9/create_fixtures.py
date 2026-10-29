from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from io import BytesIO
from PIL import Image, ImageDraw
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A5
from pypdf import PdfReader

root=Path(__file__).resolve().parent/'fixtures';root.mkdir(exist_ok=True)
pdf=root/'YomiHub-039-reader-test.pdf'
c=canvas.Canvas(str(pdf),pagesize=A5)
for page in range(1,4):
    c.setFont('Helvetica-Bold',22);c.drawString(35,530,'YomiHub 0.3.9 reader test')
    c.setFont('Helvetica',16);c.drawString(35,485,f'Page {page} of 3')
    c.setFont('Helvetica',12);c.drawString(35,450,'Test navigation, zoom and reading position.')
    c.setFillColorRGB(0.12,0.3,0.5);c.rect(35,100,340,250,fill=1,stroke=0)
    c.setFillColorRGB(1,1,1);c.setFont('Helvetica-Bold',70);c.drawCentredString(205,200,str(page));c.showPage()
c.save();assert len(PdfReader(pdf).pages)==3
with ZipFile(root/'YomiHub-039-comic-test.cbz','w',ZIP_DEFLATED) as z:
    for page in range(1,4):
        im=Image.new('RGB',(600,900),(220,235,250));draw=ImageDraw.Draw(im)
        draw.text((45,80),f'YomiHub 0.3.9 - page {page} / 3',fill='black',font_size=32)
        draw.rectangle((45,160,555,800),fill=(30*page,60,120))
        out=BytesIO();im.save(out,format='PNG');z.writestr(f'{page:03}.png',out.getvalue())
with ZipFile(root/'YomiHub-039-novel-test.epub','w') as z:
    z.writestr('mimetype','application/epub+zip')
    z.writestr('META-INF/container.xml','''<?xml version="1.0"?><container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>''')
    items=''.join(f'<item id="c{i}" href="c{i}.xhtml" media-type="application/xhtml+xml"/>' for i in range(1,4))
    spine=''.join(f'<itemref idref="c{i}"/>' for i in range(1,4))
    z.writestr('OEBPS/content.opf',f'''<?xml version="1.0"?><package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:identifier id="id">yomihub-test-039</dc:identifier><dc:title>YomiHub reader test</dc:title><dc:language>en</dc:language><dc:creator>YomiHub QA</dc:creator><meta property="dcterms:modified">2026-10-25T00:00:00Z</meta></metadata><manifest>{items}<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/></manifest><spine>{spine}</spine></package>''')
    nav=''.join(f'<li><a href="c{i}.xhtml">Chapter {i}</a></li>' for i in range(1,4))
    z.writestr('OEBPS/nav.xhtml',f'<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><head><title>Contents</title></head><body><nav epub:type="toc"><ol>{nav}</ol></nav></body></html>')
    for page in range(1,4):
        paras=''.join(f'<p>Test paragraph {n}. This original fixture checks scrolling, font size and saved reading position.</p>' for n in range(1,45))
        z.writestr(f'OEBPS/c{page}.xhtml',f'<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Chapter {page}</title></head><body><h1>Chapter {page}</h1>{paras}</body></html>')
print('Created PDF (3 pages), CBZ (3 images), EPUB (3 chapters).')
