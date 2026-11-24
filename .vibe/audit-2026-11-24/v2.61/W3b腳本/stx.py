# stx.py src port out.json selftest.js [k=v,k=v] [skip=T70,T71]
import sys,json,time,os
from drv import *
from playwright.sync_api import sync_playwright
src,port,out,stf=sys.argv[1],int(sys.argv[2]),sys.argv[3],sys.argv[4]
pin=sys.argv[5] if len(sys.argv)>5 else '';skip=sys.argv[6] if len(sys.argv)>6 else 'T70'
srv=serve(src,port);t0=time.time()
code=open(stf,encoding='utf-8').read().replace('\r\n','\n')
if 'T70' in skip:
    k="    try { WALK.items.length = 0; WALK.fall.length = 0; WALK.leave.length = 0; WALK.stuck = null; fresh(DEF, 70);"
    assert code.count(k)==1;code=code.replace(k,"    try { throw new Error('略過');"+k[9:])
if 'T71' in skip:
    i=code.index('  // T71 v2.61 W3');j=code.index('  // T70 v2.61 破皮');code=code[:i]+code[j:]
pre=''
if pin:
    o={}
    for kv in pin.split(','):
        a,b=kv.split('=');o[a]=float(b)
    pre='{const P=%s;for(const k in PRESETS)Object.assign(PRESETS[k],P);Object.assign(mat,P);}'%json.dumps(o)
gpu=('gpu' in sys.argv)
with sync_playwright() as p:
    args=['--mute-audio','--disable-background-timer-throttling']+(['--use-angle=d3d11','--enable-gpu','--ignore-gpu-blocklist'] if gpu else [])
    b=p.chromium.launch(executable_path=CH,headless=True,args=args)
    pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True,is_mobile=True).new_page();pg.set_default_timeout(0)
    errs=[];pg.on('pageerror',lambda e:errs.append(str(e)[:200]))
    pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(2500)
    gl=pg.evaluate("(()=>{try{const g=document.createElement('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return g.getParameter(e.UNMASKED_RENDERER_WEBGL)}catch(_){return String(_)}})()")
    r=pg.evaluate('async ([c,q])=>{if(q)(0,eval)(q);const r=await (0,eval)(c);return JSON.parse(JSON.stringify(r))}',[code,pre]);b.close()
json.dump(r,open(out,'w',encoding='utf-8'),ensure_ascii=False)
print(out,round(time.time()-t0),'s n',len(r['PASS']),'fail',[k for k,v in r['PASS'].items() if not v],'errs',errs[:3],gl,flush=True);srv.shutdown()
