# 補點踢的修法試驗：A 預設；B 補點後重算 globalC 與 CP；C B＋家跟著粒子平均移；D 只有家跟著移
from common import *
import multiprocessing as mp, numpy as np
JS='''async ([fn,seeds,arm,over])=>{const out=[];const cen=()=>{let A=0,cx=0,cy=0;const n=bnd.length;for(let i=0;i<n;i++){const a=bnd[i],b=bnd[(i+1)%n],c=X[a]*Y[b]-X[b]*Y[a];A+=c;cx+=(X[a]+X[b])*c;cy+=(Y[a]+Y[b])*c}return [cx/3/A,cy/3/A,A/2/A0]};
 const mean=()=>{let x=0,y=0;for(let i=0;i<N;i++){x+=X[i];y+=Y[i]}return [x/N,y/N]};
 if(!window.__rm0){window.__rm0=remesh}
 let ev=null;remesh=function(b){const c0=cen(),m0=mean();const r=__rm0(b);if(r){const m1=mean();
   if(arm==='B'||arm==='C'){globalC.xc=m1[0];globalC.yc=m1[1];CPX=m1[0];CPY=m1[1]}
   if(arm==='C'||arm==='D'){HOMEX+=m1[0]-m0[0];HOMEY+=m1[1]-m0[1]}
   ev={back:b?1:0,c1:cen(),m0,m1}}return r};
 const stats={off:0,worst:0,minA:9,frames:0,tot:0};
 for(const s of seeds){F2.fresh(fn==='P4S'?61:s,{shine:0,opaque:.9,...over});let cur=null,worst=0,minA=9;
  GEST[fn](s,(ph)=>{ev=null;update(F2.DT);const c=cen();stats.frames++;let o=0;for(let i=0;i<N;i++)if(X[i]<-2||X[i]>W+2||Y[i]<-2)o++;o/=N;if(o>worst)worst=o;if(c[2]<minA)minA=c[2];
   if(cur){cur.n++;cur.aMin=Math.min(cur.aMin,c[2]);if(cur.n===1)cur.a1=Math.hypot(c[0]-cur.c1[0],c[1]-cur.c1[1]);if(cur.n===8){cur.a8=Math.hypot(c[0]-cur.c1[0],c[1]-cur.c1[1]);out.push({ph:cur.ph,back:cur.back,a0:cur.a0,a1:cur.a1,a8:cur.a8,dm:Math.hypot(cur.m1[0]-cur.m0[0],cur.m1[1]-cur.m0[1]),aMin:cur.aMin,A:cur.c1[2]});cur=null}}
   if(ev&&!cur)cur={...ev,ph,n:0,aMin:9,a0:Math.hypot(c[0]-ev.c1[0],c[1]-ev.c1[1])}});
  stats.worst=Math.max(stats.worst,worst);if(worst>.25)stats.off++;stats.minA=Math.min(stats.minA,minA);stats.tot++;
  for(const id of [...fingers.keys()])F2.ev('pointerup',id,0,0)}return {out,stats}}'''
def run(a):
    port,fn,seeds,arm,over=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b,pg,errs=page(p,port)
        for f in ('skinmodes.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
        r=pg.evaluate(JS,[fn,seeds,arm,over]);b.close();return (fn,arm,r)
if __name__=='__main__':
    port=freeport();srv=serve(port);jobs=[]
    fn=sys.argv[1] if len(sys.argv)>1 else 'CALM';n=int(sys.argv[2]) if len(sys.argv)>2 else 36
    for arm in ('A','B','C','D'):
        sd=list(range(1,n+1))
        for k in range(3): jobs.append((port,fn,sd[k::3],arm,{}))
    with mp.Pool(6) as P: R=P.map(run,jobs,chunksize=1)
    for arm in ('A','B','C','D'):
        L=[x for f,a,r in R if a==arm for x in r['out']];S=[r['stats'] for f,a,r in R if a==arm]
        print(arm,'組',sum(s['tot'] for s in S),'四分之一以上跑出螢幕的組',sum(s['off'] for s in S),'最多 %.0f%%'%(100*max(s['worst'] for s in S)),'面積最低 %.2f'%min(s['minA'] for s in S))
        for name,sel in (('d',lambda x:x['ph']=='d' and not x['back']),('pull',lambda x:x['ph']=='pull' and not x['back']),('hold',lambda x:x['ph']=='hold' and not x['back']),('換回',lambda x:x['back'])):
            q=[x for x in L if sel(x)]
            if q: g=lambda k:np.array([x[k] for x in q],float);print('   %-4s n%3d 粒子平均跳 %.0f｜同一格整隻移 中位 %.1f p90 %.1f｜兩格後 中位 %.1f p90 %.1f｜八格後 中位 %.1f p90 %.1f｜八格內面積最低 中位 %.2f 最低 %.2f'%(name,len(q),np.median(g('dm')),np.median(g('a0')),np.percentile(g('a0'),90),np.median(g('a1')),np.percentile(g('a1'),90),np.median(g('a8')),np.percentile(g('a8'),90),np.median(g('aMin')),g('aMin').min()))
    srv.shutdown()
