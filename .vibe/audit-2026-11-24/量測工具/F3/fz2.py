import sys,json,os,functools,threading,multiprocessing as mp
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,HERE)
from st import SV,Q,CH
def run(a):
    w,port,seeds,over=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio']);pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True).new_page();pg.set_default_timeout(0)
        pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(1500)
        pg.evaluate('(c)=>{window.FZ=c}',{'seeds':seeds,'over':over});pg.evaluate(open(os.path.join(w,'fuzz.js'),encoding='utf-8').read())
        pg.wait_for_function('window.__fz && window.__fz.done',polling=500)
        r=pg.evaluate('window.__fz.out.map(o=>({flipFr:o.flipFr,frames:o.frames,flipMax:o.flipMax,j:o.jerkHoldMean,sp:o.endSpikes,ef:o.endFlip,ex:o.endX,xFr:o.xFr}))');b.close();return r
if __name__=='__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    w=os.path.join(os.path.dirname(HERE),'webB');port=8992;srv=SV(('127.0.0.1',port),functools.partial(Q,directory=w));threading.Thread(target=srv.serve_forever,daemon=True).start()
    arms=[{},{'lagLead':.6},{'lagMix':.3},{'lag':.12}];K=4;S=6
    jobs=[(w,port,list(range(1000+S*k,1000+S*(k+1))),a) for a in arms for k in range(K)]
    with mp.Pool(4) as P: R=P.map(run,jobs,chunksize=1)
    for i,a in enumerate(arms):
        r=[x for q in R[K*i:K*i+K] for x in q];n=len(r)
        print(a,'n',n,'翻面格 %.1f%%'%(100*sum(x['flipFr'] for x in r)/sum(x['frames'] for x in r)),'交叉格 %.1f%%'%(100*2*sum(x['xFr'] for x in r)/sum(x['frames'] for x in r)),'一格最多翻 %d'%max(x['flipMax'] for x in r),'停住時跳動 %.2f'%(sum(x['j'] or 0 for x in r)/n),'結束有尖 %d 翻 %d 交叉 %d'%(sum((x['sp'] or 0)>0 for x in r),sum((x['ef'] or 0)>0 for x in r),sum((x['ex'] or 0)>0 for x in r)),flush=True)
    srv.shutdown()
