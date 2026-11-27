from common import *
import multiprocessing as mp, numpy as np
def run(a):
    port,slime,seeds,fn=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b,pg,errs=page(p,port)
        for f in ('skinmodes.js','paired.js','remesh.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
        r=pg.evaluate('''async ([fn,seeds,slime])=>{chooseSlime(slime,false,false);for(const s of seeds){F2.fresh(s,{shine:0,opaque:.9});
            // 先揉兩下讓紫斑出現
            if(FX().purple){const c=globalC,[sx,sy]=F2.scr(c.xc-R*.3,c.yc);F2.ev('pointerdown',1,sx,sy);for(let i=0;i<70;i++){F2.ev('pointermove',1,sx+Math.sin(i*.4)*R*.2,sy+Math.cos(i*.3)*R*.1);update(F2.DT)}F2.ev('pointerup',1,sx,sy);for(let i=0;i<10;i++)update(F2.DT)}
            GEST[fn](s,()=>update(F2.DT));for(const id of [...fingers.keys()])F2.ev('pointerup',id,0,0)}return REMLOG}''',[fn,seeds,slime])
        b.close();
        if errs: print(errs[:2])
        return (slime,fn,r)
if __name__=='__main__':
    port=freeport();srv=serve(port,BASE+'/fix5/prototype/web')
    jobs=[(port,sl,list(range(1,6)),fn) for sl in (2,5,9) for fn in ('CALM','P4S')]
    with mp.Pool(4) as P: R=P.map(run,jobs,chunksize=1)
    json.dump(R,open(BASE+'/data/remesh5.json','w'))
    for sl,fn,L in R:
        if not L: print(sl,fn,'no remesh');continue
        g=lambda k:np.array([o[k] for o in L if k in o and o[k] is not None],float)
        print('slime',sl,fn,'n',len(L),'back',int(sum(o['back'] for o in L)),'disp px mean %.2f p95 %.2f max %.2f'%(g('disp').mean(),np.percentile(g('disp'),95),g('disp').max()),'outline pt max %.1f'%g('maxd').max(),'eye jump px mean %.2f max %.2f'%(g('eye').mean(),g('eye').max()),
          'remesh 時有看得到的凹痕: %d'%sum(1 for o in L if o['dentMax']>.1))
        if 'core' in L[0]: print('   core centre jump R mean %.2f max %.2f'%(g('core').mean(),g('core').max()),'spread before→after max change',max([(abs(o['spread'][0]-o['spread'][1]),o['spread']) for o in L])[1])
        pe=[x for o in L for x in o.get('pearl',[])]
        if pe: print('   pearl jump R mean %.2f max %.2f  >.15R: %d/%d'%(np.mean(pe),max(pe),sum(x>.15 for x in pe),len(pe)))
        st=[x for o in L for x in o.get('stain',[])]
        if st: print('   stain jump R mean %.2f max %.2f  >.15R: %d/%d'%(np.mean(st),max(st),sum(x>.15 for x in st),len(st)))
    srv.shutdown()
