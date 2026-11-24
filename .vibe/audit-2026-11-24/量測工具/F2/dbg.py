from common import *
from playwright.sync_api import sync_playwright
port=freeport();srv=serve(port)
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    pg.evaluate(open(BASE+'/tools/skinmodes.js',encoding='utf-8').read())
    pg.evaluate(open(BASE+'/tools/paired.js',encoding='utf-8').read())
    t0=time.time()
    r=pg.evaluate('async (o)=>{const r=await RUNP(o);return {k:Object.keys(r),c:Object.keys(r.caps||{}),n:r.out.length,rows:r.out[0].rows.length,t:typeof r.caps}}',{'fn':'TWO','seeds':[1],'over':{},'modes':[0,1,2],'slime':None,'every':6})
    print(r,time.time()-t0,errs);b.close()
srv.shutdown()
