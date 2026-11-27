import sys,json,time
from drv import *
from playwright.sync_api import sync_playwright
src,port,out=sys.argv[1],int(sys.argv[2]),sys.argv[3];srv=serve(src,port);t0=time.time()
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
    pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True,is_mobile=True).new_page();pg.set_default_timeout(0)
    errs=[];pg.on('pageerror',lambda e:errs.append(str(e)[:200]))
    pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(2500)
    code=open(src+'/selftest.js',encoding='utf-8').read();k="    try { WALK.items.length = 0; WALK.fall.length = 0; WALK.leave.length = 0; WALK.stuck = null; fresh(DEF, 70);"
    assert code.count(k)==1;code=code.replace(k,"    try { throw new Error('略過');"+k[9:])
    r=pg.evaluate('async c=>{const r=await (0,eval)(c);return JSON.parse(JSON.stringify(r))}',code);b.close()
json.dump(r,open(out,'w',encoding='utf-8'),ensure_ascii=False)
print(out,round(time.time()-t0),'s n',len(r['PASS']),'fail',[k for k,v in r['PASS'].items() if not v],'errs',errs[:3],flush=True);srv.shutdown()
