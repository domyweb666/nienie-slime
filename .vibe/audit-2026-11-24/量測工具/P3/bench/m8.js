(async()=>{window.requestAnimationFrame=()=>0;await new Promise(r=>setTimeout(r,80));
IMPSV.noSave=true;WALK.noSave=true;const log=[];const op=sfxPlay;sfxPlay=(k,g,r)=>{log.push([+t.toFixed(2),k])};
const DT=1/60;const steps=n=>{for(let i=0;i<n;i++)update(DT)};
const ev=(type,id,x,y)=>cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}));
const seeded=seed=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296}};
const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
const fresh=sd=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(65+sd*1000);setup();t=0;lastTouch=-10;nextTwitch=3;tLife=0;relaxUntil=-1;SLP.lastAny=-99;SLP.on=false;SLP.k=0;impReset();ESC.on=false;DENTS.length=0;BRAIN.seed=65+sd*1000;brainReset();Object.assign(MOOD,{c:0,a:0,strain:0,strainMax:0,scare:0,cowerUntil:-9,happyT:-9,wagT:-9,taps:[]});Object.assign(FLN,{at:-9,t0:-9,amp:0,H:1,s:1});PURR=0;INTRO.on=false;SWIM.on=false;steps(150);log.length=0};
const out=[];

for(const tr of [0,.8])for(const dR of [1.6,2.2,3.0])for(const sd of [1,2,3]){fresh(sd);IMP.tr=tr;IMPD.tr=tr;LIFE.st='rest';LIFE.until=t+20;steps(30);const c=globalC;const [sx,sy]=scr(c.xc+R*dR,c.yc-R*.2);const t1=t,gx0=EYE.gx;ev('pointerdown',1,sx,sy);let tg=null,ts=null,tw=null,mode=fingers.get(1)&&fingers.get(1).mode;const hx=HOMEX;for(let k=0;k<180;k++){steps(1);if(tg==null&&EYE.gx>.6)tg=+(t-t1).toFixed(2);if(ts==null&&LIFE.sns.length)ts=+(t-t1).toFixed(2);if(tw==null&&Math.abs(HOMEX-hx)>R*.03)tw=+(t-t1).toFixed(2)}ev('pointerup',1,sx,sy);out.push({tr,dR,sd,mode,gaze:tg,pod:ts,move:tw})}
return out})()
