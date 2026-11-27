(async()=>{window.requestAnimationFrame=()=>0;await new Promise(r=>setTimeout(r,80));
IMPSV.noSave=true;WALK.noSave=true;const log=[];const op=sfxPlay;sfxPlay=(k,g,r)=>{log.push([+t.toFixed(2),k])};
const DT=1/60;const steps=n=>{for(let i=0;i<n;i++)update(DT)};
const ev=(type,id,x,y)=>cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}));
const seeded=seed=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296}};
const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
const fresh=sd=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(65+sd*1000);setup();t=0;lastTouch=-10;nextTwitch=3;tLife=0;relaxUntil=-1;SLP.lastAny=-99;SLP.on=false;SLP.k=0;impReset();ESC.on=false;DENTS.length=0;BRAIN.seed=65+sd*1000;brainReset();Object.assign(MOOD,{c:0,a:0,strain:0,strainMax:0,scare:0,cowerUntil:-9,happyT:-9,wagT:-9,taps:[]});Object.assign(FLN,{at:-9,t0:-9,amp:0,H:1,s:1});PURR=0;INTRO.on=false;SWIM.on=false;steps(150);log.length=0};
const out=[];

// 戳一下：按 0.1 秒放開，記這一下排到多久後縮、縮多少
const tap=(wx,wy)=>{const [sx,sy]=scr(wx,wy);const t1=t;ev('pointerdown',1,sx,sy);const at=FLN.at;steps(6);ev('pointerup',1,sx,sy);const t0prev=FLN.t0;let amp=null,lat=null;for(let k=0;k<30;k++){steps(1);if(FLN.t0>=t1-1e-9&&amp==null&&FLN.t0!==t0prev||(FLN.t0>=t1&&amp==null)){amp=FLN.amp;lat=FLN.t0-t1}}return{amp:amp==null?0:+amp.toFixed(4),lat:lat==null?null:+lat.toFixed(3),wary:+IMP.w.toFixed(2),flee:ESC.on,H:+FLN.H.toFixed(2)}};
const row=[];
const serie=(isi,n,side)=>{fresh(7);const r=[];for(let k=0;k<n;k++){const c=globalC;r.push(tap(c.xc+side*R*.45,c.yc-R*.2));steps(Math.round(60*isi)-36)}return r};
out.push({isi:1.5,r:serie(1.5,8,1).map(x=>[x.amp,x.lat,x.H,x.wary,x.flee?1:0])});
out.push({isi:5,r:serie(5,8,1).map(x=>[x.amp,x.lat,x.H,x.wary,x.flee?1:0])});
out.push({isi:15,r:serie(15,5,1).map(x=>[x.amp,x.lat,x.H,x.wary,x.flee?1:0])});
// 同一處戳 5 下（間隔 2.5 秒），換到另一邊戳 1 下：有沒有換地方就變大（刺激特異性）
{fresh(8);const a=[];for(let k=0;k<5;k++){a.push(tap(globalC.xc+R*.45,globalC.yc-R*.2).amp);steps(114)}const b=tap(globalC.xc-R*.45,globalC.yc-R*.2).amp;out.push({sameSide5:a,otherSide:b})}
// 同一處戳 5 下，中間夾一個大動靜（大力拉一下放手），再戳同一處：有沒有去習慣化
{fresh(8);const a=[];for(let k=0;k<5;k++){a.push(tap(globalC.xc+R*.45,globalC.yc-R*.2).amp);steps(114)}
 const [sx,sy]=scr(globalC.xc,globalC.yc-R*.5);ev('pointerdown',1,sx,sy);for(let k=0;k<20;k++){ev('pointermove',1,sx+k*6,sy-k*5);steps(1)}ev('pointerup',1,sx+114,sy-95);const H1=FLN.H;steps(150);const b=tap(globalC.xc+R*.45,globalC.yc-R*.2);out.push({dishab:{five:a,afterYankH:+H1.toFixed(2),next:b.amp,nextH:b.H}})}
// 隔一段時間的恢復：戳 5 下後等 5、15、30、60 秒再戳
for(const w of [5,15,30,60]){fresh(8);const a=[];for(let k=0;k<5;k++){a.push(tap(globalC.xc+R*.45,globalC.yc-R*.2).amp);steps(60)}steps(w*60);out.push({rec:w,first:a[0],fifth:a[4],after:tap(globalC.xc+R*.45,globalC.yc-R*.2).amp})}
return out})()
