(async()=>{window.requestAnimationFrame=()=>0;await new Promise(r=>setTimeout(r,80));
IMPSV.noSave=true;WALK.noSave=true;const log=[];const op=sfxPlay;sfxPlay=(k,g,r)=>{log.push([+t.toFixed(2),k])};
const DT=1/60;const steps=n=>{for(let i=0;i<n;i++)update(DT)};
const ev=(type,id,x,y)=>cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}));
const seeded=seed=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296}};
const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
const fresh=sd=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(65+sd*1000);setup();t=0;lastTouch=-10;nextTwitch=3;tLife=0;relaxUntil=-1;SLP.lastAny=-99;SLP.on=false;SLP.k=0;impReset();ESC.on=false;DENTS.length=0;BRAIN.seed=65+sd*1000;brainReset();Object.assign(MOOD,{c:0,a:0,strain:0,strainMax:0,scare:0,cowerUntil:-9,happyT:-9,wagT:-9,taps:[]});Object.assign(FLN,{at:-9,t0:-9,amp:0,H:1,s:1});PURR=0;INTRO.on=false;SWIM.on=false;steps(150);log.length=0};
const out=[];

const pat=(name,v,sd)=>{fresh(sd);const px=v*60;const T=10;let purr=0,tP=null,cMax=-1,stMax=0,nS=0,nG=0,nP=0,n=0,x0=globalC.xc,dx=0;const t0=t;
 while(t-t0<T){const c=globalC;let wx0,wy0,ux,uy,L;
  if(name==='short'){wx0=c.xc-R*.5;wy0=c.yc-R*.35;ux=1;uy=0;L=R*.8}
  else if(name==='down'){wx0=c.xc+R*.45;wy0=c.yc-R*.55;ux=0;uy=1;L=R*.9}
  else if(name==='outside'){wx0=c.xc-R*1.5;wy0=c.yc-R*.3;ux=1;uy=0;L=R*3}
  else if(name==='topdown'){wx0=c.xc-R*.45;wy0=c.yc-R*.6;ux=.6;uy=.8;L=R*1.0}
  const [sx,sy]=scr(wx0,wy0);L*=CAM.z;let moved=0,ok=null,x=sx,y=sy,pushed=false;ev('pointerdown',1,x,y);const m0=fingers.get(1)&&fingers.get(1).mode;
  while(moved<L&&t-t0<T){const d=px*DT;x+=ux*d;y+=uy*d;moved+=d;ev('pointermove',1,x,y);steps(1);const f=fingers.get(1);if(f){if(f.mode==='stroke')ok='s';else if(f.mode==='push')pushed=true;stMax=Math.max(stMax,SB(f)||0)}purr=Math.max(purr,PURR);if(tP==null&&PURR>.3)tP=+(t-t0).toFixed(2);cMax=Math.max(cMax,MOOD.c);dx=Math.max(dx,Math.hypot(globalC.xc-x0)/R)}
  ev('pointerup',1,x,y);n++;if(ok==='s')nS++;else if(m0==='push'||pushed)nP++;else nG++;for(let k=0;k<18;k++){steps(1);purr=Math.max(purr,PURR);if(tP==null&&PURR>.3)tP=+(t-t0).toFixed(2);cMax=Math.max(cMax,MOOD.c)}}
 out.push({pat:name,v,sd,n,s:nS,g:nG,push:nP,purr:+purr.toFixed(2),tP,c:+cMax.toFixed(2),tr:+IMP.tr.toFixed(2),w:+IMP.w.toFixed(2),shift:+dx.toFixed(2),st:+stMax.toFixed(2)})};
for(const nm of ['short','down','topdown','outside'])for(const v of [1.5,3,5,8])pat(nm,v,2);
for(const sd of [3,4,5])pat('short',3,sd);
// 揉太久會不會有變化：連續揉 120 秒，每 10 秒記呼嚕、舒服、想被摸、心情、身體姿勢
{fresh(1);const c=globalC;const [sx,sy]=scr(c.xc-R*.3,c.yc-R*.35);let x=sx,dir=1;ev('pointerdown',1,x,sy);const L=R*.6*CAM.z,px=5*60;const rec=[];let next=10;const t0=t;log.length=0;while(t-t0<120){x+=dir*px*DT;if(x>sx+L)dir=-1;if(x<sx)dir=1;ev('pointermove',1,x,sy);steps(1);if(t-t0>=next){rec.push([next,+PURR.toFixed(2),+MOOD.c.toFixed(2),+BRAIN.s.toFixed(2),+BRAIN.m.toFixed(2),fingers.get(1).mode]);next+=10}}ev('pointerup',1,x,sy);const voices={};for(const [tt,k] of log)if(/^voice/.test(k))voices[k]=(voices[k]||0)+1;out.push({rub120:rec,voices})}
return out})()
