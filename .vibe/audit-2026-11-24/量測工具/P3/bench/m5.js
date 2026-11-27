(async()=>{window.requestAnimationFrame=()=>0;await new Promise(r=>setTimeout(r,80));
IMPSV.noSave=true;WALK.noSave=true;const log=[];const op=sfxPlay;sfxPlay=(k,g,r)=>{log.push([+t.toFixed(2),k])};
const DT=1/60;const steps=n=>{for(let i=0;i<n;i++)update(DT)};
const ev=(type,id,x,y)=>cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}));
const seeded=seed=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296}};
const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
const fresh=sd=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(65+sd*1000);setup();t=0;lastTouch=-10;nextTwitch=3;tLife=0;relaxUntil=-1;SLP.lastAny=-99;SLP.on=false;SLP.k=0;impReset();ESC.on=false;DENTS.length=0;BRAIN.seed=65+sd*1000;brainReset();Object.assign(MOOD,{c:0,a:0,strain:0,strainMax:0,scare:0,cowerUntil:-9,happyT:-9,wagT:-9,taps:[]});Object.assign(FLN,{at:-9,t0:-9,amp:0,H:1,s:1});PURR=0;INTRO.on=false;SWIM.on=false;steps(150);log.length=0};
const out=[];

const tap=(wx,wy)=>{const [sx,sy]=scr(wx,wy);const t1=t;ev('pointerdown',1,sx,sy);const at=FLN.at;steps(6);ev('pointerup',1,sx,sy);const t0prev=FLN.t0;let amp=null,lat=null;for(let k=0;k<30;k++){steps(1);if(FLN.t0>=t1-1e-9&&amp==null&&FLN.t0!==t0prev||(FLN.t0>=t1&&amp==null)){amp=FLN.amp;lat=FLN.t0-t1}}return{amp:amp==null?0:+amp.toFixed(4),lat:lat==null?null:+lat.toFixed(3),wary:+IMP.w.toFixed(2),flee:ESC.on,H:+FLN.H.toFixed(2)}};

const run=(isi,n,tr)=>{fresh(7);IMP.tr=tr;IMPD.tr=tr;const r=[[0,null,+BRAIN.m.toFixed(2),+IMP.w.toFixed(2),+BRAIN.f.toFixed(2)]];for(let k=0;k<n;k++){const c=globalC;const q=tap(c.xc+R*.45,c.yc-R*.2);r.push([k+1,q.amp,+BRAIN.m.toFixed(2),+IMP.w.toFixed(2),+BRAIN.f.toFixed(2)]);steps(Math.round(60*isi)-36)}return r};
out.push({isi:2.5,tr:0,r:run(2.5,6,0)});
out.push({isi:2.5,tr:.8,r:run(2.5,6,.8)});
out.push({isi:20,tr:.8,r:run(20,5,.8)});
// 戳 5 下後放著，心情多久回到 0
{fresh(7);for(let k=0;k<5;k++){tap(globalC.xc+R*.45,globalC.yc-R*.2);steps(114)}const a=[[0,+BRAIN.m.toFixed(2)]];for(const T of [30,60,120]){const t1=t;while(t-t1<T)steps(1);a.push([T,+BRAIN.m.toFixed(2)])}out.push({moodAfter5taps:a})}
return out})()
