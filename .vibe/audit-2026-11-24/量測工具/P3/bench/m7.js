(async()=>{window.requestAnimationFrame=()=>0;await new Promise(r=>setTimeout(r,80));
IMPSV.noSave=true;WALK.noSave=true;const log=[];const op=sfxPlay;sfxPlay=(k,g,r)=>{log.push([+t.toFixed(2),k])};
const DT=1/60;const steps=n=>{for(let i=0;i<n;i++)update(DT)};
const ev=(type,id,x,y)=>cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}));
const seeded=seed=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296}};
const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
const fresh=sd=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(65+sd*1000);setup();t=0;lastTouch=-10;nextTwitch=3;tLife=0;relaxUntil=-1;SLP.lastAny=-99;SLP.on=false;SLP.k=0;impReset();ESC.on=false;DENTS.length=0;BRAIN.seed=65+sd*1000;brainReset();Object.assign(MOOD,{c:0,a:0,strain:0,strainMax:0,scare:0,cowerUntil:-9,happyT:-9,wagT:-9,taps:[]});Object.assign(FLN,{at:-9,t0:-9,amp:0,H:1,s:1});PURR=0;INTRO.on=false;SWIM.on=false;steps(150);log.length=0};
const out=[];

// 快點 3 下：第 3 下放開後多久開始逃、逃多遠、逃之前有沒有別的動作
for(const tr of [0,.8])for(const sd of [5,6,7]){fresh(sd);IMP.tr=tr;IMPD.tr=tr;const x0=globalC.xc,y0=globalC.yc;let esc=null;const acts=[];for(let k=0;k<3;k++){const [sx,sy]=scr(globalC.xc+R*.4,globalC.yc-R*.2);ev('pointerdown',1,sx,sy);for(let q=0;q<5;q++){steps(1);if(ESC.on&&esc==null)esc=t}ev('pointerup',1,sx,sy);const tu=t;if(ESC.on&&esc==null)esc=t;for(let q=0;q<10;q++){steps(1);if(ESC.on&&esc==null)esc=t}if(k===2){out.push({tr,sd,fleeDelayAfter3rd:esc==null?null:+(esc-tu).toFixed(3)})}}
 steps(120);out[out.length-1].movedPt=+Math.hypot(globalC.xc-x0,globalC.yc-y0).toFixed(0);out[out.length-1].mood=+BRAIN.m.toFixed(2);out[out.length-1].trustAfter=+IMP.tr.toFixed(2)}
// 手指放在旁邊：第一秒內牠有沒有先停（呼吸振幅、走路）再轉
{fresh(9);const c=globalC;const [sx,sy]=scr(c.xc+R*2.0,c.yc-R*.3);const g0=[EYE.gx,EYE.gy];const amp0=BR.amp;ev('pointerdown',1,sx,sy);const rec=[];for(let k=0;k<90;k++){steps(1);if(k%6===0)rec.push([+(k/60).toFixed(1),+EYE.gx.toFixed(2),LIFE.sns.length,+BR.amp.toFixed(3),LIFE.st])}ev('pointerup',1,sx,sy);out.push({beside:rec})}
return out})()
