import sys;sys.path.insert(0,'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/P1work/run')
from drv import *
import base64
from playwright.sync_api import sync_playwright
serve();os.makedirs(BASE+'/shot',exist_ok=True)
with sync_playwright() as p:
    b,pg,errs=page(p)
    pg.evaluate("draw()");pg.wait_for_timeout(1500)
    pg.evaluate("OBS.reset({seed:3,tr:0})")
    for T in (1,16,30,12,40,30):
        pg.evaluate(f"OBS.idle({T});draw()");tt=pg.evaluate("t");k=pg.evaluate("OBS.klass()")
        d=pg.evaluate("cv.toDataURL('image/jpeg',.8)");open(f"{BASE}/shot/idle-{int(tt)}-{k}.jpg",'wb').write(base64.b64decode(d.split(',')[1]));print(tt,k,flush=True)
    b.close()
