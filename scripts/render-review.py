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
def render_scene(width,height,eye,target,fov=65,filter_path=''):
    eye=np.array(eye,dtype=float);f=np.array(target,dtype=float)-eye;f/=np.linalg.norm(f)
    right=np.cross(f,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,f)
    camera=np.array([right,-up,f]); focal=height/2/math.tan(math.radians(fov/2))
    faces=[]
    for item in scene:
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
            if view[:,2].min()<.4:continue
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
    return Image.fromarray(pixels)

main=render_scene(1360,800,[0,24,-5],[0,5,-56])
# Geometry remains deliberately separate from a Roblox rendering claim.
close=render_scene(1100,850,[-16,11,-16],[-21.85,5.7,-24.95],48,'VaultWorld.MAIN.Vault_12')
# More reliable local vault framing derived from the generated model's interaction coordinates.
vault_parts=[i for i in scene if 'VaultWorld.MAIN.Vault_01.' in i['name']]
center=np.array([np.array(i['matrix']).reshape(3,4)[:,3] for i in vault_parts]).mean(axis=0)
facing=np.array([0,0,-51])-center;facing[1]=0;facing/=np.linalg.norm(facing)
right=np.cross(facing,[0,1,0]);eye=center+facing*17+right*8+[0,4.5,0]
close=render_scene(1000,850,eye,center,40,'VaultWorld.MAIN.Vault_01.')

fontdir=Path('/usr/share/fonts/truetype/dejavu')
def font(size,bold=False):
    return ImageFont.truetype(str(fontdir/('DejaVuSans-Bold.ttf' if bold else 'DejaVuSans.ttf')),max(8,int(size*.92)))
def wrap(text,f,w):
    lines=[]
    for paragraph in text.split('\n'):
        line=''
        for word in paragraph.split(' '):
            candidate=(line+' '+word).strip()
            if line and f.getlength(candidate)>w:lines.append(line);line=word
            else:line=candidate
        lines.append(line)
    return lines
for label,image in [('stage-geometry',main),('vault-geometry',close)]:
    reviewed=image.copy();d=ImageDraw.Draw(reviewed);d.rectangle([0,reviewed.height-25,reviewed.width,reviewed.height],fill=(6,10,16));d.text((12,reviewed.height-20),'OFFLINE GEOMETRY REVIEW / NOT ROBLOX RENDERING / NO SURFACE GUI OR NATIVE LIGHTING',font=font(11),fill=(146,163,175));reviewed.save(out/(label+'.png'))
for layoutfile in (root/'.cache').glob('layout-*.json'):
    layout=json.loads(layoutfile.read_text());w,h=layout['width'],layout['height']
    bg=main.resize((w,h),Image.Resampling.LANCZOS).convert('RGBA')
    if 'lobby' in layoutfile.name:bg=Image.blend(bg,Image.new('RGBA',(w,h),(12,18,27,255)),.58)
    for el in sorted(layout['elements'],key=lambda el:el['z']):
        if el['class']=='ViewportFrame':continue
        x,y,ew,eh=el['x'],el['y'],el['w'],el['h']
        if ew<=0 or eh<=0:continue
        layer=Image.new('RGBA',(w,h));d=ImageDraw.Draw(layer)
        if el['alpha']>0:
            color=tuple(int(v*255) for v in el['bg'])+(int(el['alpha']*255),)
            radius=7 if ew>50 and eh>24 else 0
            d.rounded_rectangle([x,y,x+ew,y+eh],radius=radius,fill=color)
        if el['text']:
            f=font(el['textSize'],el['name'] not in ('Introduction','PossibleRange','InputHint','FreePlayNote','PhaseDescription'))
            lines=wrap(el['text'],f,max(ew-4,1));lh=int(el['textSize']*1.16);ty=y+max(0,(eh-len(lines)*lh)/2)
            for line in lines:
                tw=f.getlength(line);tx=x if el['align']=='Left' else (x+ew-tw if el['align']=='Right' else x+(ew-tw)/2)
                d.text((tx,ty),line,font=f,fill=tuple(int(v*255) for v in el['color'])+(255,));ty+=lh
        clip=el.get('clip',[0,0,w,h]);clip=tuple(map(lambda v:int(round(v)),clip))
        if clip[2]<=clip[0] or clip[3]<=clip[1]:continue
        restricted=Image.new('RGBA',(w,h));restricted.paste(layer.crop(clip),clip[:2]);layer=restricted
        bg=Image.alpha_composite(bg,layer)
    d=ImageDraw.Draw(bg);d.rectangle([0,h-16,w,h],fill=(6,10,16,255));d.text((8,h-14),'OFFLINE LAYOUT REVIEW / NOT A ROBLOX SCREENSHOT',font=font(9),fill=(126,145,160,255))
    bg.convert('RGB').save(out/(layoutfile.stem+'.png'))
print('Review images:',out)
