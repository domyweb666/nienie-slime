import sys,json,os,functools,threading,multiprocessing as mp
sys.path.insert(0,os.path.dirname(__file__));from st import SV,Q,CH
def run(a):
    w,port,seeds,over=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio']);pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True).new_page();pg.set_default_timeout(0)
        pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(1500)
        pg.evaluate('(c)=>{window.FZ=c}',{'seeds':seeds,'over':over});pg.evaluate(open(os.path.join(w,'fuzz.js'),encoding='utf-8').read())
        pg.wait_for_function('window.__fz && window.__fz.done',polling=500)
        r=pg.evaluate('window.__fz.out.map(o=>({flipFr:o.flipFr,frames:o.frames,flipMax:o.flipMax,j:o.jerkHoldMean,sp:o.endSpikes,ef:o.endFlip,ex:o.endX}))');b.close();return r
if __name__=='__main__':
    w=sys.argv[1];srv=SV(('127.0.0.1',8990),functools.partial(Q,directory=w));threading.Thread(target=srv.serve_forever,daemon=True).start()
    arms=[{'pullGive':0,'memUntie':0},{},{'pullGive':0.3}];jobs=[(w,8990,list(range(1000+6*k,1006+6*k)),a) for a in arms for k in range(4)]
    with mp.Pool(6) as P: R=P.map(run,jobs,chunksize=1)
    for i,a in enumerate(arms):
        r=[x for q in R[4*i:4*i+4] for x in q];n=len(r)
        print(a,'n',n,'flipFr%% %.1f'%(100*sum(x['flipFr'] for x in r)/sum(x['frames'] for x in r)),'jerk %.2f'%(sum(x['j'] or 0 for x in r)/n),'spikes',sum((x['sp'] or 0)>0 for x in r),'endFlip',sum((x['ef'] or 0)>0 for x in r),'endX',sum((x['ex'] or 0)>0 for x in r))
