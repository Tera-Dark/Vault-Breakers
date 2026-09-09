"""Offline geometry/layout review. NOT a Roblox screenshot or physics/rendering test.
Uses the production scene and UI coordinates captured by the Luau contract harness.
Optional local dependencies: Pillow + NumPy. Outputs ignored review images in .cache/review.
"""
from pathlib import Path
import json, math, sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.cache/python'))
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
out=root/'.cache/review';out.mkdir(exist_ok=True)
scene=json.loads((root/'.cache/scene.json').read_text())
def render_scene(width,height,eye,target,fov=65,filter_path='',parts=None,transparent=False):
    eye=np.array(eye,dtype=float);f=np.array(target,dtype=float)-eye;f/=np.linalg.norm(f)
    right=np.cross(f,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,f)
    camera=np.array([right,-up,f]); focal=height/2/math.tan(math.radians(fov/2))
    faces=[]
    for item in (scene if parts is None else parts):
        if item['alpha']<.5 or (filter_path and filter_path not in item['name']):continue
        m=np.array(item['matrix']).reshape(3,4);r,t=m[:,:3],m[:,3];size=np.array(item['size'])/2
        # Exclude overhead ceiling only for the cutaway overview.
        if item['name'].endswith('.Ceiling') and eye[1]>32:continue
        surfaces=[]
        if item['shape']=='Cylinder':
            steps=20;ring=[np.array([0,math.cos(i*2*math.pi/steps)*size[1],math.sin(i*2*math.pi/steps)*size[2]]) for i in range(steps)]
            for sign in [-1,1]:surfaces.append(([v+np.array([size[0]*sign,0,0]) for v in ring],np.array([sign,0,0])))
            for i in range(steps):
                a,b=ring[i],ring[(i+1)%steps];normal=a+b;normal/=np.linalg.norm(normal)
                surfaces.append(([a+[-size[0],0,0],a+[size[0],0,0],b+[size[0],0,0],b+[-size[0],0,0]],normal))
        else:
            for axis in range(3):
                u,v=[i for i in range(3) if i!=axis]
                for sign in [-1,1]:
                    vertices=[]
                    for a,b in [(-1,-1),(1,-1),(1,1),(-1,1)]:
                        vec=np.zeros(3);vec[axis]=sign*size[axis];vec[u]=a*size[u];vec[v]=b*size[v];vertices.append(vec)
                    n=np.zeros(3);n[axis]=sign;surfaces.append((vertices,n))
        for vertices,normal in surfaces:
            world=np.array(vertices)@r.T+t;center=world.mean(axis=0);normal=r@normal
            if normal@(eye-center)<=0:continue
            view=(world-eye)@camera.T
            # Clip polygons to the near plane; an interior floor/wall may cross it.
            clipped=[]
            for j,a in enumerate(view):
                b=view[(j+1)%len(view)];inside_a=a[2]>=.15;inside_b=b[2]>=.15
                if inside_a:clipped.append(a)
                if inside_a!=inside_b:clipped.append(a+(b-a)*((.15-a[2])/(b[2]-a[2])))
            if len(clipped)<3:continue
            view=np.array(clipped)
            points=np.column_stack([view[:,0]/view[:,2]*focal+width/2,view[:,1]/view[:,2]*focal+height/2])
            if points[:,0].max()<0 or points[:,0].min()>width or points[:,1].max()<0 or points[:,1].min()>height:continue
            key=np.array([-12,32,0])-center;key/=np.linalg.norm(key)
            shade=.58+.58*max(0,normal@key)
            if item['material']=='Neon':shade=1.8
            col=np.array(item['color'])*255*shade
            col=np.clip(col,0,255).astype(int)
            faces.append((view[:,2],points,[int(v) for v in col]))
    pixels=np.zeros((height,width,3),dtype=np.uint8);pixels[:]=[13,20,30]
    depth=np.full((height,width),np.inf)
    # A real per-pixel depth test avoids the painter's-algorithm floor/back-wall artifacts.
    for zs,points,color in faces:
        for index in range(1,len(points)-1):
            ids=[0,index,index+1];tri=points[ids];z=zs[ids]
            x0=max(0,math.floor(tri[:,0].min()));x1=min(width,math.ceil(tri[:,0].max()))
            y0=max(0,math.floor(tri[:,1].min()));y1=min(height,math.ceil(tri[:,1].max()))
            if x1<=x0 or y1<=y0:continue
            a,b,c=tri;den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
            if abs(den)<1e-8:continue
            yy,xx=np.mgrid[y0:y1,x0:x1];xx=xx+.5;yy=yy+.5
            u=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/den
            v=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/den
            w=1-u-v
            invz=u/z[0]+v/z[1]+w/z[2]
            dist=1/np.maximum(invz,1e-12)
            mask=(u>=0)&(v>=0)&(w>=0)&(dist<depth[y0:y1,x0:x1])
            depth[y0:y1,x0:x1][mask]=dist[mask];pixels[y0:y1,x0:x1][mask]=color
    if transparent:
        alpha=np.where(np.isfinite(depth),255,0).astype(np.uint8)
        return Image.fromarray(np.dstack([pixels,alpha]))
    return Image.fromarray(pixels)

