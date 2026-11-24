import sys,json,base64,os
D='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/t70/'
sys.path.insert(0,D+'tool')
from srv import *
from playwright.sync_api import sync_playwright
INI="""(()=>{let a=12345;window.__NOW=1e6;Math.random=()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296};performance.now=()=>window.__NOW;Date.now=()=>1.7e12+window.__NOW;window.requestAnimationFrame=()=>0;window.setInterval=()=>0})()"""
HLP="""window.SH={img:{},take(nm){const S0=mat.skinU;for(const s of [0,1]){mat.skinU=s;draw();SH.img[nm+'_s'+s]=cv.toDataURL('image/png')}
  // 拆：關折射、關水
  for(const s of [0,1]){mat.skinU=s;LAB.off.refr=true;draw();SH.img[nm+'_s'+s+'_norefr']=cv.toDataURL('image/png');LAB.off.refr=false}
  {mat.skinU=1;const w0=SKINT.w,b=VIEW.bg;VIEW.bg="blue";SKINT.w=0;draw();SH.img[nm+"_nocap"]=cv.toDataURL("image/png");SKINT.w=w0;VIEW.bg=b;let fl=0;for(let k=0;k<TRI.length;k+=3){const a=TRI[k],b=TRI[k+1],c=TRI[k+2];if((X[b]-X[a])*(Y[c]-Y[a])-(Y[b]-Y[a])*(X[c]-X[a])<0)fl++}SH.img[nm+"_flip"]=[fl,TRI.length/3]}
  // 拆：背景單色（看得到的東西都不在後面）
  for(const s of [0,1]){mat.skinU=s;const b=VIEW.bg;VIEW.bg='blue';draw();SH.img[nm+'_s'+s+'_plain']=cv.toDataURL('image/png');VIEW.bg=b}
  // 遮罩本身：h2（畫面讀出來的模糊遮罩）、原始遮罩
  for(const s of [0,1]){mat.skinU=s;draw();const gl=JEL.gl,w=JEL.h2.w,h=JEL.h2.h,b=new Float32Array(w*h*4);gl.bindFramebuffer(gl.FRAMEBUFFER,JEL.h2.f);gl.readPixels(0,0,w,h,gl.RGBA,gl.FLOAT,b);gl.bindFramebuffer(gl.FRAMEBUFFER,null);SH.img[nm+'_s'+s+'_h2']=[w,h,Array.from({length:w*h},(_,i)=>+b[i*4].toFixed(4))];const w2=JEL.q2.w,hh2=JEL.q2.h,c=new Float32Array(w2*hh2*4);gl.bindFramebuffer(gl.FRAMEBUFFER,JEL.q2.f);gl.readPixels(0,0,w2,hh2,gl.RGBA,gl.FLOAT,c);gl.bindFramebuffer(gl.FRAMEBUFFER,null);SH.img[nm+'_s'+s+'_q2']=[w2,hh2,Array.from({length:w2*hh2},(_,i)=>+c[i*4].toFixed(4))]}
  mat.skinU=S0}};"""
RUN="""async ()=>{PB.slime(2);PB.over={};PB.fresh(779);
 const step=k=>{for(let i=0;i<k;i++){__NOW+=1000/60;update(1/60);if(i%6===0)draw()}};const P=(dx,dy)=>PB.scr(globalC.xc+dx*R,globalC.yc+dy*R);
 step(30);SH.take('平常');
 let a0=P(0,-.5);PB.ev('pointerdown',1,...a0);step(30);PB.ev('pointerup',1,...a0);step(40);
 a0=P(.2,-.6);PB.ev('pointerdown',1,...a0);for(let i=1;i<=24;i++){PB.ev('pointermove',1,a0[0]+i*5,a0[1]-i*9);step(1)}step(40);SH.take('拉遠');PB.ev('pointerup',1,a0[0]+120,a0[1]-216);step(90);
 let b0=P(-.5,-.2),c0=P(.5,-.2);PB.ev('pointerdown',1,...b0);PB.ev('pointerdown',2,...c0);for(let i=1;i<=24;i++){PB.ev('pointermove',1,b0[0]-i*4,b0[1]-i*5);PB.ev('pointermove',2,c0[0]+i*4,c0[1]-i*2);step(1)}step(50);SH.take('兩指');PB.ev('pointerup',1,0,0);PB.ev('pointerup',2,0,0);step(120);
 const r=SH.img;SH.img={};return r}"""
# 細脖子：最糟批裡找脖子最細的一格（先跑一遍找，再跑一遍停在那格畫）
NECK="""async cells=>{let best=null;for(const c of cells){PB.trace=[];PB.deep=false;PB.run(c);for(const q of PB.trace){if((q.ph==='hold')&&q.nk>.03&&q.nk<.11&&q.len<6.5&&q.fl<60&&(!best||q.nk<best.nk))best={nk:q.nk,fr:q.fr,ph:q.ph,c:c,len:q.len,x:q.x,fl:q.fl}}}PB.trace=null;return best}"""
NECK2="""async b=>{const s0=PB.step;let n=0;PB.trace=[];PB.step=(a,v)=>{const r=s0(a,v);if(PB.trace.at(-1).fr===b.fr){SH.info=PB.trace.at(-1);SH.take('細脖子')}return r};PB.deep=false;PB.begin('x','x',1);const c=b.c;PB.run(c);PB.step=s0;PB.trace=null;const r=SH.img;SH.img={};r.info=SH.info;return r}"""
srv=serve(D+'v61/prototype/web',9100);cells=json.load(open(D+'../combo/c_gone.json',encoding='utf-8'))
out={}
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
    def sess():
        cx=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True);cx.add_init_script(INI);pg=cx.new_page();pg.set_default_timeout(0);pg.on('pageerror',lambda e:print('ERR',e))
        pg.goto('http://127.0.0.1:9100/index.html',wait_until='load');pg.wait_for_timeout(2500);pg.evaluate(open(D+'tool/probe.js',encoding='utf-8').read());pg.evaluate('PB.init()');pg.evaluate(HLP);return pg
    pg=sess();out.update(pg.evaluate(RUN));pg.context.close()
    pg=sess();pg.evaluate('PB.slime(2);PB.over={}')
    best=pg.evaluate(NECK,[c for c in cells]);print(best,flush=True)
    pg.context.close();pg=sess();pg.evaluate('PB.slime(2);PB.over={}')
    r=pg.evaluate(NECK2,best);print('info',r.pop('info',None));out.update(r)
    b.close()
srv.shutdown()
for k,v in out.items():
    if isinstance(v,str): open(D+'out/'+k+'.png','wb').write(base64.b64decode(v.split(',')[1]))
json.dump({k:v for k,v in out.items() if not isinstance(v,str)},open(D+'out/masks.json','w',encoding='utf-8'))
print(sorted(out))
