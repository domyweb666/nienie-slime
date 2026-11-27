# sr.py <out> <jobs json> <procs>：刺激反應（逐種存檔）
import sys;sys.path.insert(0,'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/P1work/run')
from drv import *
from playwright.sync_api import sync_playwright
import multiprocessing as mp
def run(a):
    out,job,port=a
    fn=f"{BASE}/data/{out}-{job['name']}.json"
    with sync_playwright() as p:
        b,pg,errs=page(p,port,job.get('q',''))
        pg.evaluate(open(BASE+'/run/own.js',encoding='utf-8').read());pg.evaluate(open(BASE+'/run/sr.js',encoding='utf-8').read())
        pg.evaluate('o=>OBS.reset(o)',job['reset']);pg.evaluate('s=>OBS.ownerSeed(s)',job.get('oseed',5))
        t0=time.time();res={}
        for s in job['stims']:
            res[s]=pg.evaluate('a=>OBS.sr(a[0],a[1],a[2],a[3])',[s,job['ctx'],job['n'],job.get('o',{})])
            json.dump({'job':job,'res':res,'errs':errs},open(fn,'w',encoding='utf-8'),ensure_ascii=False);print(job['name'],s,round(time.time()-t0),flush=True)
        b.close()
    return job['name'],round(time.time()-t0),errs[:2]
if __name__=='__main__':
    out=sys.argv[1];jobs=json.loads(open(sys.argv[2],encoding='utf-8').read());procs=int(sys.argv[3]) if len(sys.argv)>3 else 3
    os.makedirs(BASE+'/data',exist_ok=True);srv=serve()
    with mp.Pool(procs) as P:
        for r in P.imap_unordered(run,[(out,j,8985) for j in jobs]): print('DONE',r,flush=True)
