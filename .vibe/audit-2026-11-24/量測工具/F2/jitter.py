# 手指停住時，外框的抖是哪一種：相鄰兩幀的位移是不是反向（每幀來回＝可以用兩幀平均消掉），還是同向慢移
from common import *
from playwright.sync_api import sync_playwright
import numpy as np
port=freeport();srv=serve(port)
JS='''async (seeds)=>{const out=[];for(const s of seeds){F2.fresh(61,{shine:0,opaque:.9});let hold=0,px=null,py=null,vx=null,vy=null,n0=N;const st=[];
 GEST.P4S(s,(ph)=>{update(F2.DT);if(ph!=='hold'||N!==n0){n0=N;px=null;vx=null;hold=0;return}hold++;const x=Float64Array.from(bnd,i=>X[i]),y=Float64Array.from(bnd,i=>Y[i]);
  if(px&&px.length===x.length){let mx=0,my=0;const nb=x.length;for(let i=0;i<nb;i++){mx+=x[i]-px[i];my+=y[i]-py[i]}mx/=nb;my/=nb;const dx=x.map((v,i)=>v-px[i]-mx),dy=y.map((v,i)=>v-py[i]-my);
   if(vx&&vx.length===nb&&hold>20){let a=0,b=0,c=0;for(let i=0;i<nb;i++){a+=dx[i]*vx[i]+dy[i]*vy[i];b+=dx[i]*dx[i]+dy[i]*dy[i];c+=vx[i]*vx[i]+vy[i]*vy[i]}st.push([a/Math.sqrt(b*c+1e-12),Math.sqrt(b/nb)])}vx=dx;vy=dy}
  px=x;py=y});for(const id of [...fingers.keys()])F2.ev('pointerup',id,0,0);out.push(...st)}return out}'''
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    for f in ('skinmodes.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
    r=np.array(pg.evaluate(JS,list(range(1,11))))
    c,a=r[:,0],r[:,1]
    print('停住 20 幀以後的格',len(r),'每幀外框 RMS 位移 px 中位 %.3f p90 %.3f p99 %.3f'%(np.median(a),np.percentile(a,90),np.percentile(a,99)))
    for lo,hi in ((0,.05),(.05,.3),(.3,1),(1,3),(3,99)):
        m=(a>=lo)&(a<hi)
        if m.any(): print('  位移 %.2f 到 %.2f px：%.1f%% 的格，相鄰兩幀同向係數 平均 %.2f，反向(<-0.3)比例 %.0f%%'%(lo,hi,100*m.mean(),c[m].mean(),100*(c[m]<-.3).mean()))
    print(errs);b.close()
srv.shutdown()
