# 連續幾格的畫面（同一組種子），m0 與 m9 上下排
from common import *
from playwright.sync_api import sync_playwright
import base64,io
from PIL import Image
fn,seed,f0,f1,st,out=sys.argv[1],int(sys.argv[2]),int(sys.argv[3]),int(sys.argv[4]),int(sys.argv[5]),sys.argv[6]
port=freeport();srv=serve(port,BASE+'/fix4/prototype/web')
JS='''async ([fn,seed,f0,f1,st])=>{const out=[];F2.fresh(fn==='P4S'?61:seed,{shine:0,opaque:.9});let fr=0,lr=REM.n,ln=N;const modes=[0,1,3,9];
 const shot=()=>{const k=document.createElement('canvas');k.width=393;k.height=852;k.getContext('2d').drawImage(cv,0,0,393,852);return k.toDataURL('image/jpeg',.85)};
 GEST[fn](seed,(ph)=>{update(F2.DT);fr++;const rm=REM.n!==lr||N!==ln;lr=REM.n;ln=N;if(fr%4===0||rm){for(const m of modes){JELX.mode=m;F2.measure()}}
  if(fr>=f0&&fr<=f1&&(fr-f0)%st===0){JELX.mode=0;draw();F2.readSkin();let A=0;for(const v of F2.skin)A+=v;const a=shot();JELX.mode=9;draw();out.push([fr,ph,A,F2.invN(),a,shot()]);JELX.mode=0}});
 return out}'''
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    for f in ('modes_fix4.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
    r=pg.evaluate(JS,[fn,seed,f0,f1,st]);b.close()
srv.shutdown()
n=len(r);C=Image.new('RGB',(393*n,852*2))
for i,q in enumerate(r):
    print(q[0],q[1],'皮面積',q[2],'翻面',q[3])
    for j in (4,5): C.paste(Image.open(io.BytesIO(base64.b64decode(q[j].split(',')[1]))),(i*393,(j-4)*852))
s=min(1,2000/C.width);C.resize((int(C.width*s),int(C.height*s))).save(out,quality=85)
