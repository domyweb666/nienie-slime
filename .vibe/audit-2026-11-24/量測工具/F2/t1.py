from common import *
from playwright.sync_api import sync_playwright
srv=serve(8962)
os.makedirs(BASE+'/shots',exist_ok=True)
with sync_playwright() as p:
    b,pg,errs=page(p,8962)
    r=pg.evaluate('''()=>{const o=[];F2.fresh(1);F2.resetPrev();const bi=F2.edgePt(0,-1);const c=globalC;const [sx,sy]=F2.scr(X[bi]+(c.xc-X[bi])*.25,Y[bi]+(c.yc-Y[bi])*.25);
     F2.ev('pointerdown',1,sx,sy);for(let i=0;i<4;i++)update(F2.DT);
     const t0=performance.now();
     for(let s=1;s<=40;s++){const [ex,ey]=F2.clampS(sx,sy-5*R*s/40);F2.ev('pointermove',1,ex,ey);update(F2.DT);if(s%4===0)o.push({s,...F2.measure()})}
     for(let s=1;s<=60;s++){update(F2.DT);if(s%10===0)o.push({h:s,...F2.measure()})}
     o.push({ms:performance.now()-t0});
     return o}''')
    for q in r: print(fmt(q))
    pg.screenshot(path=BASE+'/shots/t1_hold.png')
    print(errs);b.close()
srv.shutdown()
