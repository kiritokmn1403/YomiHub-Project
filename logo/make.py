from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageFont
import os, math
S=4096  # supersample canvas
def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))
def gradient(w,h,stops,angle=135):
    im=Image.new('RGB',(w,h)); px=im.load()
    a=math.radians(angle); dx,dy=math.cos(a),math.sin(a)
    L=abs(w*dx)+abs(h*dy)
    for y in range(0,h,4):
        for x in range(0,w,4):
            t=((x*dx+y*dy)-min(0,w*dx)-min(0,h*dy))/L
            t=max(0,min(1,t))
            for i in range(len(stops)-1):
                p0,c0=stops[i]; p1,c1=stops[i+1]
                if t<=p1:
                    c=lerp(c0,c1,(t-p0)/(p1-p0) if p1>p0 else 0); break
            for yy in range(y,min(y+4,h)):
                for xx in range(x,min(x+4,w)): px[xx,yy]=c
    return im
def mark(size=S):
    """Alpha mask of the YomiHub mark: open book whose upper corners rise like
    two ears, with a play triangle cut out of the spine area."""
    m=Image.new('L',(size,size),0); d=ImageDraw.Draw(m)
    s=size/1024
    k=0.86
    P=lambda pts:[((512+(x-512)*k)*s,(532+(y-532)*k)*s) for x,y in pts]
    # left page (with ear corner)
    d.polygon(P([(512,330),(470,300),(330,262),(214,250),(196,214),(178,300),(178,742),(330,752),(470,786),(512,812)]),fill=255)
    # right page (mirror)
    d.polygon(P([(512,330),(554,300),(694,262),(810,250),(828,214),(846,300),(846,742),(694,752),(554,786),(512,812)]),fill=255)
    # spine gap
    d.line(P([(512,345),(512,800)]),fill=0,width=int(16*s))
    # play triangle cut-out
    d.polygon(P([(440,440),(440,640),(612,540)]),fill=0)
    # small page lines on the right page
    for i,y in enumerate([380,440,500]):
        pass
    # rounded play triangle
    return m.filter(ImageFilter.GaussianBlur(2*s))
def rounded(size,r,inset=0):
    m=Image.new('L',(size,size),0); ImageDraw.Draw(m).rounded_rectangle([inset,inset,size-inset,size-inset],radius=r,fill=255); return m
STOPS=[(0,(91,44,182)),(0.55,(30,120,230)),(1,(0,191,165))]
bg=gradient(S,S,STOPS)
mk=mark()
# full-color icon (rounded square)
def color_icon(dark=False):
    base=Image.new('RGBA',(S,S),(0,0,0,0))
    shape=rounded(S,int(S*0.23),int(S*0.03))
    fill=Image.new('RGB',(S,S),(18,22,34)) if dark else bg
    base.paste(fill,(0,0),shape)
    # soft shadow under mark
    sh=mk.filter(ImageFilter.GaussianBlur(S*0.012)).point(lambda v:int(v*0.35))
    shimg=Image.new('RGBA',(S,S),(0,0,0,255)); shimg.putalpha(ImageChops.offset(sh,0,int(S*0.012)))
    base=Image.alpha_composite(base,shimg)
    white=Image.new('RGBA',(S,S),(255,255,255,255)); white.putalpha(mk)
    base=Image.alpha_composite(base,white)
    if dark:
        # colour the play cut-out area with the gradient on the dark icon
        tri=Image.new('L',(S,S),0); s=S/1024
        k=0.86; Q=lambda x,y:((512+(x-512)*k)*s,(532+(y-532)*k)*s)
        ImageDraw.Draw(tri).polygon([Q(440,440),Q(440,640),Q(612,540)],fill=255)
        g=bg.convert('RGBA'); g.putalpha(tri.filter(ImageFilter.GaussianBlur(2*s)))
        base=Image.alpha_composite(base,g)
    base.putalpha(ImageChops.multiply(base.getchannel('A'),shape))
    return base
out=os.path.expanduser('~/ov')
ci=color_icon(); cd=color_icon(dark=True)
ci.resize((1024,1024),Image.LANCZOS).save(os.path.expanduser('~/logo/yomihub_logo_1024.png'))
cd.resize((1024,1024),Image.LANCZOS).save(os.path.expanduser('~/logo/yomihub_logo_dark_1024.png'))
# app silhouette (tinted in-app)
sil=Image.new('RGBA',(S,S),(0,0,0,0)); sil.putalpha(mk)
sil.resize((1024,1024),Image.LANCZOS).save(out+'/assets/app_icons/icon.png')
cd.resize((1024,1024),Image.LANCZOS).save(out+'/assets/app_icons/icon-black.png')
ci.resize((1024,1024),Image.LANCZOS).save(out+'/assets/app_icons/icon-red.png')
for d,px in {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}.items():
    im=ci.resize((px,px),Image.LANCZOS)
    for n in ['ic_launcher.png','launcher_icon.png']:
        im.save(f'{out}/android/app/src/main/res/mipmap-{d}/{n}')
# TV banner
def banner(w,h):
    b=gradient(w*2,h*2,STOPS,angle=20).resize((w,h),Image.LANCZOS).convert('RGBA')
    ic=Image.new('RGBA',(S,S),(0,0,0,0)); ic.putalpha(mk)
    white=Image.new('RGBA',(S,S),(255,255,255,255)); white.putalpha(mk)
    sz=int(h*0.62); b.alpha_composite(white.resize((sz,sz),Image.LANCZOS),(int(w*0.06),(h-sz)//2))
    d=ImageDraw.Draw(b); f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',int(h*0.17))
    d.text((int(w*0.06)+sz+int(w*0.03),h//2),'YomiHub',font=f,fill='white',anchor='lm')
    return b.convert('RGB')
banner(640,360).save(out+'/android/app/src/main/res/drawable/tv_banner.png')
banner(320,180).save(out+'/android/app/src/main/res/drawable-xhdpi/tv_banner.png')
print('done')
