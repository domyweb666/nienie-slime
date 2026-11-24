# usage: h.py <js file> [procs-seeds e.g. 1,2,3]  -> runs js in a fresh page per seed; js gets __SEED__
import sys,json,threading,http.server,socketserver,functools,multiprocessing as mp,time,os
sys.stdout.reconfigure(encoding='utf-8')
CH='C:/Program Files/Google/Chrome/Application/chrome.exe'
WEB=r'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/p4/src/prototype/web'
PRE=r'''
async()=>{
 const SEED=__SEED__;
 window.requestAnimationFrame=()=>0;
 await new Promise(r=>setTimeout(r,150));
 try{IMPSV.noSave=true;WALK.noSave=true}catch(e){}
 const seeded=s=>()=>{s|=0;s=s+0x6D2B79F5|0;let t=Math.imul(s^s>>>15,1|s);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296};
 if(SFX&&SFX.frame)SFX.frame=()=>{};
 Math.random=seeded(1000+SEED*7919);
 const DT=1/60;const steps=n=>{for(let i=0;i<n;i++)update(DT)};
 const ev=(type,id,x,y)=>cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}));
 const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
'''
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*x): pass
class SV(socketserver.ThreadingTCPServer):
    allow_reuse_address=True; request_queue_size=256; daemon_threads=True
    def handle_error(self,*x): pass
def run(a):
    js,port=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
        pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True).new_page()
        errs=[];pg.on('pageerror',lambda e:errs.append(str(e)[:200]))
        pg.set_default_timeout(0)
        pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(1200)
        r=pg.evaluate(js);b.close();return r if not errs else {'r':r,'err':errs[:3]}
if __name__=='__main__':
    body=open(sys.argv[1],encoding='utf-8').read();seeds=[int(x) for x in (sys.argv[2] if len(sys.argv)>2 else '1').split(',')]
    out=sys.argv[3] if len(sys.argv)>3 else None
    srv=SV(('127.0.0.1',0),functools.partial(Q,directory=WEB));port=srv.server_address[1];threading.Thread(target=srv.serve_forever,daemon=True).start()
    jobs=[(PRE.replace('__SEED__',str(s))+body+'\n}',port) for s in seeds];t0=time.time()
    with mp.Pool(min(len(jobs),6)) as P: R=P.map(run,jobs,chunksize=1)
    if out: json.dump(R,open(out,'w',encoding='utf-8'),ensure_ascii=False)
    for s,r in zip(seeds,R): print(s,json.dumps(r,ensure_ascii=False)[:2500])
    print('secs',round(time.time()-t0));srv.shutdown()
