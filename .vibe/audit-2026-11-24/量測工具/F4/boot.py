import sys, json, threading, http.server, socketserver, functools, time
sys.stdout.reconfigure(encoding='utf-8')
CH='C:/Program Files/Google/Chrome/Application/chrome.exe'
WEB=r'C:\Users\fcharlie\AppData\Local\Temp\claude\667dbbd50c5b7948\415881cf-6a7b-41c2-85af-00bf46311a7d\scratchpad\audit\f4src\prototype\web'
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*x): pass
class SV(socketserver.ThreadingTCPServer):
    allow_reuse_address=True; request_queue_size=256; daemon_threads=True
    def handle_error(self,*x): pass
def serve(port=8971):
    srv=SV(('127.0.0.1',port),functools.partial(Q,directory=WEB)); threading.Thread(target=srv.serve_forever,daemon=True).start(); return srv
if __name__=='__main__':
    srv=serve()
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio','--autoplay-policy=no-user-gesture-required'])
        pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True).new_page()
        errs=[];pg.on('pageerror',lambda e:errs.append(str(e)))
        pg.goto('http://127.0.0.1:8971/index.html',wait_until='load');pg.wait_for_timeout(3000)
        r=pg.evaluate('''()=>({W,H,R,N,DPR,cx:globalC.xc,cy:globalC.yc,nb:bnd.length,slime:SLIMES[SLIME].id,mat:SLIMES[SLIME].mat,view:VIEW,sill:SILL.on,plane:SILL.plane,g:SILL.g&&{l:SILL.g.l,r:SILL.g.r,fl:SILL.g.fl,gx:SILL.g.gx,jr:SILL.g.jr,gy:SILL.g.gy,bt:SILL.g.bt},cam:CAM,eyes:mat.eyes,props:PROPS.map(p=>({im:p.im,x:p.x,y:p.y,w:p.w,h:p.h})),sfx:!!SFX,ctx:SFX&&SFX.ctx&&SFX.ctx.state,bufs:SFX&&Object.fromEntries(Object.entries(SFX.buf).map(([k,v])=>[k,v.length]))})''')
        print(json.dumps(r,ensure_ascii=False,indent=0)[:2500]); print(errs)
        b.close()
    srv.shutdown()
