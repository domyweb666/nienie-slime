# own.py <out> <jobs json> <procs>：飼主。job: {name, owner, sec, reset:{...}, after}
import sys;sys.path.insert(0,'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/P1work/run')
from drv import *
from playwright.sync_api import sync_playwright
import multiprocessing as mp
def run(a):
    out,job,port=a
    with sync_playwright() as p:
        b,pg,errs=page(p,port,job.get('q',''))
        print(pg.evaluate(open(BASE+'/run/own.js',encoding='utf-8').read()))
        pg.evaluate('o=>OBS.reset(o)',job['reset']);pg.evaluate('s=>OBS.ownerSeed(s)',job.get('oseed',7))
        E=[];S=[];t0=time.time()
        if job.get('warm'): pg.evaluate(f"OBS.idle({job['warm']})")
        left=job['sec']
        while left>0:
            c=min(60,left);pg.evaluate(f"OBS.{job['owner']}({c})");r=pg.evaluate('OBS.take()');E+=r['E'];S+=r['S'];left-=c
        mid=pg.evaluate("({t,m:BRAIN.m,tr:IMP.tr,w:IMP.w,cell:BMEM.cell.slice(),side:BMEM.side})")
        for m in range(job.get('after',0)):
            pg.evaluate('OBS.idle(60)');r=pg.evaluate('OBS.take()');E+=r['E'];S+=r['S']
        b.close()
    fn=f"{BASE}/data/{out}-{job['name']}.json";json.dump({'job':job,'mid':mid,'E':E,'S':S,'errs':errs},open(fn,'w',encoding='utf-8'),ensure_ascii=False)
    return job['name'],len(E),len(S),round(time.time()-t0),mid,errs[:2]
if __name__=='__main__':
    out=sys.argv[1];jobs=json.loads(open(sys.argv[2],encoding='utf-8').read());procs=int(sys.argv[3]) if len(sys.argv)>3 else 3
    os.makedirs(BASE+'/data',exist_ok=True);srv=serve()
    with mp.Pool(procs) as P:
        for r in P.imap_unordered(run,[(out,j,8985) for j in jobs]): print(r,flush=True)
