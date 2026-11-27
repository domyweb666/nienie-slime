import sys, json, threading, http.server, socketserver, functools, time
sys.stdout.reconfigure(encoding='utf-8')
CH='C:/Program Files/Google/Chrome/Application/chrome.exe'
WEB=sys.argv[1]; JS=open(sys.argv[2],encoding='utf-8').read(); PORT=int(sys.argv[3]) if len(sys.argv)>3 else 8931
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*x): pass
class SV(socketserver.ThreadingTCPServer):
    allow_reuse_address=True; daemon_threads=True; request_queue_size=256
    def handle_error(self,*x): pass
srv=SV(('127.0.0.1',PORT),functools.partial(Q,directory=WEB)); threading.Thread(target=srv.serve_forever,daemon=True).start()
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
    pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True).new_page()
    errs=[]; pg.on('pageerror',lambda e:errs.append(str(e)))
    pg.set_default_timeout(0)
    pg.goto(f'http://127.0.0.1:{PORT}/index.html',wait_until='load'); pg.wait_for_timeout(1500)
    t0=time.time(); r=pg.evaluate(JS); print(json.dumps(r,ensure_ascii=False),flush=True); print('secs',round(time.time()-t0,1), errs[:3], file=sys.stderr)
    import os; sys.stdout.flush(); sys.stderr.flush(); threading.Timer(8,lambda: os._exit(0)).start(); b.close(); os._exit(0)
srv.shutdown()
