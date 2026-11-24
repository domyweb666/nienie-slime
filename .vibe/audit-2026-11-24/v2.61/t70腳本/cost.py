D='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/t70/'
import sys,json
sys.path.insert(0,D+'tool')
from srv import *
from playwright.sync_api import sync_playwright
srv=serve(D+'v61/prototype/web',9105)
with sync_playwright() as p:
    for mob in (True,False):
        b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
        pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True,is_mobile=mob).new_page()
        pg.goto('http://127.0.0.1:9105/index.html',wait_until='load');pg.wait_for_timeout(2500)
        print(mob,pg.evaluate("""()=>{window.requestAnimationFrame=()=>0;const T=(n,f)=>{const a=performance.now();for(let i=0;i<n;i++)f();return +((performance.now()-a)/n).toFixed(2)};const gl=JEL.gl,w=JEL.h2.w,h=JEL.h2.h,buf=new Float32Array(w*h*4);const rd=()=>{gl.bindFramebuffer(gl.FRAMEBUFFER,JEL.h2.f);gl.readPixels(0,0,w,h,gl.RGBA,gl.FLOAT,buf);gl.bindFramebuffer(gl.FRAMEBUFFER,null)};
        const o={update:T(60,()=>update(1/60)),draw_read:T(60,()=>{draw();rd()}),read_only:T(30,rd)};return JSON.stringify(o)+gl.getParameter(gl.getExtension('WEBGL_debug_renderer_info').UNMASKED_RENDERER_WEBGL)}"""))
        b.close()
srv.shutdown()
