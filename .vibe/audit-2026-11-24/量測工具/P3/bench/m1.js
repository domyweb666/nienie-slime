(async()=>{window.requestAnimationFrame=()=>0;await new Promise(r=>setTimeout(r,80));
IMPSV.noSave=true;WALK.noSave=true;const log=[];const op=sfxPlay;sfxPlay=(k,g,r)=>{log.push([+t.toFixed(2),k])};
const DT=1/60;const steps=n=>{for(let i=0;i<n;i++)update(DT)};
const ev=(type,id,x,y)=>cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}));
const seeded=seed=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296}};
const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
const fresh=sd=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(65+sd*1000);setup();t=0;lastTouch=-10;nextTwitch=3;tLife=0;relaxUntil=-1;SLP.lastAny=-99;SLP.on=false;SLP.k=0;impReset();ESC.on=false;DENTS.length=0;BRAIN.seed=65+sd*1000;brainReset();Object.assign(MOOD,{c:0,a:0,strain:0,strainMax:0,scare:0,cowerUntil:-9,happyT:-9,wagT:-9,taps:[]});Object.assign(FLN,{at:-9,t0:-9,amp:0,H:1,s:1});PURR=0;INTRO.on=false;SWIM.on=false;steps(150);log.length=0};
const out=[];
const pat=(name,v,mode,sd)=>{fresh(sd);const px=v*60;const T=10;let purr=0,tP=null,cMax=-1,stMax=0,nS=0,nG=0,n=0,x0=globalC.xc,dx=0,lap=0;const t0=t;
 while(t-t0<T){const c=globalC;const [sx,sy]=scr(c.xc-R*.6,c.yc-R*.35);const L=R*1.2*CAM.z;let x=sx,dir=1;ev('pointerdown',1,x,sy);let moved=0,ok=null;const seg=mode==='lift'?L:1e9;
  while(moved<seg&&t-t0<T){let d=px*DT;x+=dir*d;moved+=d;if(mode!=='lift'){if(x>sx+L){x=sx+L;dir=-1}if(x<sx){x=sx;dir=1}}
   ev('pointermove',1,x,sy);steps(1);const f=fingers.get(1);if(f){if(f.mode==='stroke')ok='s';stMax=Math.max(stMax,SB(f)||0)}purr=Math.max(purr,PURR);if(tP==null&&PURR>.3)tP=+(t-t0).toFixed(2);cMax=Math.max(cMax,MOOD.c);dx=Math.max(dx,Math.abs(globalC.xc-x0)/R)}
  ev('pointerup',1,x,sy);n++;if(ok==='s')nS++;else nG++;for(let k=0;k<(mode==='lift'?18:1);k++){steps(1);purr=Math.max(purr,PURR);if(tP==null&&PURR>.3)tP=+(t-t0).toFixed(2);cMax=Math.max(cMax,MOOD.c)}}
 out.push({pat:mode,v,n,judgedStroke:nS,judgedGrab:nG,purrMax:+purr.toFixed(2),tPurr:tP,cMax:+cMax.toFixed(2),trust:+IMP.tr.toFixed(2),wary:+IMP.w.toFixed(2),shiftR:+dx.toFixed(2),stretchR:+stMax.toFixed(2),flee:ESC.on})};
for(const v of [1,2,3,5,6,7,8,10,12,15,20])pat('p',v,'lift',1);
for(const v of [1,2,3,5,8,12,15])pat('p',v,'rub',1);
return out})()
