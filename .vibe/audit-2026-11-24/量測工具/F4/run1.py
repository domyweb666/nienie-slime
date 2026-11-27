import sys, json, os, multiprocessing as mp
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from boot import *
def run(a):
    name, seed, port = a
    from playwright.sync_api import sync_playwright
    lib=open(os.path.join(HERE,'lib.js'),encoding='utf-8').read(); ges=open(os.path.join(HERE,'gest.js'),encoding='utf-8').read()
    with sync_playwright() as p:
        b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio','--autoplay-policy=no-user-gesture-required'])
        pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True).new_page()
        errs=[];pg.on('pageerror',lambda e:errs.append(str(e)))
        pg.set_default_timeout(0)
        pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(1500)
        pg.evaluate(lib); pg.evaluate(ges)
        try: r=pg.evaluate('(a)=>{const F=window.__f4;F.setSeed(a[1]);F.settle(12);return window.__gest[a[0]]()}',[name,seed])
        except Exception as e: r={'log':[],'EXC':str(e)[:300]}
        b.close()
    r['name']=name; r['seed']=seed
    if errs: r['err']=errs[:3]
    return r
if __name__=='__main__':
    ALL='tap,hold3,rub,stroke,stroke6,slowpull,yank,longhold,swing,flingside,release_gentle,pinch,spread,spread_v,rotate,poke7,tickle,drag,dragdeco,bumpwall,throwwall,dropfloor,putonwall,pulloffwall,pinchlong,three,palm,edgegraze,pushout,shake,sleeptouch,repeatpull'.split(',')
    sel=sys.argv[1].split(',') if len(sys.argv)>1 and sys.argv[1] and sys.argv[1]!='ALL' else ALL
    seeds=[int(x) for x in sys.argv[2].split(',')] if len(sys.argv)>2 else [1]
    out=sys.argv[3] if len(sys.argv)>3 else None
    port=8960+os.getpid()%30
    srv=serve(port)
    jobs=[(n,s,port) for n in sel for s in seeds]
    with mp.Pool(min(5,len(jobs))) as P: R=P.map(run,jobs,chunksize=1)
    if out: json.dump(R,open(os.path.join(HERE,out),'w',encoding='utf-8'),ensure_ascii=False)
    for r in R:
        print('=====',r['name'],'seed',r['seed'],{k:(round(v,3) if isinstance(v,float) else v) for k,v in r.items() if k not in('log','name','seed','cont')})
        for e in r.get('log',[])[:int(os.environ.get('NL','40'))]: print('   ',e)
    srv.shutdown()
