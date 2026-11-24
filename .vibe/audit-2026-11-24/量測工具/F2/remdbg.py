from common import *
from playwright.sync_api import sync_playwright
import numpy as np
port=freeport();srv=serve(port)
JS='''async ([fn,seeds])=>{const out=[];const cen=()=>{let A=0,cx=0,cy=0;const n=bnd.length;for(let i=0;i<n;i++){const a=bnd[i],b=bnd[(i+1)%n],c=X[a]*Y[b]-X[b]*Y[a];A+=c;cx+=(X[a]+X[b])*c;cy+=(Y[a]+Y[b])*c}return [cx/3/A,cy/3/A,A/2/A0]};
 const rm0=remesh;let pre=null,post=null;remesh=function(b){pre=cen();const r=rm0(b);if(r){post=cen();post.back=b?1:0}else pre=null;return r};
 for(const s of seeds){F2.fresh(s,{shine:0,opaque:.9});const H=[];let last=cen(),wait=0,cur=null;
  GEST.CALM(s,(ph)=>{pre=null;post=null;update(F2.DT);const c=cen();if(cur){cur.after.push([+(c[0]-cur.post[0]).toFixed(1),+(c[1]-cur.post[1]).toFixed(1),+c[2].toFixed(2)]);if(cur.after.length>=8){out.push(cur);cur=null}}
   if(post&&!post.back&&!cur){cur={s,ph,prev:[+(pre[0]-last[0]).toFixed(1),+(pre[1]-last[1]).toFixed(1)],swap:[+(post[0]-pre[0]).toFixed(1),+(post[1]-pre[1]).toFixed(1)],a:[+pre[2].toFixed(2),+post[2].toFixed(2)],post,after:[],f:[...fingers.values()].map(f=>[+(f.stretch||0).toFixed(2),f.mem.length])}}
   last=c});for(const id of [...fingers.keys()])F2.ev('pointerup',id,0,0)}return out}'''
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    for f in ('skinmodes.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
    r=pg.evaluate(JS,['CALM',list(range(1,15))]);b.close()
srv.shutdown()
for ph in ('d','pull','hold'):
    q=[x for x in r if x['ph']==ph]
    if not q: continue
    h=lambda k:np.array([np.hypot(*x[k]) for x in q])
    print(ph,'n',len(q),'補點前那一格（物理）移 中位 %.1f｜換點本身移 中位 %.2f 最大 %.2f｜之後第 1 格 中位 %.1f 最大 %.1f｜第 8 格 中位 %.1f 最大 %.1f'%(np.median(h('prev')),np.median(h('swap')),h('swap').max(),np.median([np.hypot(*x['after'][0][:2]) for x in q]),max(np.hypot(*x['after'][0][:2]) for x in q),np.median([np.hypot(*x['after'][-1][:2]) for x in q]),max(np.hypot(*x['after'][-1][:2]) for x in q)))
    for x in q[:5]: print('   ',x['s'],'前格',x['prev'],'換點',x['swap'],'面積',x['a'],'之後',x['after'],x['f'])
