# 補點那一格的踢來自哪裡：同樣的手勢，比 (a) 預設 (b) remeshCalm 關 (c) 不補點 (d) 補點但重心在 0.15 秒內釘在補點前的速度
from common import *
import multiprocessing as mp, numpy as np
exec(open(BASE+'/tools/remkick.py',encoding='utf-8').read().split("def run(a)")[0].split("JS='''")[0])
SRC=open(BASE+'/tools/remkick.py',encoding='utf-8').read();JS=SRC.split("JS='''")[1].split("'''")[0]
FIX='''()=>{ // d：補點後 0.2 秒內，整團的平移速度只准是補點前那一格的（手指真的在動的話加上手指的速度）
 const rm0=remesh;window.__lock={until:-9,vx:0,vy:0};
 remesh=function(back){let mx=0,my=0;for(let i=0;i<N;i++){mx+=X[i]-PX[i];my+=Y[i]-PY[i]}mx/=N;my/=N;const r=rm0(back);if(r&&!back){__lock.until=t+.2;__lock.vx=mx;__lock.vy=my}return r};
 const cs0=remeshCalmStep;
 remeshCalmStep=function(dt){cs0(dt);if(t<__lock.until){let mx=0,my=0;for(let i=0;i<N;i++){mx+=X[i]-PX[i];my+=Y[i]-PY[i]}mx/=N;my/=N;const k=1-(__lock.until-t)/.2,tx=__lock.vx*(1-k)+mx*k,ty=__lock.vy*(1-k)+my*k;for(let i=0;i<N;i++){PX[i]+=mx-tx;PY[i]+=my-ty}}}}'''
def run(a):
    port,fn,seeds,over,arm=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b,pg,errs=page(p,port)
        for f in ('skinmodes.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
        if arm=='lock': pg.evaluate(FIX)
        r=[]
        for sd in seeds:
            try: r+=pg.evaluate(JS,[fn,[sd],over])
            except Exception as e: print('ERR',arm,sd,str(e)[:90])
        b.close();return (fn,arm,r)
if __name__=='__main__':
    port=freeport();srv=serve(port);jobs=[]
    for arm,over in (('預設',{}),('calm關',{'remeshCalm':0}),('lock',{})):
        sd=list(range(1,25))
        for k in range(3): jobs.append((port,'CALM',sd[k::3],over,arm))
    with mp.Pool(6) as P: R=P.map(run,jobs,chunksize=1)
    for arm in ('預設','calm關','lock'):
        L=[x for f,a,r in R if a==arm for x in r if not x['back']]
        for name,sel in (('d',lambda x:x['ph']=='d'),('pull',lambda x:x['ph']=='pull'),('hold',lambda x:x['ph']=='hold')):
            q=[x for x in L if sel(x)]
            if q: g=lambda k:np.array([x[k] for x in q],float);print(arm,name,'n',len(q),'那一格跳 中位 %.1f p90 %.1f｜之後每格最多 中位 %.1f｜6 格共移 中位 %.0f p90 %.0f｜面積最低 中位 %.2f 最低 %.2f'%(np.median(g('jump1')),np.percentile(g('jump1'),90),np.median(g('mvA')),np.median(g('sh6')),np.percentile(g('sh6'),90),np.median(g('aMin')),g('aMin').min()))
    srv.shutdown()
