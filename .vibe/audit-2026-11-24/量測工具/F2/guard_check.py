# 物理允許的最細：ringGuard 只擋到 .45h；皮要 .105R 才看得到。量各種玩法裡，身體最細的地方（外框往裡到對面）的分布
from common import *
from playwright.sync_api import sync_playwright
import numpy as np
port=freeport();srv=serve(port,BASE+'/fix4/prototype/web')
JS='''async ([fn,seeds])=>{const out=[];for(const s of seeds){F2.fresh(fn==='P4S'?61:s,{shine:0,opaque:.9});let fr=0;GEST[fn](s,(ph)=>{update(F2.DT);if(++fr%6)return;JELX.mode=9;draw();const M=JEL.mesh,nb=bnd.length,Rz=R*CAM.z;let mn=9,n16=0,n105=0;for(let k=0;k<nb;k++){const T=M.T[k]/Rz;if(T<mn)mn=T;if(T<.16)n16++;if(T<.105)n105++}out.push([mn,n16/nb,n105/nb])});for(const id of [...fingers.keys()])F2.ev('pointerup',id,0,0)}return out}'''
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    for f in ('modes_fix4.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
    for fn,sd in (('CALM',range(1,9)),('P4S',range(1,9)),('FZS',range(1000,1008)),('TWO',range(1,9))):
        r=np.array(pg.evaluate(JS,[fn,list(sd)]))
        print(fn,'格',len(r),'每格最細處 T（半徑）：中位 %.3f p10 %.3f p1 %.3f；T<0.105R 的格 %.1f%%（這些地方皮看不到）；T<0.16R 的外框點平均占 %.1f%%'%(np.median(r[:,0]),np.percentile(r[:,0],10),np.percentile(r[:,0],1),100*(r[:,0]<.105).mean(),100*r[:,1].mean()))
    print(errs);b.close()
srv.shutdown()
