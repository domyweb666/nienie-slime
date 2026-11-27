import sys,functools,threading,time,json,os
sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0,r'E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/tools/web-bench')
from st import SV,Q,CH
BASE=r'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work'
WEB=BASE+'/prototype/web'
def serve(port,web=WEB):
    srv=SV(('127.0.0.1',port),functools.partial(Q,directory=web));threading.Thread(target=srv.serve_forever,daemon=True).start();return srv
def page(p,port,dpr=2,url='/index.html',args=None,w=393,h=852,lib=True):
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio']+(args or []))
    pg=b.new_context(viewport={'width':w,'height':h},device_scale_factor=dpr,has_touch=True).new_page()
    errs=[];pg.on('pageerror',lambda e:errs.append(str(e)))
    pg.set_default_timeout(0)
    for k in range(5):
        try: pg.goto(f'http://127.0.0.1:{port}{url}',wait_until='load');break
        except Exception as e:
            if k==4: raise
            time.sleep(2)
    pg.wait_for_timeout(1800)
    if lib: pg.evaluate(open(BASE+'/tools/f2lib.js',encoding='utf-8').read())
    return b,pg,errs
def fmt(q): return {k:(round(v,2) if isinstance(v,float) else v) for k,v in q.items()}

def freeport():
    import socket
    k=socket.socket();k.bind(('127.0.0.1',0));n=k.getsockname()[1];k.close();return n
