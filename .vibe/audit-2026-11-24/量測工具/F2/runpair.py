# usage: runpair.py <fn> <n> <seed0> <tag> [over json] [modes "0,1,2"] [slime] [every] [extra js ...]
from common import *
import multiprocessing as mp, base64
def run(a):
    web,port,fn,seeds,over,modes,slime,every,extra=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b,pg,errs=page(p,port)
        (pg.evaluate(open(BASE+'/tools/skinmodes.js',encoding='utf-8').read()) if 'fix' not in web.split('F2work')[1] else None)
        pg.evaluate(open(BASE+'/tools/paired.js',encoding='utf-8').read())
        for e in extra: pg.evaluate(e)
        r=pg.evaluate('async (o)=>{return await RUNP(o)}',{'fn':fn,'seeds':seeds,'over':over,'modes':modes,'slime':slime,'every':every})
        b.close()
        if errs: print('ERR',errs[:2])
        return r
if __name__=='__main__':
    fn,n,s0,tag=sys.argv[1],int(sys.argv[2]),int(sys.argv[3]),sys.argv[4]
    over=json.loads(sys.argv[5]) if len(sys.argv)>5 and sys.argv[5] not in('','-') else {}
    modes=[int(x) for x in sys.argv[6].split(',')] if len(sys.argv)>6 and sys.argv[6]!='-' else [0,1,2]
    slime=int(sys.argv[7]) if len(sys.argv)>7 and sys.argv[7]!='-' else None
    every=int(sys.argv[8]) if len(sys.argv)>8 and sys.argv[8]!='-' else 3
    extra=[open(f,encoding='utf-8').read() for f in sys.argv[9:]]
    web=os.environ.get('F2WEB',WEB)
    port=freeport()
    srv=serve(port,web);t0=time.time();P=int(os.environ.get('F2P','5'))
    ch=[list(range(s0,s0+n))[k::P*2] for k in range(P*2)];jobs=[(web,port,fn,c,over,modes,slime,every,extra) for c in ch if c]
    with mp.Pool(P) as pool: R=pool.map(run,jobs,chunksize=1)
    O=sorted([x for r in R for x in r['out']],key=lambda x:x['seed']);json.dump(O,open(BASE+f'/data/{tag}.json','w'))
    caps={}
    for r in R:
        for k,L in r['caps'].items(): caps.setdefault(k,[]).extend(L)
    d=BASE+f'/shots/{tag}';os.makedirs(d,exist_ok=True);idx=[]
    from PIL import Image
    import io
    for k,L in caps.items():
        L.sort(key=lambda o:-o['score'])
        for q,o in enumerate(L[:3]):
            ims=[Image.open(io.BytesIO(base64.b64decode(v.split(',')[1]))).convert('RGB') for kk,v in sorted(o['imgs'].items(),key=lambda kv:(kv[0]!='m0',kv[0]!='d0',kv[0]))]
            C=Image.new('RGB',(sum(i.width for i in ims),ims[0].height));x=0
            for i in ims: C.paste(i,(x,0));x+=i.width
            C.save(f'{d}/{k}_{q}.jpg',quality=88);idx.append((k,q,round(o['score'],2),o['info'],sorted(o['imgs'])))
    json.dump(idx,open(d+'/index.json','w'),ensure_ascii=False,indent=0)
    print(fn,tag,'seeds',len(O),'frames',sum(x['frames'] for x in O),'rows',sum(len(x['rows']) for x in O),'secs',round(time.time()-t0));srv.shutdown()
