# usage: run.py exp.js out.json [--shots dir]
import sys, json, threading, http.server, socketserver, functools, os, time
sys.stdout.reconfigure(encoding='utf-8')
CH='C:/Program Files/Google/Chrome/Application/chrome.exe'
WEB='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/P2/src3/prototype/web'
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*x): pass
class SV(socketserver.ThreadingTCPServer):
    allow_reuse_address=True; request_queue_size=256; daemon_threads=True
    def handle_error(self,*x): pass
def main():
    js=open('lib.js',encoding='utf-8').read()+'\n'+open(sys.argv[1],encoding='utf-8').read()
    out=sys.argv[2]; q=sys.argv[3] if len(sys.argv)>3 else ''
    srv=SV(('127.0.0.1',0),functools.partial(Q,directory=WEB)); port=srv.server_address[1]
    threading.Thread(target=srv.serve_forever,daemon=True).start()
    from playwright.sync_api import sync_playwright
    t0=time.time()
    with sync_playwright() as p:
        b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
        pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True).new_page()
        errs=[];pg.on('pageerror',lambda e:errs.append(str(e)))
        pg.set_default_timeout(0)
        pg.goto(f'http://127.0.0.1:{port}/index.html'+q,wait_until='load');pg.wait_for_timeout(2500)
        r=pg.evaluate('(async()=>{'+js+'\n})()')
        json.dump(r,open(out,'w',encoding='utf-8'),ensure_ascii=False,indent=1)
        b.close()
    print('errs',errs[:3],'secs',round(time.time()-t0))
    srv.shutdown()
main()
