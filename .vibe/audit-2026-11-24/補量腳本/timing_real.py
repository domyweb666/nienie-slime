import sys,json,collections,random
D='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/combo/'
sys.path.insert(0,D+'tool')
from srv import *
from ana import tot,mx
from playwright.sync_api import sync_playwright
B='cg:1,bl:1.35,gv:1';C='cr:1,iw:1,cg:1,bl:1.35,up:3,gv:1,fl:1.35,vc:6'
CO={'a':'F1X={};JELX.mode=0','g':'F1X={};JELX.mode=9','b':'F1X={%s};JELX.mode=9'%B,'c':'F1X={%s};JELX.mode=9'%C,'d':'F1X={%s,hs:1};JELX.mode=9'%C,'e':'F1X={%s,kp:1};JELX.mode=9'%B}
cells=json.load(open(D+'c_rnd.json',encoding='utf-8'))[:20]+json.load(open(D+'c_gone.json',encoding='utf-8'))[::4]
srv=serve(D+'pat/prototype/web',8996);acc=collections.defaultdict(list)
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
    pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True).new_page();pg.set_default_timeout(0)
    pg.goto('http://127.0.0.1:8996/index.html',wait_until='load');pg.wait_for_timeout(2500)
    pg.evaluate(open(D+'tool/probe.js',encoding='utf-8').read());pg.evaluate('PB.init()');pg.evaluate('PB.over={};PB.snapOn=false;PB.deep=true')
    pg.evaluate("(()=>{const d0=draw,px=new Uint8Array(4);window.__d=[0,0,0];draw=function(){const t=performance.now();d0();const u=performance.now();const gl=JEL.gl;gl.bindFramebuffer(gl.FRAMEBUFFER,null);gl.readPixels(0,0,1,1,gl.RGBA,gl.UNSIGNED_BYTE,px);const w=performance.now();__d[0]+=u-t;__d[1]+=w-t;__d[2]++}})()")
    print(pg.evaluate("(()=>{const g=JEL.gl,e=g.getExtension('WEBGL_debug_renderer_info');return e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):'?'})()"))
    ks=list(CO)
    for n,c in enumerate(cells):
        for k in ks[n%6:]+ks[:n%6]:
            pg.evaluate(CO[k]);pg.evaluate('__d[0]=__d[1]=__d[2]=0');r=pg.evaluate('c=>PB.run(c)',c);d=pg.evaluate('__d')
            acc[k].append((tot(r,'msSum')/max(1,tot(r,'fr')),d[0]/max(1,d[2]),d[1]/max(1,d[2]),mx(r,'msMax')))
    b.close()
srv.shutdown()
for k in CO:
    v=acc[k];m=lambda i:sum(x[i] for x in v)/len(v)
    med=lambda i:sorted(x[i] for x in v)[len(v)//2]
    print(k,len(v),'update均%.2f 中位%.2f | draw JS均%.2f 中位%.2f | draw+讀1點 均%.2f 中位%.2f | 最慢一格中位%.1f'%(m(0),med(0),m(1),med(1),m(2),med(2),med(3)))
