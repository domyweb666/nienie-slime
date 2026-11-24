import sys,threading,http.server,socketserver,functools
sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0,r"C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/p4/scripts")
from h import SV,Q,WEB,CH,PRE
from playwright.sync_api import sync_playwright
OUT=r"C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/p4/"
JS=PRE.replace('__SEED__','3')+r'''
 const mk=(ang)=>{Math.random=seeded(9);setup();fxReset();impReset();brainReset();t=50;lastTouch=t-20;SLP.lastAny=t-20;steps(150);const y0=Math.max(...bnd.map(i=>Y[i])),x0=Math.min(...bnd.map(i=>X[i])),x1=Math.max(...bnd.map(i=>X[i])),yt=Math.min(...bnd.map(i=>Y[i]));
  startSniff(ang,mat.podLen,1.2,1.5,.8);LIFE.st='look';LIFE.until=t+9;LIFE.looks=0;LIFE.noGo=true;steps(110);const y1=Math.max(...bnd.map(i=>Y[i])),a=Math.min(...bnd.map(i=>X[i])),b=Math.max(...bnd.map(i=>X[i])),c=Math.min(...bnd.map(i=>Y[i]));
  return{floor:+SILL.g.fl.toFixed(1),bottom0:+y0.toFixed(1),bottom1:+y1.toFixed(1),left:+(x0-a).toFixed(1),right:+(b-x1).toFixed(1),top:+(yt-c).toFixed(1)}};
 const r={};r.down=mk(Math.PI/2);draw();window.__r=r;return r;}'''
srv=SV(('127.0.0.1',0),functools.partial(Q,directory=WEB));port=srv.server_address[1];threading.Thread(target=srv.serve_forever,daemon=True).start()
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
    pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=1,has_touch=True).new_page();pg.set_default_timeout(0)
    pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(1500)
    print(pg.evaluate(JS));pg.screenshot(path=OUT+'sniff_down.png')
    print(pg.evaluate(JS.replace("mk(Math.PI/2)","mk(-Math.PI/2*.7)")));pg.screenshot(path=OUT+'sniff_up.png')
    b.close()
srv.shutdown()
