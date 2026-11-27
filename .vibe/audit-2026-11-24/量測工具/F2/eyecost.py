from common import *
from playwright.sync_api import sync_playwright
port=freeport();srv=serve(port)
JS='''(d)=>{F2.fresh(1,{shine:0,opaque:.9});const c=globalC,bi=F2.edgePt(0.15,-1),[sx,sy]=F2.scr(X[bi]+(c.xc-X[bi])*.25,Y[bi]+(c.yc-Y[bi])*.25);if(d>0){F2.ev('pointerdown',1,sx,sy);for(let i=0;i<4;i++)update(F2.DT);let e=[sx,sy];for(let s=1;s<=50;s++){e=F2.clampS(sx-.2*d*R*s/50,sy-d*R*s/50);F2.ev('pointermove',1,e[0],e[1]);update(F2.DT)}for(let i=0;i<60;i++)update(F2.DT)}
 const best=(f,n)=>{let b=1e9;for(let k=0;k<15;k++){const t0=performance.now();for(let i=0;i<n;i++)f();b=Math.min(b,(performance.now()-t0)/n)}return +b.toFixed(3)};
 const P=boundaryPts();
 // 正常
 const o={N,nb:bnd.length,eye:best(()=>eyePose(1/60),20),bp:best(()=>boundaryPts(),200)};
 // 逼它走「臉放不下」那條：把眼距放大，M 加大
 const es=mat.eyeSize;mat.eyeSize=3.2;o.eyeNoFit=best(()=>eyePose(1/60),6);mat.eyeSize=es;
 o.css=best(()=>{const css=getComputedStyle(document.documentElement);for(let i=0;i<6;i++)css.getPropertyValue('--body').trim()},50);
 return o}'''
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    for d in (0,4.5): print(d,pg.evaluate(JS,d))
    b.close()
srv.shutdown()
