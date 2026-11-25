# run.py cells.json outprefix --procs 6 --slime 2 --over '{}' --src <webdir> --q '' --port 8981
import sys,json,time,base64,argparse,os,multiprocessing as mp
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from srv import *
A=os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace(os.sep,'/')+'/'
def work(a):
    wid,cells,slime,over,q,port,outp,snap,deep,pre,BT=a
    from playwright.sync_api import sync_playwright
    fo=open(f'{outp}.{wid}.jsonl','w',encoding='utf-8');sd=outp+'_snap';os.makedirs(sd,exist_ok=True)
    with sync_playwright() as p:
        b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
        i=0
        while i<len(cells):
            cx=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True);pg=cx.new_page();pg.set_default_timeout(0)
            errs=[];pg.on('pageerror',lambda e:errs.append(str(e)))
            pg.goto(f'http://127.0.0.1:{port}/index.html'+q,wait_until='load');pg.wait_for_timeout(2500)
            pg.evaluate(open(A+'tool/probe.js',encoding='utf-8').read());pg.evaluate('PB.init()')
            if slime>=0: pg.evaluate('i=>PB.slime(i)',slime)
            pg.evaluate('o=>{PB.over=o;}',over)
            pg.evaluate('o=>{PB.snapOn=o[0];PB.deep=o[1]}',[snap,deep])
            if pre: pg.evaluate(pre)
            for c in cells[i:i+BT]:
                try: m=pg.evaluate('c=>PB.run(c)',c)
                except Exception as e: m={'id':c['id'],'c':c,'err':str(e)[:300]}
                for k,s in list(m.get('snaps',{}).items()):
                    fn=f"{sd}/{c['id']}_{k}.jpg";open(fn,'wb').write(base64.b64decode(s['img'].split(',')[1]));s['img']=fn
                if errs: m['perr']=errs[:3]; errs.clear()
                fo.write(json.dumps(m,ensure_ascii=False)+'\n');fo.flush()
            i+=BT;cx.close()
        b.close()
    fo.close();return len(cells)
if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('cells');ap.add_argument('out');ap.add_argument('--procs',type=int,default=6);ap.add_argument('--slime',type=int,default=-1);ap.add_argument('--over',default='{}');ap.add_argument('--q',default='');ap.add_argument('--port',type=int,default=8981);ap.add_argument('--src',default=A+'src/prototype/web');ap.add_argument('--nosnap',action='store_true');ap.add_argument('--nodeep',action='store_true');ap.add_argument('--pre',default='');ap.add_argument('--batch',type=int,default=30)
    a=ap.parse_args()
    cells=json.load(open(a.cells,encoding='utf-8'));srv=serve(a.src,a.port);t0=time.time()
    n=min(a.procs,len(cells));jobs=[(w,cells[w::n],a.slime,json.loads(a.over),a.q,a.port,a.out,not a.nosnap,not a.nodeep,a.pre,a.batch) for w in range(n)]
    with mp.Pool(n) as P: P.map(work,jobs,chunksize=1)
    R=[]
    for w in range(n):
        for l in open(f'{a.out}.{w}.jsonl',encoding='utf-8'): R.append(json.loads(l))
    json.dump(R,open(a.out+'.json','w',encoding='utf-8'),ensure_ascii=False)
    print('done',len(R),'skip',sum(1 for r in R if (r.get('info') or {}).get('skip')),'err',sum(1 for r in R if r.get('err')),'secs',round(time.time()-t0));srv.shutdown()
