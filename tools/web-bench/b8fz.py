# v2.64 B8 起步跟手：亂捏打結比例（翻面格）開和關各跑一次，40 組（種子 1000 到 1039）。規劃說 16.4% 變 19.9%、另一輪方向相反，判不出好壞，這裡只記數字不擋。
# 用法：python b8fz.py <web 資料夾> [--seeds 40] [--port 8994]
import sys,os,argparse,functools,threading,multiprocessing as mp
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
    sys.stdout.reconfigure(encoding='utf-8')
    ap=argparse.ArgumentParser();ap.add_argument('webdir');ap.add_argument('--seeds',type=int,default=40);ap.add_argument('--port',type=int,default=8994);ap.add_argument('--procs',type=int,default=4)
    a=ap.parse_args();w=a.webdir
    srv=SV(('127.0.0.1',a.port),functools.partial(Q,directory=w));threading.Thread(target=srv.serve_forever,daemon=True).start()
    arms=[{},{'startFollow':1}];K=a.procs;S=-(-a.seeds//K)
    jobs=[(w,a.port,[s for s in range(1000+S*k,1000+S*(k+1)) if s<1000+a.seeds],o) for o in arms for k in range(K)]
    with mp.Pool(min(8,len(jobs))) as P: R=P.map(run,jobs,chunksize=1)
    for i,o in enumerate(arms):
        r=[x for q in R[K*i:K*i+K] for x in q];n=len(r)
        print(o or '{} 起步跟手關','n',n,'翻面格 %.1f%%'%(100*sum(x['flipFr'] for x in r)/sum(x['frames'] for x in r)),'一格最多翻 %d'%max(x['flipMax'] for x in r),'停住時跳動 %.2f'%(sum(x['j'] or 0 for x in r)/n),'結束有尖 %d 翻 %d 交叉 %d'%(sum((x['sp'] or 0)>0 for x in r),sum((x['ef'] or 0)>0 for x in r),sum((x['ex'] or 0)>0 for x in r)),flush=True)
    srv.shutdown()
