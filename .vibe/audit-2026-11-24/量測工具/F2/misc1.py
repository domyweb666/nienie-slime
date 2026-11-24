from common import *
from playwright.sync_api import sync_playwright
port=freeport();srv=serve(port)
PULL='''(o)=>{F2.fresh(1,{shine:0,opaque:.9,...o.over});const c=globalC,bi=F2.edgePt(0.15,-1),[sx,sy]=F2.scr(X[bi]+(c.xc-X[bi])*.25,Y[bi]+(c.yc-Y[bi])*.25);F2.ev('pointerdown',1,sx,sy);for(let i=0;i<4;i++)update(F2.DT);let e=[sx,sy],mk=0,ms=0;const rem=[];let n0=REM.n;for(let s=1;s<=50;s++){e=F2.clampS(sx-.2*o.d*R*s/50,sy-o.d*R*s/50);F2.ev('pointermove',1,e[0],e[1]);update(F2.DT);draw();mk=Math.max(mk,THIN.k);ms=Math.max(ms,[...fingers.values()][0].stretch);if(REM.n!==n0){n0=REM.n;rem.push(+REM.ms.toFixed(1))}}for(let i=0;i<60;i++){update(F2.DT);draw();mk=Math.max(mk,THIN.k);if(REM.n!==n0){n0=REM.n;rem.push(+REM.ms.toFixed(1))}}
 return {thinK:mk,stretch:ms,effPull:effPull(),rem}}'''
REMS='''async (seeds)=>{const out=[];for(const s of seeds){F2.fresh(61,{shine:0,opaque:.9});let n0=REM.n;GEST.P4S(s,()=>{update(F2.DT);if(REM.n!==n0){n0=REM.n;if(REM.last===t||Math.abs(REM.last-t)<.02)out.push(+REM.ms.toFixed(1))}});for(const id of [...fingers.keys()])F2.ev('pointerup',id,0,0)}return out}'''
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    for f in ('skinmodes.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
    for o in ({'d':4.5,'over':{'thin':1}},{'d':4.5,'over':{'thin':1,'endless':0,'maxPull':3}}): print(o,pg.evaluate(PULL,o))
    r=pg.evaluate(REMS,list(range(1,7)))
    import numpy as np
    r=np.array(r);print('remesh ms n',len(r),'p10 %.1f median %.1f p90 %.1f max %.1f'%(np.percentile(r,10),np.median(r),np.percentile(r,90),r.max()))
    print(errs);b.close()
srv.shutdown()
