# usage: runfz.py <func FZS|P4S|TWO> <n seeds> <seed0> <out.json> [over json] [web] [slime] [every]
from common import *
import multiprocessing as mp
def run(a):
    web,port,fn,seeds,over,slime,every,extra=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b,pg,errs=page(p,port)
        if extra: pg.evaluate(extra)
        pg.evaluate(open(BASE+'/tools/fzskin.js',encoding='utf-8').read())
        r=pg.evaluate('''async ([fn,seeds,over,slime,every])=>{if(slime!=null){chooseSlime(slime,false,false)}return await window[fn]({seeds,over,every})}''',[fn,seeds,over,slime,every])
        b.close()
        if errs: print('ERR',errs[:2])
        return r
if __name__=='__main__':
    fn,n,s0,out=sys.argv[1],int(sys.argv[2]),int(sys.argv[3]),sys.argv[4]
    over=json.loads(sys.argv[5]) if len(sys.argv)>5 else {}
    web=sys.argv[6] if len(sys.argv)>6 and sys.argv[6]!='-' else WEB
    slime=int(sys.argv[7]) if len(sys.argv)>7 and sys.argv[7]!='-' else None
    every=int(sys.argv[8]) if len(sys.argv)>8 else 2
    extra=open(sys.argv[9],encoding='utf-8').read() if len(sys.argv)>9 else None
    port=freeport()
    srv=serve(port,web);t0=time.time();P=5
    ch=[list(range(s0,s0+n))[k::P*2] for k in range(P*2)];jobs=[(web,port,fn,c,over,slime,every,extra) for c in ch if c]
    with mp.Pool(P) as pool: R=pool.map(run,jobs,chunksize=1)
    O=sorted([x for r in R for x in r],key=lambda x:x['seed']);json.dump(O,open(out,'w'));print(fn,'seeds',len(O),'frames',sum(x['frames'] for x in O),'rows',sum(len(x['rows']) for x in O),'secs',round(time.time()-t0));srv.shutdown()
