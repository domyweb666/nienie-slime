# stx.py src(web夾) port out.json [gpu] [t70] [pre=js] [drop=T71,...]  整份自測（或只跑前言＋T70）。主控台訊息一起存。
import sys,json,time,os
HERE=os.path.dirname(os.path.abspath(__file__));sys.path.insert(0,HERE)
from drv import *
from playwright.sync_api import sync_playwright
src,port,out=sys.argv[1],int(sys.argv[2]),sys.argv[3];opt=sys.argv[4:]
pre=next((o[4:] for o in opt if o.startswith('pre=')),'');stf=next((o[4:] for o in opt if o.startswith('stf=')),src+'/selftest.js')
def_mut=next((o[4:] for o in opt if o.startswith('mut=')),'')
code=open(stf,encoding='utf-8').read().replace('\r\n','\n')
if 't70' in opt:
    L=code.split('\n');t1=next(i for i,l in enumerate(L) if l.startswith('  // T1 '));s=next(i for i,l in enumerate(L) if l.startswith('  // T70 v2.61 破皮'))
    code='\n'.join(L[:t1]+['  res.PASS={};']+L[s:]);code=code.replace('restoreClock(clock00);','if(0)restoreClock(clock00);',1)
if 'not70' in opt:
    k="    try { WALK.items.length = 0; WALK.fall.length = 0; WALK.leave.length = 0; WALK.stuck = null; fresh(DEF, 70);"
    if code.count(k)==1: code=code.replace(k,"    try { throw new Error('略過');"+k[9:])
if def_mut:
    a,b=def_mut.split('=>');assert code.count(a)==1,(code.count(a),a);code=code.replace(a,b)
srv=serve(src,port);t0=time.time();msgs=[]
with sync_playwright() as p:
    args=['--mute-audio','--disable-background-timer-throttling']+(['--use-angle=d3d11','--enable-gpu','--ignore-gpu-blocklist'] if 'gpu' in opt else [])
    b=p.chromium.launch(executable_path=CH,headless=True,args=args)
    pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True,is_mobile=True).new_page();pg.set_default_timeout(0)
    errs=[];pg.on('pageerror',lambda e:errs.append(str(e)[:300]));pg.on('console',lambda m:msgs.append([m.type,m.text[:300]]) if m.type in('error','warning') else None)
    pg.on('requestfailed',lambda r:msgs.append(['reqfailed',r.url[-120:]+' '+str(r.failure)+' t+%d'%(time.time()-t0)]))
    pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(2500)
    gl=pg.evaluate("(()=>{try{const g=document.createElement('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return g.getParameter(e.UNMASKED_RENDERER_WEBGL)}catch(_){return String(_)}})()")
    r=pg.evaluate('async ([c,q])=>{if(q)(0,eval)(q);const r=await (0,eval)(c);return JSON.parse(JSON.stringify(r))}',[code,pre]);b.close()
r['_meta']={'src':src,'secs':round(time.time()-t0),'gl':gl,'errs':errs,'msgs':msgs,'opt':opt}
json.dump(r,open(out,'w',encoding='utf-8'),ensure_ascii=False)
print(os.path.basename(out),round(time.time()-t0),'s 項',len(r['PASS']),'紅',[k for k,v in r['PASS'].items() if not v],'ALL',r.get('ALL_PASS'),'KI',json.dumps(r.get('KNOWN_ISSUES')),'errs',errs[:3],'msgs',msgs[:4],gl,flush=True)
for k,v in (r.get('T70_skin') or {}).items(): print('   ',k,json.dumps(v,ensure_ascii=False),flush=True)
srv.shutdown()
