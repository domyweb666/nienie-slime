from common import *
from playwright.sync_api import sync_playwright
import numpy as np
port=freeport();srv=serve(port)
JS='''async ([fn,seeds])=>{const out=[];for(const s of seeds){F2.fresh(fn==='P4S'?61:s,{shine:0,opaque:.9});let n=0,o5=0,o20=0,mx=0,area=0;GEST[fn](s,(ph)=>{update(F2.DT);n++;let m=0,c=0;for(let i=0;i<N;i++){const d=Math.max(-X[i],X[i]-W,-Y[i]);if(d>m)m=d;if(d>0)c++}if(m>5)o5++;if(m>20)o20++;if(m>mx)mx=m;area=Math.max(area,c/N)});for(const id of [...fingers.keys()])F2.ev('pointerup',id,0,0);out.push([n,o5,o20,mx,area])}return out}'''
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    for f in ('skinmodes.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
    for fn,sd in (('CALM',range(1,13)),('P4S',range(1,13)),('FZS',range(1000,1012)),('TWO',range(1,13))):
        r=np.array(pg.evaluate(JS,[fn,list(sd)]));n=r[:,0].sum()
        print(fn,'組',len(r),'格',int(n),'有點超出螢幕 5 點以上的格 %.1f%%、20 點以上 %.1f%%'%(100*r[:,1].sum()/n,100*r[:,2].sum()/n),'最多超出 %.0f 點'%r[:,3].max(),'同時在螢幕外的粒子最多 %.0f%%'%(100*r[:,4].max()),'組數(>20點)',int((r[:,2]>0).sum()))
    print(errs);b.close()
srv.shutdown()
