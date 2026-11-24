from common import *
import multiprocessing as mp, numpy as np
JS='''async ([seeds,draws])=>{const out=[];for(const s of seeds){F2.fresh(s,{shine:0,opaque:.9});let fr=0,worst=0,minA=9,wide=0;const hist=[];let bad=null;
 GEST.CALM(s,(ph,g)=>{update(F2.DT);fr++;if(draws&&fr%6===0){draw()}let x0=1e9,x1=-1e9,c=0;for(let i=0;i<N;i++){if(X[i]<x0)x0=X[i];if(X[i]>x1)x1=X[i];if(X[i]<-2||X[i]>W+2||Y[i]<-2)c++}const off=c/N;if(off>worst)worst=off;let A=0;const n=bnd.length;for(let i=0;i<n;i++){const a=bnd[i],b=bnd[(i+1)%n];A+=X[a]*Y[b]-X[b]*Y[a]}const ar=A/2/A0;if(ar<minA)minA=ar;if(x1-x0>wide)wide=x1-x0;
  const f=[...fingers.values()][0];hist.push([fr,ph,g,+ar.toFixed(2),Math.round(x0),Math.round(x1),+off.toFixed(2),F2.invN(),REM.n,f?[Math.round(f.sx),Math.round(f.sy)]:0,SILL.surf,+SILL.gvx.toFixed(2),SILL.route?1:0,CLING.on?1:0]);if(hist.length>160)hist.shift();
  if(!bad&&(off>.25||ar<.45))bad={at:fr,h:hist.filter((q,k)=>k%6===0||k>hist.length-8)}});
 for(const id of [...fingers.keys()])F2.ev('pointerup',id,0,0);out.push({s,worst,minA,wide,bad})}return out}'''
def run(a):
    port,seeds,d=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b,pg,errs=page(p,port)
        for f in ('skinmodes.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
        r=pg.evaluate(JS,[seeds,d]);b.close();return r
if __name__=='__main__':
    port=freeport();srv=serve(port);sd=list(range(1,181))
    with mp.Pool(6) as P: R=P.map(run,[(port,sd[k::12],True) for k in range(12)],chunksize=1)
    L=[x for r in R for x in r]
    print('組',len(L),'最多在螢幕外 >25%%：%d 組'%sum(x['worst']>.25 for x in L),'面積掉到 45%% 以下：%d 組'%sum(x['minA']<.45 for x in L),'最寬 %.0f 點'%max(x['wide'] for x in L))
    L.sort(key=lambda x:-(x['worst']+max(0,.6-x['minA'])))
    for x in L[:4]:
        print(x['s'],round(x['worst'],2),round(x['minA'],2),round(x['wide']))
        if x['bad']:
            for q in x['bad']['h']: print('    ',q)
    srv.shutdown()
