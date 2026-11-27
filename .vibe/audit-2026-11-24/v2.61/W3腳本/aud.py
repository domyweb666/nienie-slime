# 真的 AudioContext（無靜音旗標）跑真頁面：按住揉 2 秒，看 rubV 播的是哪個 buffer、雨的目標、缺檔時退回、切 0
import sys,json,time
from drv import *
from playwright.sync_api import sync_playwright
src,port=sys.argv[1],int(sys.argv[2]);srv=serve(src,port)
JS=r'''async()=>{const out={};const wait=ms=>new Promise(r=>setTimeout(r,ms));const S=SFX;let last=null,KEEP=null;const oc=AudioContext.prototype.createBufferSource;AudioContext.prototype.createBufferSource=function(){const n=oc.call(this);const st=n.start;n.start=function(){if(n.loop&&n.buffer&&[...(KEEP||[]),...(S.buf['rub.loop']||[])].includes(n.buffer))last=n.buffer;return st.apply(this,arguments)};return n};
S.init();await S.ctx.resume();for(let i=0;i<60&&!((S.buf['rub.loop61']||[]).length>=4&&(S.buf['rub.loop']||[]).length>=4);i++)await wait(100);
out.files=[(S.buf['rub.loop']||[]).length,(S.buf['rub.loop61']||[]).length];
KEEP=S.buf['rub.loop61'];for(let i=0;i<120;i++)update(1/60);const which=()=>last?(KEEP.includes(last)?'rub.loop61':(S.buf['rub.loop']||[]).includes(last)?'rub.loop':'別的'):null;
const rub=async(n)=>{last=null;const x=W/2,y=globalC.yc;const ev=(t,a,b)=>cv.dispatchEvent(new PointerEvent(t,{pointerId:1,clientX:a,clientY:b,bubbles:true,pointerType:'touch',isPrimary:true}));ev('pointerdown',x,y);let lv=0,tg=null;const gm=S.bgmG;for(let i=0;i<n;i++){ev('pointermove',x+Math.sin(i/4)*R*.5,y);update(1/60);if(S.rubV)lv=Math.max(lv,S.rubV.level);tg=S.bgmT;await wait(8)}ev('pointerup',x,y);for(let i=0;i<90;i++){update(1/60);await wait(4)}return {buf:which(),level:+lv.toFixed(3),雨目標:tg,放開:S.bgmT,停:S.rubV===null}};
S.amb='rain';out.on=await rub(90);mat.snd61=0;out.off=await rub(90);mat.snd61=1;const keep=S.buf['rub.loop61'];S.buf['rub.loop61']=[];out.缺檔=await rub(90);delete S.buf['rub.loop61'];out.沒這層=await rub(60);S.buf['rub.loop61']=keep;
for(const a of ['fire','noise','lofi']){S.amb=a;out[a]=(await rub(40)).雨目標}S.amb='rain';
// OfflineAudioContext：同一段參數算出來的 RMS（新 vs 舊），確認檔真的有聲音
const rms=async b=>{const o=new OfflineAudioContext(1,44100*2,44100),s=o.createBufferSource(),g=o.createGain();s.buffer=b;s.loop=true;g.gain.value=.35;s.connect(g);g.connect(o.destination);s.start();const r=(await o.startRendering()).getChannelData(0);let q=0;for(const v of r)q+=v*v;return +(10*Math.log10(q/r.length)).toFixed(1)};
out.rms舊=[];for(const b of S.buf['rub.loop'])out.rms舊.push(await rms(b));out.rms新=[];for(const b of S.buf['rub.loop61'])out.rms新.push(await rms(b));
out.FEELVER=FEELVER;out.ver=document.querySelector('.feel-ver').textContent;out.text=deskText().slice(0,60);return out}'''
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--autoplay-policy=no-user-gesture-required'])
    pg=b.new_context(viewport={'width':393,'height':852},has_touch=True).new_page();pg.add_init_script(INIT);errs=[];pg.on('pageerror',lambda e:errs.append(str(e)[:200]))
    pg.goto(f'http://127.0.0.1:{port}/index.html');pg.wait_for_timeout(1500);r=pg.evaluate(JS);b.close()
for k,v in r.items():print(k,json.dumps(v,ensure_ascii=False))
print(errs);srv.shutdown()
