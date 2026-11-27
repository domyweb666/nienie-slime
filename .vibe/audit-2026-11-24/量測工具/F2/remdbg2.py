from common import *
from playwright.sync_api import sync_playwright
import numpy as np
port=freeport();srv=serve(port)
JS='''async ([fn,seeds])=>{const out=[];const cen=()=>{let A=0,cx=0,cy=0;const n=bnd.length;for(let i=0;i<n;i++){const a=bnd[i],b=bnd[(i+1)%n],c=X[a]*Y[b]-X[b]*Y[a];A+=c;cx+=(X[a]+X[b])*c;cy+=(Y[a]+Y[b])*c}return [cx/3/A,cy/3/A,A/2/A0]};
 const mean=()=>{let x=0,y=0;for(let i=0;i<N;i++){x+=X[i];y+=Y[i]}return [x/N,y/N]};
 const rm0=remesh;let ev=null;remesh=function(b){const c0=cen(),m0=mean(),g0=[globalC.xc,globalC.yc];const r=rm0(b);if(r)ev={back:b?1:0,c0,c1:cen(),m0,m1:mean(),g0,g1:[globalC.xc,globalC.yc],home:[HOMEX,HOMEY],drag:[DRAG.ox,DRAG.oy]};return r};
 for(const s of seeds){F2.fresh(s,{shine:0,opaque:.9});let cur=null;
  GEST[fn](s,(ph)=>{ev=null;update(F2.DT);const c=cen();if(cur){cur.n++;if(cur.n===1)cur.a1=[c[0]-cur.c1[0],c[1]-cur.c1[1]];if(cur.n===8){cur.a8=[c[0]-cur.c1[0],c[1]-cur.c1[1]];out.push(cur);cur=null}}
   if(ev&&!cur){cur={...ev,ph,s,n:0,a0:[c[0]-ev.c1[0],c[1]-ev.c1[1]]}}});for(const id of [...fingers.keys()])F2.ev('pointerup',id,0,0)}return out}'''
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    for f in ('skinmodes.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
    r=pg.evaluate(JS,['CALM',list(range(1,21))]);b.close()
srv.shutdown()
for name,sel in (('d',lambda x:x['ph']=='d' and not x['back']),('pull',lambda x:x['ph']=='pull' and not x['back']),('hold',lambda x:x['ph']=='hold' and not x['back']),('換回',lambda x:x['back'])):
    q=[x for x in r if sel(x)]
    if not q: continue
    dm=np.array([[x['m1'][0]-x['m0'][0],x['m1'][1]-x['m0'][1]] for x in q]);a0=np.array([x['a0'] for x in q]);a1=np.array([x['a1'] for x in q]);a8=np.array([x['a8'] for x in q]);dc=np.array([[x['c1'][0]-x['c0'][0],x['c1'][1]-x['c0'][1]] for x in q])
    cc=lambda u,v:np.corrcoef(u.ravel(),v.ravel())[0,1]
    print(name,'n',len(q),'｜外框重心換點時移 %.2f｜粒子平均換點時移 中位 %.1f p90 %.1f｜同一格之後整隻移 中位 %.1f p90 %.1f｜兩格後 %.1f｜相關（-粒子平均移, 同一格移）%.2f （兩格後）%.2f（八格後）%.2f'%(np.median(np.hypot(*dc.T)),np.median(np.hypot(*dm.T)),np.percentile(np.hypot(*dm.T),90),np.median(np.hypot(*a0.T)),np.percentile(np.hypot(*a0.T),90),np.median(np.hypot(*a1.T)),cc(-dm,a0),cc(-dm,a1),cc(-dm,a8)))
    for x in q[:3]: print('    粒子平均移',np.round([x['m1'][0]-x['m0'][0],x['m1'][1]-x['m0'][1]],1),'globalC 換點前後',np.round(x['g0'],0),np.round(x['g1'],0),'同格整隻移',np.round(x['a0'],1),'兩格',np.round(x['a1'],1))
