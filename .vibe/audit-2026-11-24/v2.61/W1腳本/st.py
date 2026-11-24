import sys,json,time
sys.path.insert(0,'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/w1/tool')
from srv import *
from playwright.sync_api import sync_playwright
src,port,out,pre=sys.argv[1],int(sys.argv[2]),sys.argv[3],sys.argv[4] if len(sys.argv)>4 else ''
srv=serve(src,port);t0=time.time()
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
    pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True,is_mobile=True).new_page();pg.set_default_timeout(0)
    errs=[];pg.on('pageerror',lambda e:errs.append(str(e)[:200]))
    pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(2500)
    if pre: pg.evaluate(pre)
    code=open(src+'/selftest.js',encoding='utf-8').read()
    r=pg.evaluate('async c=>{const r=await (0,eval)(c);return JSON.parse(JSON.stringify(r))}',code)
    chk=pg.evaluate("()=>typeof JELX==='undefined'?'no JELX':JSON.stringify([F1X,JELX.mode])")
    b.close()
json.dump(r,open(out,'w',encoding='utf-8'),ensure_ascii=False)
print(out.split('/')[-1],round(time.time()-t0),'s n',len(r['PASS']),'fail',[k for k,v in r['PASS'].items() if not v],'ver',chk,'errs',errs[:3],flush=True)
srv.shutdown()