main=render_scene(1360,800,[0,24,-5],[0,5,-56])
only_menu='--only-menu' in sys.argv
fontdir=Path('/usr/share/fonts/truetype/dejavu')
font_cache=root/'.cache/fonts'
def font(size,bold=False,family='',text=''):
    if any(ord(ch)>0x2fff for ch in text) and (font_cache/'NotoSansCJKsc-Bold.otf').exists():
        file=font_cache/'NotoSansCJKsc-Bold.otf'
    elif family=='FredokaOne' and (font_cache/'FredokaOne.ttf').exists():file=font_cache/'FredokaOne.ttf'
    else:file=fontdir/('DejaVuSans-Bold.ttf' if bold else 'DejaVuSans.ttf')
    return ImageFont.truetype(str(file),max(8,int(size)))
def wrap(text,f,width):
    lines=[]
    for paragraph in text.split('\n'):
        line=''
        chunks=list(paragraph) if any(ord(ch)>0x2fff for ch in paragraph) else paragraph.split(' ')
        separator='' if any(ord(ch)>0x2fff for ch in paragraph) else ' '
        for word in chunks:
            candidate=(line+separator+word).strip()
            if line and f.getlength(candidate)>width:lines.append(line);line=word
            else:line=candidate
        lines.append(line)
    return lines

def gradient_image(w,h,gradient,alpha=255):
    stops=gradient.get('colors') or []
    if not stops:return None
    angle=math.radians(gradient.get('rotation',90));dx,dy=math.cos(angle),math.sin(angle)
    yy,xx=np.mgrid[0:h,0:w]
    t=np.clip((dx*(xx/max(1,w-1)-.5)+dy*(yy/max(1,h-1)-.5))/(abs(dx)+abs(dy))+.5,0,1)
    colors=np.zeros((h,w,4),dtype=np.uint8)
    for channel in range(3):colors[:,:,channel]=np.interp(t,[s['time'] for s in stops],[s['color'][channel]*255 for s in stops]).astype(np.uint8)
    colors[:,:,3]=alpha
    return Image.fromarray(colors)

def annotate(image,label):
    image=image.convert('RGBA');d=ImageDraw.Draw(image)
    d.rectangle([0,image.height-22,image.width,image.height],fill=(5,10,17,255))
    d.text((10,image.height-17),label,font=font(10),fill=(174,191,206,255))
    return image.convert('RGB')

if not only_menu:
    vault_parts=[i for i in scene if 'VaultWorld.MAIN.Vault_01.' in i['name']]
    center=np.array([np.array(i['matrix']).reshape(3,4)[:,3] for i in vault_parts]).mean(axis=0)
    facing=np.array([0,0,-51])-center;facing[1]=0;facing/=np.linalg.norm(facing)
    right=np.cross(facing,[0,1,0]);eye=center+facing*17+right*8+[0,4.5,0]
    close=render_scene(1000,850,eye,center,40,'VaultWorld.MAIN.Vault_01.')
    for label,image in [('stage-geometry',main),('vault-geometry',close)]:
        annotate(image,'OFFLINE GEOMETRY REVIEW / NOT ROBLOX RENDERING / NO SURFACE GUI OR NATIVE LIGHTING').save(out/(label+'.png'))

backgrounds={}
def background(w,h,kind):
    key=(w,h,kind)
    if key not in backgrounds:
        if kind=='lounge':
            # A representative angle from the real lounge; NOT a PlayerModule camera simulation.
            backgrounds[key]=render_scene(w,h,[29,21,54],[5,6,-41],67).convert('RGBA')
        else:backgrounds[key]=main.resize((w,h),Image.Resampling.LANCZOS).convert('RGBA')
    return backgrounds[key].copy()

