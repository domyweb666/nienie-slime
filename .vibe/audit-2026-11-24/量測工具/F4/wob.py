import sys, json, os, multiprocessing as mp
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from boot import *
def run(a):
    cfg, port = a
    from playwright.sync_api import sync_playwright
    lib=open(os.path.join(HERE,'lib.js'),encoding='utf-8').read(); wj=open(os.path.join(HERE,'wob.js'),encoding='utf-8').read()
    with sync_playwright() as p:
        b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
        pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=1,has_touch=True).new_page(); pg.set_default_timeout(0)
        pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(1200); pg.evaluate(lib+';0')
        r=pg.evaluate(wj,cfg); b.close()
    return cfg,r
if __name__=='__main__':
    port=8960+os.getpid()%30; srv=serve(port)
    cf=[dict(slime=s,d=d,seed=sd) for s in (2,1,5) for d in (1.0,2.0) for sd in (1,2)]
    with mp.Pool(5) as P: R=P.map(run,[(c,port) for c in cf],chunksize=1)
    for cfg,r in R:
        v=[q[1] for q in r]
        def last(th): 
            idx=[i for i,x in enumerate(v) if x>th]; return (idx[-1]/60 if idx else 0)
        # peaks (local maxima) in first 2 s
        pk=[(r[i][0],v[i]) for i in range(1,len(v)-1) if v[i]>v[i-1] and v[i]>=v[i+1] and v[i]>.05][:6]
        print(cfg['slime'],cfg['d'],cfg['seed'],'start %.2f R/s'%v[0],'still moving >0.2R/s until %.2fs, >0.1 until %.2fs, >0.05 until %.2fs'%(last(.2),last(.1),last(.05)),'peaks',pk)
    srv.shutdown()
