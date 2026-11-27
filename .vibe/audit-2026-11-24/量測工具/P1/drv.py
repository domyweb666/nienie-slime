# drv.py: 共用：開伺服器、開頁、注入 h.js
import sys, json, threading, http.server, socketserver, functools, os, time
sys.stdout.reconfigure(encoding='utf-8')
BASE='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/P1work'
WEB=BASE+'/copy/prototype/web'
CH='C:/Program Files/Google/Chrome/Application/chrome.exe'
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*x): pass
class SV(socketserver.ThreadingTCPServer):
    allow_reuse_address=True; request_queue_size=128; daemon_threads=True
    def handle_error(self,*x): pass
def serve(port=8985):
    import socket
    s=socket.socket()
    try:
        s.settimeout(.5); s.connect(('127.0.0.1',port)); s.close(); return None
    except OSError:
        pass
    srv=SV(('127.0.0.1',port),functools.partial(Q,directory=WEB));threading.Thread(target=srv.serve_forever,daemon=True).start();return srv
INIT='window.__raf=window.requestAnimationFrame;window.requestAnimationFrame=function(cb){window.__cb=cb;return 1};'
def page(p,port=8985,q=''):
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio','--disable-background-timer-throttling'])
    ctx=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True)
    ctx.add_init_script(INIT)
    pg=ctx.new_page();errs=[];pg.on('pageerror',lambda e:errs.append(str(e)[:300]))
    pg.set_default_timeout(0)
    for k in range(8):
        try:
            pg.goto(f'http://127.0.0.1:{port}/index.html{q}',wait_until='load');break
        except Exception as e:
            errs.clear();serve(port);time.sleep(1.5)
    pg.wait_for_timeout(1200)
    r=pg.evaluate(open(BASE+'/run/h.js',encoding='utf-8').read());assert r=='ok',r
    return b,pg,errs