thumbnails={}
for layoutfile in sorted((root/'.cache').glob('layout-*.json')):
    if only_menu and not any(tag in layoutfile.name for tag in ('menu-','world-hud-')):continue
    layout=json.loads(layoutfile.read_text());w,h=layout['width'],layout['height']
    if '-zh' in layoutfile.stem and not (font_cache/'NotoSansCJKsc-Bold.otf').exists():
        print('Skipping Chinese image without a CJK reference font:',layoutfile.name);continue
    bg=background(w,h,layout.get('background','stage'))
    for el in sorted(layout['elements'],key=lambda el:el['z']):
        x,y,ew,eh=map(lambda v:int(round(v)),[el['x'],el['y'],el['w'],el['h']])
        if ew<=0 or eh<=0:continue
        layer=Image.new('RGBA',(w,h));d=ImageDraw.Draw(layer)
        radius=max(0,int(el.get('radius',0)))
        if el['alpha']>0:
            color=tuple(int(v*255) for v in el['bg'])+(int(el['alpha']*255),)
            d.rounded_rectangle([x,y,x+ew,y+eh],radius=radius,fill=color)
            if el.get('gradient') and not el['text']:
                fill=gradient_image(ew,eh,el['gradient'],color[3])
                if fill:
                    mask=Image.new('L',(ew,eh));ImageDraw.Draw(mask).rounded_rectangle([0,0,ew-1,eh-1],radius=radius,fill=255)
                    fill.putalpha(mask.point(lambda n:int(n*el['alpha'])));layer.paste(fill,(x,y))
        if el.get('viewport'):
            view=el['viewport'];key=(el['name'],ew,eh,tuple(view['eye']),tuple(view['tint']))
            if key not in thumbnails:
                image=render_scene(ew*2,eh*2,view['eye'],view['target'],view['fov'],parts=view['parts'],transparent=True).resize((ew,eh),Image.Resampling.LANCZOS)
                data=np.array(image);data[:,:,:3]=(data[:,:,:3]*np.array(view['tint'])).astype(np.uint8)
                thumbnails[key]=Image.fromarray(data)
            layer.paste(thumbnails[key],(x,y))
        if el['text']:
            size=el['textSize'];family=el.get('font','')
            f=font(size,'Bold' in family or family=='FredokaOne',family,el['text'])
            if el.get('textScaled'):
                while size>10 and (f.getlength(el['text'])>ew-4 or f.getbbox(el['text'])[3]-f.getbbox(el['text'])[1]>eh-2):
                    size-=1;f=font(size,True,family,el['text'])
            lines=wrap(el['text'],f,max(ew-4,1));lh=int(size*1.17)
            ty=y+max(0,(eh-len(lines)*lh)/2)
            text_layer=Image.new('RGBA',(w,h));td=ImageDraw.Draw(text_layer)
            mask=Image.new('L',(w,h));md=ImageDraw.Draw(mask)
            for line in lines:
                tw=f.getlength(line);tx=x if el['align']=='Left' else (x+ew-tw if el['align']=='Right' else x+(ew-tw)/2)
                # Anchor to the actual glyph box, unlike Roblox's unmodeled line metrics.
                offset=f.getbbox(line)[1];point=(tx,ty-offset)
                width=2 if el.get('textStroke',0)>.1 else 0
                td.text(point,line,font=f,fill=tuple(int(v*255) for v in el['color'])+(int(el.get('textAlpha',1)*255),),stroke_width=width,stroke_fill=tuple(int(v*255) for v in el.get('strokeColor',[0,0,0]))+(255,))
                md.text(point,line,font=f,fill=255);ty+=lh
            layer=Image.alpha_composite(layer,text_layer)
            if el.get('gradient'):
                fill=gradient_image(ew,eh,el['gradient'])
                if fill:
                    fill.putalpha(mask.crop((x,y,x+ew,y+eh)));layer.paste(fill,(x,y),fill)
        if el.get('border'):
            border=el['border'];color=tuple(int(v*255) for v in border['color'])+(int(border['alpha']*255),)
            # Border is emitted after descendants by the hierarchy capture.
            ImageDraw.Draw(layer).rounded_rectangle([x,y,x+ew,y+eh],radius=radius,outline=color,width=max(1,int(border['width'])))
        clip=tuple(int(round(v)) for v in el.get('clip',[0,0,w,h]))
        if clip[2]<=clip[0] or clip[3]<=clip[1]:continue
        restricted=Image.new('RGBA',(w,h));restricted.paste(layer.crop(clip),clip[:2]);bg=Image.alpha_composite(bg,restricted)
    annotate(bg,'OFFLINE GUI / NOT A ROBLOX SCREENSHOT / FONT & LIGHTING APPROXIMATION' if w>600 else 'OFFLINE GUI REVIEW / NOT A ROBLOX SCREENSHOT').save(out/(layoutfile.stem+'.png'))
print('Review images:',out)

# Side-by-side state review, not a fabricated recording of a live Roblox client.
closed=out/'layout-world-hud-desktop.png'
opened=out/'layout-menu-desktop-zh.png'
if not opened.exists():opened=out/'layout-menu-desktop.png'
if closed.exists() and opened.exists():
    sheet=Image.new('RGB',(1600,544),(12,18,27));d=ImageDraw.Draw(sheet)
    titles=['01  MENU CLOSED / THE WORLD COMES FIRST','02  MENU OPEN / ONE CLICK BACK TO THE GAME']
    for x,title,file in zip((16,816),titles,(closed,opened)):
        d.text((x,18),title,font=font(17,True),fill=(239,231,211))
        image=Image.open(file).convert('RGB').resize((768,432),Image.Resampling.LANCZOS)
        sheet.paste(image,(x,57))
    d.text((18,511),'PRODUCTION GUI + GEOMETRY / OFFLINE REVIEW, NOT ROBLOX SCREENSHOTS / NATIVE DEVICE VALIDATION STILL REQUIRED',font=font(12),fill=(156,176,190))
    sheet.save(out/'menu-states.png')
