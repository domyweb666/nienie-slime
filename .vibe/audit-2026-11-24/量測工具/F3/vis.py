import sys,json,threading,functools,http.server,socketserver,os
sys.stdout.reconfigure(encoding='utf-8')
CH='C:/Program Files/Google/Chrome/Application/chrome.exe'
HERE=os.path.dirname(os.path.abspath(__file__))
WEB=sys.argv[1] if len(sys.argv)>1 else os.path.join(os.path.dirname(HERE),'src','prototype','web')
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class SV(socketserver.ThreadingTCPServer):
    allow_reuse_address=True; request_queue_size=128; daemon_threads=True
    def handle_error(self,*x): pass
def evaljs(js,cfg,port=8971):
    srv=SV(('127.0.0.1',port),functools.partial(Q,directory=WEB));threading.Thread(target=srv.serve_forever,daemon=True).start()
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
        pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True).new_page()
        errs=[];pg.on('pageerror',lambda e:errs.append(str(e)));pg.set_default_timeout(0)
        pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(1500)
        r=pg.evaluate(js,cfg);b.close()
    srv.shutdown()
    if errs: print('ERR',errs[:3])
    return r
if __name__=='__main__':
    js=open(os.path.join(HERE,'vis.js'),encoding='utf-8').read()
    jobs=[]
    for nm,o in (('中間',{}),('偏右0.5R',{'ox':.5}),('偏上0.6R',{'oy':-.6})):
        jobs.append(dict(name='按 '+nm,n=60,**o))
    r=evaljs(js,dict(occ=48,jobs=jobs))
    print('按下去：外框相對沒按的最大位移（點），括號是手指遮住 48 點半徑以外看得到的；R=%.1f'%r[0]['R'])
    for x in r:
        rows=x['rows']; g=lambda k:'%d(%d)'%(0,0)
        t2=next((i+1 for i,q in enumerate(rows) if q[1]>=2),None); t2a=next((i+1 for i,q in enumerate(rows) if q[0]>=2),None)
        print('%-10s 模式 %s'%(x['name'],rows[0][6]),' '.join('第%d格 %.1f(%.1f)'%(k,rows[k-1][0],rows[k-1][1]) for k in (1,2,3,6,12,24,48)),'| 到2點：全部 %s 格、看得到 %s 格'%(t2a,t2),'| 凹痕深 第1格 %.2f 第6格 %.2f'%(rows[0][8],rows[5][8]))
