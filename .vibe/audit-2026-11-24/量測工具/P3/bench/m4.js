(async()=>{window.requestAnimationFrame=()=>0;await new Promise(r=>setTimeout(r,80));
IMPSV.noSave=true;WALK.noSave=true;const log=[];const op=sfxPlay;sfxPlay=(k,g,r)=>{log.push([+t.toFixed(2),k])};
const DT=1/60;const steps=n=>{for(let i=0;i<n;i++)update(DT)};
const ev=(type,id,x,y)=>cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}));
const seeded=seed=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296}};
const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
const fresh=sd=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(65+sd*1000);setup();t=0;lastTouch=-10;nextTwitch=3;tLife=0;relaxUntil=-1;SLP.lastAny=-99;SLP.on=false;SLP.k=0;impReset();ESC.on=false;DENTS.length=0;BRAIN.seed=65+sd*1000;brainReset();Object.assign(MOOD,{c:0,a:0,strain:0,strainMax:0,scare:0,cowerUntil:-9,happyT:-9,wagT:-9,taps:[]});Object.assign(FLN,{at:-9,t0:-9,amp:0,H:1,s:1});if(typeof PET!=='undefined'){PET.g=0;PET.last=-9}PURR=0;INTRO.on=false;SWIM.on=false;steps(150);log.length=0};
const out=[];

const pat=(name,v,sd)=>{fresh(sd);const px=v*60;const T=8;let purr=0,tP=null,cMax=-1,stMax=0,n=0,x0=globalC.xc,y0=globalC.yc,dx=0;const t0=t;
 while(t-t0<T){const c=globalC;let wx0,wy0,ux,uy,L;
  if(name==='pet'){wx0=c.xc-R*.5;wy0=c.yc-R*.35;ux=1;uy=0;L=R*.8}
  else if(name==='pet12'){wx0=c.xc-R*.6;wy0=c.yc-R*.35;ux=1;uy=0;L=R*1.2}
  else if(name==='topdown'){wx0=c.xc-R*.45;wy0=c.yc-R*.6;ux=.6;uy=.8;L=R*1.0}
  else if(name==='pullEdgeUp'){wx0=c.xc;wy0=c.yc-R*.75;ux=0;uy=-1;L=R*2.5}
  else if(name==='pullSide'){wx0=c.xc+R*.75;wy0=c.yc-R*.1;ux=1;uy=-.3;L=R*1.4}
  else if(name==='pullCenterUp'){wx0=c.xc;wy0=c.yc;ux=0;uy=-1;L=R*2.5}
  const ul=Math.hypot(ux,uy);ux/=ul;uy/=ul;
  const [sx,sy]=scr(wx0,wy0);L*=CAM.z;let moved=0,x=sx,y=sy;ev('pointerdown',1,x,y);
  while(moved<L&&t-t0<T){const d=px*DT;x+=ux*d;y+=uy*d;moved+=d;ev('pointermove',1,x,y);steps(1);const f=fingers.get(1);if(f)stMax=Math.max(stMax,SB(f)||0);purr=Math.max(purr,PURR);if(tP==null&&PURR>.3)tP=+(t-t0).toFixed(2);cMax=Math.max(cMax,MOOD.c);dx=Math.max(dx,Math.hypot(globalC.xc-x0)/R)}
  ev('pointerup',1,x,y);n++;for(let k=0;k<18;k++){steps(1);purr=Math.max(purr,PURR);if(tP==null&&PURR>.3)tP=+(t-t0).toFixed(2);cMax=Math.max(cMax,MOOD.c)}}
 out.push({pat:name,v,n,purr:+purr.toFixed(2),tP,c:+cMax.toFixed(2),tr:+IMP.tr.toFixed(2),w:+IMP.w.toFixed(2),shift:+dx.toFixed(2),st:+stMax.toFixed(2)})};
for(const nm of ['pet','topdown'])for(const v of [1,3,5,8,15])pat(nm,v,2);
for(const v of [3])pat('pet12',v,2);
for(const nm of ['pullEdgeUp','pullSide','pullCenterUp'])for(const v of [3,6,12])pat(nm,v,2);
return out})()
