import sys,json,base64,os
D=os.path.dirname(os.path.abspath(__file__))+'/'
sys.path.insert(0,D+'tool')
from srv import *
from playwright.sync_api import sync_playwright
W='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/prototype/web'
K="skinU pullHold pullWhole pullSoft rough tapSoft petSlow wakeSoft nearFast greetLook brJit bumpSoft eyeTrue snd61".split()
Z={k:0 for k in K}
RUN="""async (a)=>{const [sl,over,seed,shots]=a;PB.slime(sl);PB.over=over;PB.fresh(seed);
 const out={h:[],p:[],img:{}};const st=()=>{let s=0;const m={x:[...X],y:[...Y],px:[...PX],qx:[...QX],qy:[...QY],N};return m};
 const hash=d=>{let h=2166136261;for(let i=0;i<d.length;i++){h^=d[i];h=Math.imul(h,16777619)}return h>>>0};
 const f64=m=>{const b=new Uint8Array(new Float64Array([...m.x,...m.y,...m.px,...m.qx,...m.qy,m.N]).buffer);return hash(b)};
 let n=0;const step=k=>{for(let i=0;i<k;i++){__NOW+=1000/60;update(1/60);if(++n%6===0){out.h.push(f64(st()));draw();out.p.push(hash(ctx.getImageData(0,0,cv.width,cv.height).data))}}};
 const shot=nm=>{if(shots){draw();out.img[nm]=cv.toDataURL('image/png')}};
 const P=(dx,dy)=>PB.scr(globalC.xc+dx*R,globalC.yc+dy*R);
 step(30);shot('平常');
 let a0=P(0,-.5);PB.ev('pointerdown',1,...a0);step(30);PB.ev('pointerup',1,...a0);step(40);
 a0=P(.2,-.6);PB.ev('pointerdown',1,...a0);for(let i=1;i<=24;i++){PB.ev('pointermove',1,a0[0]+i*5,a0[1]-i*9);step(1)}step(40);shot('拉遠');PB.ev('pointerup',1,a0[0]+120,a0[1]-216);step(90);
 let b0=P(-.5,-.2),c0=P(.5,-.2);PB.ev('pointerdown',1,...b0);PB.ev('pointerdown',2,...c0);for(let i=1;i<=24;i++){PB.ev('pointermove',1,b0[0]-i*4,b0[1]-i*5);PB.ev('pointermove',2,c0[0]+i*4,c0[1]-i*2);step(1)}step(50);shot('兩指');PB.ev('pointerup',1,0,0);PB.ev('pointerup',2,0,0);step(120);
 a0=P(-.5,0);PB.ev('pointerdown',1,...a0);for(let i=1;i<=20;i++){PB.ev('pointermove',1,a0[0]+i*10,a0[1]-i*2);step(1)}step(30);PB.ev('pointerup',1,0,0);step(60);
 out.draws=n;out.rem=REM.n;out.clear=SKIN_USED();return out}"""
INI="""(()=>{let a=12345;window.__NOW=1e6;Math.random=()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296};performance.now=()=>window.__NOW;Date.now=()=>1.7e12+window.__NOW;window.requestAnimationFrame=()=>0;window.setInterval=()=>0})()"""
def sess(b,port,q=''):
    cx=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True);cx.add_init_script(INI);pg=cx.new_page();pg.set_default_timeout(0);pg.errs=[];pg.on('pageerror',lambda e:pg.errs.append(str(e)[:200]));pg.warn=[];pg.on('console',lambda m:pg.warn.append(m.text[:80]) if m.type in('warning','error') else None)
    pg.goto(f'http://127.0.0.1:{port}/index.html'+q,wait_until='load');pg.wait_for_timeout(2500);pg.evaluate(open(D+'tool/probe.js',encoding='utf-8').read());pg.evaluate('PB.init()');pg.evaluate("window.SKIN_USED=()=>typeof SKIN==='undefined'?null:SKIN.used");return pg
if __name__=='__main__':
    a=serve(D+'web60',8991);c=serve(W,8992)
    with sync_playwright() as p:
        b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
        for sl in (2,0,1,5):
            R=[]
            for port,over in ((8991,{}),(8991,{}),(8992,Z),(8992,{**Z,'skinU':1})):
                pg=sess(b,port);R.append(pg.evaluate(RUN,[sl,over,777+sl,over.get('skinU')==1 and sl==2]));R[-1]['e']=pg.errs;R[-1]['w']=pg.warn;pg.context.close()
            df=lambda x,y,k:sum(1 for u,v in zip(x[k],y[k]) if u!=v)
            r0,r1,z,sk=R
            print('隻',sl,'取樣',len(r0['h']),'補點',r0['rem'],'| v60自比 狀態差',df(r0,r1,'h'),'畫面差',df(r0,r1,'p'),'| 全0 狀態差',df(r0,z,'h'),'畫面差',df(r0,z,'p'),'| 只開皮 狀態差',df(r0,sk,'h'),'畫面不同格',df(r0,sk,'p'),'皮用到',sk['clear'],'err',z['e'],sk['e'],sk['w'][:2],flush=True)
            if sk['img']:
                o='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/.vibe/audit-2026-11-24/v2.61/';os.makedirs(o,exist_ok=True)
                for k,v in sk['img'].items(): open(o+'皮-'+k+'.png','wb').write(base64.b64decode(v.split(',')[1]))
        b.close()
