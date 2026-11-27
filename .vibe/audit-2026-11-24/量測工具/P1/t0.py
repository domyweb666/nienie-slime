import sys;sys.path.insert(0,'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/P1work/run')
from drv import *
from playwright.sync_api import sync_playwright
serve()
with sync_playwright() as p:
    b,pg,errs=page(p)
    print(pg.evaluate("({W,H:innerHeight,R,N,nb:bnd.length,slime:SLIMES[SLIME].id,eyes:mat.eyes,brain:mat.brain,mood:mat.mood,brMem:mat.brMem,bg:VIEW.bg,one:mat.one,sill:SILL.on,g:SILL.g&&{l:SILL.g.l,r:SILL.g.r,bx:SILL.g.bx,fl:SILL.g.fl},reduced:REDUCED,props:PROPS.map(p=>p.im),hang:Object.keys(HANG).filter(k=>HANG[k].on)})"))
    t0=time.time();pg.evaluate("OBS.reset({seed:1});OBS.idle(60)");print('60s sim took',time.time()-t0)
    r=pg.evaluate("OBS.take()");print(len(r['E']),len(r['S']));print(r['S'][:3]);
    for e in r['E'][:70]: print(e)
    print(errs);b.close()
