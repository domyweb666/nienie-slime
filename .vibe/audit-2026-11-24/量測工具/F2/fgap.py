# 手指到看得到的皮有多遠；被抓那塊的重心看不看得到（m0 現在／m9 新做法）
from common import *
import multiprocessing as mp, numpy as np
JS='''async ([fn,seeds,modes])=>{const out=[];const W1=F2.W1,H1=F2.H1;
 const gapTo=(sk,x,y)=>{const ix=Math.round(x),iy=Math.round(y);if(ix>=0&&iy>=0&&ix<W1&&iy<H1&&sk[iy*W1+ix])return 0;for(let r=1;r<220;r+=1){const n=Math.max(8,Math.ceil(r*3));for(let k=0;k<n;k++){const a=k/n*6.2832,px=Math.round(x+Math.cos(a)*r),py=Math.round(y+Math.sin(a)*r);if(px>=0&&py>=0&&px<W1&&py<H1&&sk[py*W1+px])return r}}return 220};
 for(const s of seeds){F2.fresh(fn==='P4S'?61:s,{shine:0,opaque:.9});let fr=0;GEST[fn](s,(ph)=>{update(F2.DT);if(++fr%5)return;const gs=[...fingers.values()].filter(f=>f.mode==='grab'&&f.mem&&f.mem.length);if(!gs.length)return;const row={s,fr,ph};
   for(const md of modes){JELX.mode=md;draw();F2.readSkin();let g=0,vis=1;for(const f of gs){const d=gapTo(F2.skin,f.sx,f.sy);if(d>g)g=d;let x=0,y=0,w=0;for(const m of f.mem){x+=X[m[0]]*m[3];y+=Y[m[0]]*m[3];w+=m[3]}const [px,py]=F2.scr(x/w,y/w);const off=px<2||py<2||px>W1-2||py>H1-2;if(!off&&gapTo(F2.skin,px,py)>1)vis=0}row['g'+md]=g;row['v'+md]=vis}
   out.push(row)});for(const id of [...fingers.keys()])F2.ev('pointerup',id,0,0)}
 return out}'''
def run(a):
    port,fn,seeds=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b,pg,errs=page(p,port)
        for f in ('modes_fix4.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
        r=pg.evaluate(JS,[fn,seeds,[0,9]]);b.close();return (fn,r)
if __name__=='__main__':
    port=freeport();srv=serve(port,BASE+'/fix4/prototype/web');jobs=[]
    for fn,sd in (('CALM',list(range(1,13))),('P4S',list(range(1,17))),('FZS',list(range(1000,1016))),('TWO',list(range(1,17)))):
        for k in range(4): jobs.append((port,fn,sd[k::4]))
    with mp.Pool(5) as P: R=P.map(run,jobs,chunksize=1)
    json.dump(R,open(BASE+'/data/fgap.json','w'))
    for fn in ('CALM','P4S','FZS','TWO'):
        L=[x for f,r in R if f==fn for x in r];g0=np.array([x['g0'] for x in L],float);g9=np.array([x['g9'] for x in L],float);v0=np.array([x['v0'] for x in L]);v9=np.array([x['v9'] for x in L])
        print(fn,'抓著的格',len(L),'| 手指到看得到的皮（點）m0 中位 %.0f p95 %.0f p99 %.0f；m9 中位 %.0f p95 %.0f p99 %.0f'%(np.median(g0),np.percentile(g0,95),np.percentile(g0,99),np.median(g9),np.percentile(g9,95),np.percentile(g9,99)),'| 差 10 點以上的格 m0 比 m9 多 %.1f%%'%(100*np.mean(g0-g9>10)),'最多少 %.0f 點'%(g0-g9).max(),'| 被抓那塊看不到的格 m0 %.2f%% m9 %.2f%%'%(100*np.mean(v0==0),100*np.mean(v9==0)))
    srv.shutdown()
