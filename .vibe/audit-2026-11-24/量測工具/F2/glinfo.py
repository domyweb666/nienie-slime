import sys,functools,threading,time
sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0,r'E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/tools/web-bench')
from st import SV,Q,CH
WEB=r'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/prototype/web'
srv=SV(('127.0.0.1',8961),functools.partial(Q,directory=WEB));threading.Thread(target=srv.serve_forever,daemon=True).start()
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    for args in (['--mute-audio'],['--mute-audio','--use-angle=d3d11','--enable-gpu','--ignore-gpu-blocklist']):
        b=p.chromium.launch(executable_path=CH,headless=True,args=args)
        pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True).new_page()
        errs=[];pg.on('pageerror',lambda e:errs.append(str(e)))
        pg.goto('http://127.0.0.1:8961/index.html',wait_until='load');pg.wait_for_timeout(2500)
        print(args, pg.evaluate('''()=>{const g=document.createElement('canvas').getContext('webgl2');const e=g&&g.getExtension('WEBGL_debug_renderer_info');return {r:g?g.getParameter(e?e.UNMASKED_RENDERER_WEBGL:g.RENDERER):null,skin:VIEW.skin,jel:!!JEL.gl,fail:JEL.fail,float:JEL.float,N,nb:bnd.length,R,W,H,DPR,slime:SLIMES[SLIME].id,mat:curMat,bg:VIEW.bg,win:VIEW.win,surf:SILL.surf}}'''), errs)
        b.close()
srv.shutdown()
