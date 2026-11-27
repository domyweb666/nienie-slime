from common import *
from playwright.sync_api import sync_playwright
import base64,io
from PIL import Image
port=freeport();srv=serve(port,BASE+'/fix4/prototype/web')
JS='''async ([seed,ev,shots])=>{const out=[],im=[];F2.fresh(seed,{shine:0,opaque:.9});let fr=0,lr=REM.n,ln=N;const modes=[0,3,9];
 const shot=()=>{const k=document.createElement('canvas');k.width=393;k.height=852;k.getContext('2d').drawImage(cv,0,0,393,852);return k.toDataURL('image/jpeg',.85)};
 GEST.CALM(seed,(ph,g)=>{update(F2.DT);fr++;const rm=REM.n!==lr||N!==ln;lr=REM.n;ln=N;if(fr%ev===0||rm){for(const m of modes){JELX.mode=m;F2.measure()}JELX.mode=0;let A=0;const n=bnd.length;for(let i=0;i<n;i++){const a=bnd[i],b=bnd[(i+1)%n];A+=X[a]*Y[b]-X[b]*Y[a]}let x0=1e9,x1=-1e9,y0=1e9,y1=-1e9,c=0;for(let i=0;i<N;i++){x0=Math.min(x0,X[i]);x1=Math.max(x1,X[i]);y0=Math.min(y0,Y[i]);y1=Math.max(y1,Y[i]);if(X[i]<-2||X[i]>W+2)c++}
   let As=0;for(const v of F2.skin)As+=v;const f=[...fingers.values()][0];
   out.push([fr,ph,g,Math.round(Math.abs(A)/2)/Math.round(A0),Math.round(x0),Math.round(x1),Math.round(y0),Math.round(y1),+(c/N).toFixed(2),F2.invN(),REM.n,f?[Math.round(f.sx),Math.round(f.sy),+(f.stretch||0).toFixed(2)]:null,SILL.surf])}
   if(shots.includes(fr)){JELX.mode=0;draw();im.push(shot())}});return [out,im]}'''
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    for f in ('modes_fix4.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
    out,im=pg.evaluate(JS,[6,6,[640,666,678,690,720,750,756,780]]);b.close()
srv.shutdown()
for q in out:
    if 624<=q[0]<=790: print(q[0],q[1],'g',q[2],'面積比 %.2f'%q[3],'x %d~%d y %d~%d'%tuple(q[4:8]),'螢幕外 %.0f%%'%(100*q[8]),'翻面',q[9],'補點',q[10],'手指',q[11],q[12])
C=Image.new('RGB',(393*len(im),852))
for i,s in enumerate(im): C.paste(Image.open(io.BytesIO(base64.b64decode(s.split(',')[1]))),(i*393,0))
C.resize((C.width//2,C.height//2)).save(BASE+'/shots/calm6.jpg',quality=85)
