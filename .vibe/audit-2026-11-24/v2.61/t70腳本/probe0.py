D='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/t70/'
import sys,json
sys.path.insert(0,D+'tool')
from srv import *
from playwright.sync_api import sync_playwright
srv=serve(D+'v61/prototype/web',9101)
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio']);cx=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True);pg=cx.new_page()
    pg.goto('http://127.0.0.1:9101/index.html',wait_until='load');pg.wait_for_timeout(2500)
    print(pg.evaluate("()=>{const o={};for(const k in mat)if(JSON.stringify(mat[k])!==JSON.stringify(PRESETS[curMat][k]))o[k]=[mat[k],PRESETS[curMat][k]];return JSON.stringify({SLIME,name:SLIMES[SLIME].name,curMat,o,VIEW,n:N,persona:SLIMES[SLIME]})}"))
    print(pg.evaluate("()=>JSON.stringify([PRESETS.clay.limbs,PRESETS.clay.bodySize,PRESETS.clay.sill,PRESETS.clay.eyes,PRESETS.clay.intro,SEED])"))
    b.close()
srv.shutdown()
