import sys, json, os, itertools, multiprocessing as mp
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from boot import *
def run(a):
    cfgs, port = a
    from playwright.sync_api import sync_playwright
    lib=open(os.path.join(HERE,'lib.js'),encoding='utf-8').read(); ges=open(os.path.join(HERE,'gest.js'),encoding='utf-8').read(); wj=open(os.path.join(HERE,'wall.js'),encoding='utf-8').read()
    out=[]
    with sync_playwright() as p:
        b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
        for cfg in cfgs:
            pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=1,has_touch=True).new_page(); pg.set_default_timeout(0)
            pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(1200)
            pg.evaluate(lib+';0'); pg.evaluate(ges+';0')
            out.append((cfg,pg.evaluate(wj,cfg))); pg.close()
        b.close()
    return out
if __name__=='__main__':
    port=8960+os.getpid()%30; srv=serve(port)
    cf=[]
    for sl,gr in [(2,'center'),(2,'bottom'),(2,'side'),(1,'center'),(5,'center')]:
        for T in (0.8,2):
            for u in (2.5,3.8):
                for h in (0.1,0.4):
                    for sd in (1,2): cf.append(dict(T=T,up=u,hold=h,side='r',seed=sd,settle=4,grab=gr,slime=sl))
    k=5; jobs=[(cf[i::k],port) for i in range(k)]
    with mp.Pool(k) as P: R=[x for r in P.map(run,jobs) for x in r]
    from collections import defaultdict
    D=defaultdict(list)
    for cfg,r in R: D[(cfg['slime'],cfg['grab'])].append((cfg,r))
    for key,L in D.items():
        print('slime',key,'n',len(L),'cling at 0.5s',sum(r['c05'] for _,r in L),'still 3s',sum(r['c3'] for _,r in L),'median bottom-off-sill gap (R) %.2f'%sorted(r['gap'] for _,r in L)[len(L)//2],'fled',sum(r['esc'] for _,r in L),'reached wall',sum(r['x1']>389-32 for _,r in L))
    srv.shutdown()
