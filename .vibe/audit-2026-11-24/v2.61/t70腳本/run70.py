# run70.py srcdir port out [pre] [full]：把 T70 插進 HEAD 的 selftest；不帶 full 時只留前言＋T70＋收尾
D='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/t70/'
import sys,json,time
sys.path.insert(0,D+'tool')
from srv import *
from playwright.sync_api import sync_playwright
src,port,out=sys.argv[1],int(sys.argv[2]),sys.argv[3];pre=sys.argv[4] if len(sys.argv)>4 else '';full=len(sys.argv)>5 and sys.argv[5]=='full'
L=open(D+'v61/prototype/web/selftest.js',encoding='utf-8').read().replace('\r\n','\n').split('\n')
t70=open(D+'t70.js',encoding='utf-8').read().rstrip('\n').split('\n')
t1=next(i for i,l in enumerate(L) if l.startswith('  // T1 '));end=next(i for i,l in enumerate(L) if l=='  draw();')
code='\n'.join(L[:end]+t70+L[end:]) if full else '\n'.join(L[:t1]+['  res.PASS={};']+t70+L[end:])
if not full: code=code.replace('restoreClock(clock00);','if(0)restoreClock(clock00);',0)
srv=serve(D+src+'/prototype/web',port);t0=time.time()
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
    pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True,is_mobile=True).new_page();pg.set_default_timeout(0)
    errs=[];pg.on('pageerror',lambda e:errs.append(str(e)[:200]))
    pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(2500)
    if pre: pg.evaluate(pre)
    v0=pg.evaluate('()=>JSON.stringify([VIEW,SLIME,mat,window.KPIOS])')
    r=pg.evaluate('async c=>{const r=await (0,eval)(c);return JSON.parse(JSON.stringify(r))}',code)
    v1=pg.evaluate('()=>JSON.stringify([VIEW,SLIME,mat,window.KPIOS])')
    b.close()
json.dump(r,open(D+'out/'+out+'.json','w',encoding='utf-8'),ensure_ascii=False)
print(out,round(time.time()-t0),'s n',len(r['PASS']),'fail',[k for k,v in r['PASS'].items() if not v],'還原',v0==v1,'errs',errs[:3])
if v0!=v1: print(v0[:300],v1[:300])
for k,v in r['T70_skin'].items(): print('  ',k,json.dumps(v,ensure_ascii=False))
srv.shutdown()
