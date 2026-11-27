# 補點之後 12 幀：整隻移多少、面積掉多少，跟補點前 12 幀比；分階段
from common import *
import multiprocessing as mp, numpy as np
JS='''async ([fn,seeds,over])=>{const out=[];for(const s of seeds){F2.fresh(fn==='P4S'?61:s,{shine:0,opaque:.9,...over});let fr=0,lr=REM.n,ln=N;const T=[];const ev=[];
 GEST[fn](s,(ph,g)=>{const tn=TRI;update(F2.DT);fr++;let A=0,mx=0,my=0;const n=bnd.length;for(let i=0;i<n;i++){const a=bnd[i],b=bnd[(i+1)%n];A+=X[a]*Y[b]-X[b]*Y[a]}for(let i=0;i<N;i++){mx+=X[i];my+=Y[i]}let x0=1e9,x1=-1e9,y0=1e9,y1=-1e9;for(const i of bnd){if(X[i]<x0)x0=X[i];if(X[i]>x1)x1=X[i];if(Y[i]<y0)y0=Y[i];if(Y[i]>y1)y1=Y[i]}
  // 重心用外框多邊形的（換點前後可以比）
  let cx=0,cy=0;for(let i=0;i<n;i++){const a=bnd[i],b=bnd[(i+1)%n],c=X[a]*Y[b]-X[b]*Y[a];cx+=(X[a]+X[b])*c;cy+=(Y[a]+Y[b])*c}cx/=3*A;cy/=3*A;
  T.push([cx,cy,A/2/A0,x0,x1,y0,y1]);if(TRI!==tn)ev.push([fr,ph,g,REM.n===0?1:0])});
 for(const id of [...fingers.keys()])F2.ev('pointerup',id,0,0);
 for(const [f,ph,g,back] of ev){const k=f-1;if(k<13||k+13>=T.length)continue;const d=(a,b)=>Math.hypot(T[b][0]-T[a][0],T[b][1]-T[a][1]);let mvB=0,mvA=0;for(let q=1;q<=6;q++){mvB=Math.max(mvB,d(k-1-q,k-q));mvA=Math.max(mvA,d(k-1+q,k+q))}
  const jump1=d(k-1,k),aB=T[k-1][2];let aMin=9;for(let q=0;q<=12;q++)aMin=Math.min(aMin,T[k+q][2]);let aMinB=9;for(let q=1;q<=12;q++)aMinB=Math.min(aMinB,T[k-q][2]);
  out.push({s,f,ph,g,back,jump1,mvB,mvA,sh6:d(k-1,k+5),shB6:d(k-7,k-1),aB,aMin,aMinB})}}
 return out}'''
def run(a):
    port,fn,seeds,over=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b,pg,errs=page(p,port)
        for f in ('skinmodes.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
        r=pg.evaluate(JS,[fn,seeds,over]);b.close();return (fn,r)
if __name__=='__main__':
    port=freeport();srv=serve(port);jobs=[]
    for fn,sd in (('CALM',list(range(1,61))),('P4S',list(range(1,31)))):
        for k in range(6): jobs.append((port,fn,sd[k::6],{}))
    with mp.Pool(6) as P: R=P.map(run,jobs,chunksize=1)
    json.dump(R,open(BASE+'/data/remkick.json','w'))
    for fn in ('CALM','P4S'):
        L=[x for f,r in R if f==fn for x in r];print(fn,'補點次數',len(L),'（換回原本網格 %d）'%sum(x['back'] for x in L))
        for name,sel in (('按下去那幾格 d',lambda x:x['ph']=='d' and not x['back']),('拉 pull',lambda x:x['ph']=='pull' and not x['back']),('停住 hold',lambda x:x['ph']=='hold' and not x['back']),('放手換回 rel',lambda x:x['back'])):
            q=[x for x in L if sel(x)]
            if not q: continue
            g=lambda k:np.array([x[k] for x in q],float)
            print('  %-14s n%3d | 那一格重心跳 中位 %.1f p90 %.1f 最大 %.0f 點 | 之後 6 格每格最多移 中位 %.1f p90 %.1f 最大 %.0f（之前 6 格 中位 %.1f p90 %.1f）| 6 格共移 中位 %.0f p90 %.0f 最大 %.0f | 面積 之前 %.2f → 12 格內最低 中位 %.2f p10 %.2f 最低 %.2f'%(name,len(q),np.median(g('jump1')),np.percentile(g('jump1'),90),g('jump1').max(),np.median(g('mvA')),np.percentile(g('mvA'),90),g('mvA').max(),np.median(g('mvB')),np.percentile(g('mvB'),90),np.median(g('sh6')),np.percentile(g('sh6'),90),g('sh6').max(),np.median(g('aB')),np.median(g('aMin')),np.percentile(g('aMin'),10),g('aMin').min()))
    srv.shutdown()
