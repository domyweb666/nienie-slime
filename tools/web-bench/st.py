# usage: st.py <webdir> --tests T65,T67 --arms '[{"remeshHome":1},{"remeshHome":0}]' --reps 10 [--warm] [--procs 4] [--out f.json] [--pre file.js]
import sys, json, re, time, argparse, threading, http.server, socketserver, functools, os, multiprocessing as mp
sys.stdout.reconfigure(encoding='utf-8')
CH='C:/Program Files/Google/Chrome/Application/chrome.exe'
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*x): pass
class SV(socketserver.ThreadingTCPServer):
    allow_reuse_address=True; request_queue_size=256; daemon_threads=True
    def handle_error(self,*x): pass
def build(webdir, tests, arms, reps, warm, sd0, pre):
    src=open(os.path.join(webdir,'selftest.js'),encoding='utf-8').read()
    ms=[m for m in re.finditer(r'(?m)^  // (T\d+) ',src)]
    i1=ms[0].start(); blocks={}
    seen=[]
    for m in ms:
        if m.group(1) not in [s[0] for s in seen]: seen.append((m.group(1),m.start()))
    foot=src.rindex('  draw();\n  Object.assign(VIEW, VIEW0)')
    for k,(n,s) in enumerate(seen):
        e=seen[k+1][1] if k+1<len(seen) else foot
        blocks[n]=src[s:e]
    if warm:
        i65=dict(seen)['T65']; head=src[:i65]
    else: head=src[:i1]+'\n  res.PASS={};\n'
    body='const OUT=[];const ARMS=%s;const P54S=JSON.parse(JSON.stringify(PRE54));\n%s\n'%(json.dumps(arms),pre.replace('__SD0__',str(sd0)).replace('__REPS__',str(reps)))
    for n in [x for x in tests if x]:
        b=re.sub(r'seeded\((\d\d)\)',r'seeded(\1+SD*1000)',blocks[n]).replace('seed: 65','seed: 65+SD*1000').replace('seed: 61','seed: 61+SD*1000')
        body+='for(let ai=0;ai<ARMS.length;ai++)for(let SD=%d;SD<%d;SD++){for(const k in PRE54)PRE54[k]={...P54S[k],...ARMS[ai]};window.__T=[];\n%s\n const key=Object.keys(res).filter(k=>k.startsWith("%s_"))[0];OUT.push({test:"%s",arm:ai,sd:SD,val:JSON.parse(JSON.stringify(res[key])),trace:window.__T});}\n'%(sd0,sd0+reps,b,n,n)
    f=src[foot:].replace('return res;','return OUT;').replace('console.log(JSON.stringify(res, null, 1));','')
    return head+body+f
def run(a):
    webdir,js,port=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
        pg=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True).new_page()
        errs=[];pg.on('pageerror',lambda e:errs.append(str(e)))
        pg.set_default_timeout(0)
        pg.goto(f'http://127.0.0.1:{port}/index.html',wait_until='load');pg.wait_for_timeout(1500)
        r=pg.evaluate(js);b.close();return r if not errs else r+[{'err':errs[:3]}]
if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('webdir');ap.add_argument('--tests',default='T65');ap.add_argument('--arms',default='[{"remeshHome":1},{"remeshHome":0}]')
    ap.add_argument('--reps',type=int,default=10);ap.add_argument('--warm',action='store_true');ap.add_argument('--procs',type=int,default=4);ap.add_argument('--out');ap.add_argument('--pre');ap.add_argument('--port',type=int,default=8951);ap.add_argument('--sd0',type=int,default=0);ap.add_argument('--full',type=int,default=0)
    a=ap.parse_args();arms=json.loads(a.arms)
    socketserver.ThreadingTCPServer.allow_reuse_address=True;socketserver.ThreadingTCPServer.request_queue_size=256;socketserver.ThreadingTCPServer.daemon_threads=True
    srv=SV(('127.0.0.1',a.port),functools.partial(Q,directory=a.webdir));threading.Thread(target=srv.serve_forever,daemon=True).start()
    pre=open(a.pre,encoding='utf-8').read() if a.pre else ''
    t0=time.time();jobs=[]
    if a.full:
        js=open(os.path.join(a.webdir,'selftest.js'),encoding='utf-8').read();jobs=[js]*a.full
    else:
        per=max(1,a.reps//a.procs) if not a.warm else a.reps
        n=a.procs if a.warm else -(-a.reps//per)
        for i in range(n): jobs.append(build(a.webdir,a.tests.split(','),arms,per if a.warm else min(per,a.reps-i*per),a.warm,a.sd0+(i*per),pre))
    with mp.Pool(len(jobs) if a.full or a.warm else min(a.procs,len(jobs))) as P: R=P.map(run,[(a.webdir,j,a.port) for j in jobs],chunksize=1)
    if a.full:
        if a.out: json.dump(R,open(a.out,'w',encoding='utf-8'),ensure_ascii=False)
        for r in R: print('ALL' if r.get('ALL_PASS') else 'FAIL',[k for k,v in r['PASS'].items() if not v],r.get('T65_endless'),r.get('T67_remeshCalm'),r.get('T68_settle'))
    else:
        O=[x for r in R for x in r]
        if a.out: json.dump(O,open(a.out,'w',encoding='utf-8'),ensure_ascii=False)
        for x in sorted(O,key=lambda x:(x.get('test',''),x.get('arm',0),x.get('sd',0))):
            v=x.get('val')
            if x.get('test')=='T65': print('T65 arm%d sd%2d up gap %.2f held %.2f after %.2f xs %d | diag gap %.2f held %.2f after %.2f xs %d'%(x['arm'],x['sd'],v['up']['gap'],v['up']['held'],v['up']['after'],v['up']['xs'],v['diag']['gap'],v['diag']['held'],v['diag']['after'],v['diag']['xs']))
            elif 'tr' in x:
                print({k:v for k,v in x.items() if k!='tr'})
                for q in x['tr']: print('  ',q)
            else: print(x.get('test'),'arm',x.get('arm'),'sd',x.get('sd'),json.dumps(v if v is not None else x)[:700])
    print('secs',round(time.time()-t0));srv.shutdown()
