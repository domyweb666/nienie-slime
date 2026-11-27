from common import *
from playwright.sync_api import sync_playwright
import base64,io
from PIL import Image
FIX=BASE+'/fix4/prototype/web'
port=freeport();srv=serve(port,FIX)
PULL='''(d)=>{F2.fresh(1,{shine:0,opaque:.9});const c=globalC,bi=F2.edgePt(0.15,-1),[sx,sy]=F2.scr(X[bi]+(c.xc-X[bi])*.25,Y[bi]+(c.yc-Y[bi])*.25);F2.ev('pointerdown',1,sx,sy);for(let i=0;i<4;i++)update(F2.DT);let e=[sx,sy];for(let s=1;s<=50;s++){e=F2.clampS(sx-.2*d*R*s/50,sy-d*R*s/50);F2.ev('pointermove',1,e[0],e[1]);update(F2.DT)}for(let i=0;i<40;i++)update(F2.DT)}'''
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    pg.evaluate("()=>{document.getElementById('hint').style.display='none';document.getElementById('view').style.display='none';JELX.smooth=1}")
    ims=[]
    for d in (0.01,4.5):
        pg.evaluate(PULL,d)
        for md in (0,1,3,9):
            m=pg.evaluate('(m)=>{JELX.mode=m;draw();F2.readSkin();let A=0;for(const v of F2.skin)A+=v;const k=document.createElement("canvas");k.width=393;k.height=852;k.getContext("2d").drawImage(cv,0,0,393,852);return [A,JEL.gl.getError(),k.toDataURL("image/jpeg",.9),F2.comps(F2.skin,1).filter(c=>c.A>=6).map(c=>c.A)]}',md)
            print('d',d,'mode',md,'skin area',m[0],'glerr',m[1],'pieces',m[3][:6]);ims.append(Image.open(io.BytesIO(base64.b64decode(m[2].split(',')[1]))))
    n=len(ims)//2;C=Image.new('RGB',(393*n,852*2))
    for i,im in enumerate(ims): C.paste(im,((i%n)*393,(i//n)*852))
    C.resize((393*n//2,852)).save(BASE+'/shots/gpu_modes4.jpg',quality=88)
    print(errs);b.close()
srv.shutdown()
