import sys;sys.path.insert(0,'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/P1work/run')
from drv import *
from playwright.sync_api import sync_playwright
serve()
with sync_playwright() as p:
    b,pg,errs=page(p);pg.evaluate(open(BASE+'/run/own.js',encoding='utf-8').read())
    for w,m in ((0,.15),(.3,-.2),(.6,-.5)):
        r=pg.evaluate("""([w,m])=>{OBS.reset({seed:91,tr:.1});OBS.ownerSeed(3);OBS.idle(5);IMP.w=w;BRAIN.m=BRAIN.mS=m;BMEM.cell.fill(0);const o=[];let lm=BRAIN.m,lw=IMP.w,ls=MOOD.scare;OBS.hook=()=>{if(Math.abs(BRAIN.m-lm)>.03||Math.abs(IMP.w-lw)>.02||MOOD.scare>ls+.05){o.push([+t.toFixed(2),'m',+lm.toFixed(3),+BRAIN.m.toFixed(3),'w',+lw.toFixed(3),+IMP.w.toFixed(3),'sc',+ls.toFixed(2),+MOOD.scare.toFixed(2),OBS.klass()])}lm=BRAIN.m;lw=IMP.w;ls=MOOD.scare};const t0=t;const [x,y]=OBS.bodyPt(0,-.15);OBS.rub(x,y,4,.28,1.4);OBS.idle(5);OBS.hook=null;return{t0,o,m:BRAIN.m,w:IMP.w,tr:IMP.tr}}""",[w,m])
        print('起始 戒',w,'心情',m,'→',round(r['m'],2),round(r['w'],2),'熟',round(r['tr'],2),'t0',round(r['t0'],1));[print('   ',x) for x in r['o'][:8]]
    b.close()
