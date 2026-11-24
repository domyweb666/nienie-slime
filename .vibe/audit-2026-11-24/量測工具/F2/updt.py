from common import *
from playwright.sync_api import sync_playwright
port=freeport();srv=serve(port)
JS='''(d)=>{F2.fresh(1,{shine:0,opaque:.9});const c=globalC,bi=F2.edgePt(0.15,-1),[sx,sy]=F2.scr(X[bi]+(c.xc-X[bi])*.25,Y[bi]+(c.yc-Y[bi])*.25);if(d>0){F2.ev('pointerdown',1,sx,sy);for(let i=0;i<4;i++)update(F2.DT);let e=[sx,sy];for(let s=1;s<=50;s++){e=F2.clampS(sx-.2*d*R*s/50,sy-d*R*s/50);F2.ev('pointermove',1,e[0],e[1]);update(F2.DT)}for(let i=0;i<40;i++)update(F2.DT)}
 const u=[],w=[];for(let i=0;i<200;i++){const t0=performance.now();update(1/60);const t1=performance.now();draw();const t2=performance.now();u.push(t1-t0);w.push(t2-t1)}const q=(a,p)=>a.slice().sort((x,y)=>x-y)[Math.floor(a.length*p)];return {N,update:[q(u,.1),q(u,.5),q(u,.9)].map(v=>+v.toFixed(2)),draw:[q(w,.1),q(w,.5),q(w,.9)].map(v=>+v.toFixed(2))}}'''
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    for d in (0,4.5): print(d,pg.evaluate(JS,d))
    b.close()
srv.shutdown()
