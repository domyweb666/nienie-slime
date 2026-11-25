# drv.py srcdir port exp.js out.json [query]
import sys,json,os,time,threading,http.server,socketserver,functools,tempfile
sys.stdout.reconfigure(encoding='utf-8')
CH='C:/Program Files/Google/Chrome/Application/chrome.exe'
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*x): pass
    def end_headers(self):
        self.send_header('Cache-Control','no-store');super().end_headers()
class SV(socketserver.ThreadingTCPServer):
    allow_reuse_address=True; request_queue_size=256; daemon_threads=True
    def handle_error(self,*x): pass
INIT='window.__raf=window.requestAnimationFrame;window.requestAnimationFrame=function(cb){window.__cb=cb;return 1};'
def serve(web,port):
    srv=SV(('127.0.0.1',port),functools.partial(Q,directory=web));threading.Thread(target=srv.serve_forever,daemon=True).start();return srv
def page(p,port,q='',args=(),init=INIT):
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio','--disable-background-timer-throttling',*args])
    ctx=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True)
    if init: ctx.add_init_script(init)
    pg=ctx.new_page();errs=[];pg.on('pageerror',lambda e:errs.append(str(e)[:300]));pg.set_default_timeout(0)
    pg.goto(f'http://127.0.0.1:{port}/index.html{q}',wait_until='load');pg.wait_for_timeout(900)
    return b,pg,errs
if __name__=='__main__':
    src,port,exp,out=sys.argv[1],int(sys.argv[2]),sys.argv[3],sys.argv[4];q=sys.argv[5] if len(sys.argv)>5 else ''
    srv=serve(src,port);t0=time.time()
    from playwright.sync_api import sync_playwright
    here=os.path.dirname(os.path.abspath(__file__))
    js=open(here+'/lib.js',encoding='utf-8').read()+'\n'+open(exp,encoding='utf-8').read()
    with sync_playwright() as p:
        b,pg,errs=page(p,port,q)
        r=pg.evaluate('(async()=>{'+js+'\n})()')
        json.dump(r,open(out,'w',encoding='utf-8'),ensure_ascii=False);b.close()
    print(os.path.basename(exp),'errs',errs[:3],'secs',round(time.time()-t0));srv.shutdown()
