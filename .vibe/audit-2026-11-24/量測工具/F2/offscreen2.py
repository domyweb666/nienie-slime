from common import *
import multiprocessing as mp, numpy as np
JS='''async ([fn,seeds,over])=>{const out=[];for(const s of seeds){F2.fresh(fn==='P4S'?61:s,{shine:0,opaque:.9,...over});let n=0,mx=0,worst=0,f20=0,f50=0,run=0,best=0,wf=0,wp='';GEST[fn](s,(ph)=>{update(F2.DT);n++;let m=0,c=0;for(let i=0;i<N;i++){const d=Math.max(-X[i],X[i]-W,-Y[i],Y[i]-H);if(d>m)m=d;if(d>2)c++}const fr=c/N;if(fr>worst){worst=fr;wf=n;wp=ph}if(fr>.2)f20++;if(fr>.5){f50++;run++;best=Math.max(best,run)}else run=0;if(m>mx)mx=m});for(const id of [...fingers.keys()])F2.ev('pointerup',id,0,0);out.push({s,n,mx,worst,f20,f50,best,wf,wp})}return out}'''
def run(a):
    port,fn,seeds,over=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b,pg,errs=page(p,port)
        for f in ('skinmodes.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
        r=pg.evaluate(JS,[fn,seeds,over]);b.close();return (fn,r)
if __name__=='__main__':
    port=freeport();srv=serve(port);jobs=[]
    for fn,sd in (('FZS',list(range(1000,1060))),('P4S',list(range(1,41))),('TWO',list(range(1,41))),('CALM',list(range(1,31)))):
        for k in range(4): jobs.append((port,fn,sd[k::4],{}))
    with mp.Pool(5) as P: R=P.map(run,jobs,chunksize=1)
    for fn in ('CALM','FZS','P4S','TWO'):
        L=[x for f,r in R if f==fn for x in r];n=sum(x['n'] for x in L)
        print(fn,'組',len(L),'格',n,'| 兩成以上粒子在螢幕外的格 %.2f%%（%d 組）'%(100*sum(x['f20'] for x in L)/n,sum(x['f20']>0 for x in L)),'| 一半以上在外 %.2f%%（%d 組，最久連續 %d 格）'%(100*sum(x['f50'] for x in L)/n,sum(x['f50']>0 for x in L),max(x['best'] for x in L)),'| 最多 %.0f%%'%(100*max(x['worst'] for x in L)),'| 最遠 %.0f 點'%max(x['mx'] for x in L))
        L.sort(key=lambda x:-x['worst']);print('   最糟',[(x['s'],round(x['worst'],2),x['wf'],x['wp'],x['best']) for x in L[:4]])
    srv.shutdown()
