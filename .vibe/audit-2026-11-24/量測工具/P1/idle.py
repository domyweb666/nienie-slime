# idle.py <out> <minutes> <jobs json>：無人觀察。job: {name, reset:{...}}
import sys;sys.path.insert(0,'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/P1work/run')
from drv import *
from playwright.sync_api import sync_playwright
import multiprocessing as mp
def run(a):
    out,minutes,job,port=a
    with sync_playwright() as p:
        b,pg,errs=page(p,port,job.get('q',''))
        pg.evaluate('o=>OBS.reset(o)',job['reset'])
        E=[];S=[];t0=time.time()
        meta=pg.evaluate("({R,slime:SLIMES[SLIME].id,mat:curMat,restMul:mat.restMul,wRate:mat.wRate,trRate:mat.trRate,e4Mul:mat.e4Mul,dash:mat.dash,eyeSize:mat.eyeSize,g:{l:SILL.g.l,r:SILL.g.r,bx:SILL.g.bx,fl:SILL.g.fl},bg:VIEW.bg,tr:IMP.tr})")
        for m in range(minutes):
            pg.evaluate('OBS.idle(60)');r=pg.evaluate('OBS.take()');E+=r['E'];S+=r['S']
        b.close()
    fn=f"{BASE}/data/{out}-{job['name']}.json";json.dump({'meta':meta,'job':job,'E':E,'S':S,'errs':errs},open(fn,'w',encoding='utf-8'),ensure_ascii=False)
    return job['name'],len(E),len(S),round(time.time()-t0),errs[:2]
if __name__=='__main__':
    out=sys.argv[1];minutes=int(sys.argv[2]);jobs=json.loads(open(sys.argv[3],encoding='utf-8').read());procs=int(sys.argv[4]) if len(sys.argv)>4 else 3
    os.makedirs(BASE+'/data',exist_ok=True)
    srv=serve()
    with mp.Pool(procs) as P:
        for r in P.imap_unordered(run,[(out,minutes,j,8985) for j in jobs]): print(r,flush=True)
