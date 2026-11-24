(async()=>{window.requestAnimationFrame=()=>0;await new Promise(r=>setTimeout(r,80));
IMPSV.noSave=true;WALK.noSave=true;const log=[];const op=sfxPlay;sfxPlay=(k,g,r)=>{log.push([+t.toFixed(2),k])};
const DT=1/60;const steps=n=>{for(let i=0;i<n;i++)update(DT)};
const ev=(type,id,x,y)=>cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}));
const seeded=seed=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296}};
const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
const fresh=sd=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(65+sd*1000);setup();t=0;lastTouch=-10;nextTwitch=3;tLife=0;relaxUntil=-1;SLP.lastAny=-99;SLP.on=false;SLP.k=0;impReset();ESC.on=false;DENTS.length=0;BRAIN.seed=65+sd*1000;brainReset();Object.assign(MOOD,{c:0,a:0,strain:0,strainMax:0,scare:0,cowerUntil:-9,happyT:-9,wagT:-9,taps:[]});Object.assign(FLN,{at:-9,t0:-9,amp:0,H:1,s:1});PURR=0;INTRO.on=false;SWIM.on=false;steps(150);log.length=0};
const out=[];

const idle=(tr,mins,sd)=>{fresh(sd);IMP.tr=tr;IMPD.tr=tr;lastTouch=t;SLP.lastAny=t;const T0=t;let cur=null,c0=t;const bouts=[];let sn0=0,blink=0,bt=EYE.blinkT,user=0,still=0,sl=0;const vs={};log.length=0;let lastSig='';
 while(t-T0<mins*60){steps(1);const a=BRAIN.act;if(a!==cur){if(cur!=null)bouts.push([cur,+(t-c0).toFixed(1)]);cur=a;c0=t}
  if(EYE.blinkT!==bt){bt=EYE.blinkT;blink++}if(t<EYE.user)user++;if(SLP.on)sl++}
 bouts.push([cur,+(t-c0).toFixed(1)]);const agg={};for(const [k,d] of bouts){const o=agg[k]||(agg[k]={n:0,s:0,min:1e9,max:0});o.n++;o.s+=d;o.min=Math.min(o.min,d);o.max=Math.max(o.max,d)}for(const k in agg){agg[k].s=+agg[k].s.toFixed(0);agg[k].pct=+(100*agg[k].s/(mins*60)).toFixed(1)}
 for(const [tt,k] of log)vs[k]=(vs[k]||0)+1;
 const tr2={};for(let k=1;k<bouts.length;k++){const q=bouts[k-1][0]+'→'+bouts[k][0];tr2[q]=(tr2[q]||0)+1}
 out.push({tr,mins,n:bouts.length,agg,trans:Object.entries(tr2).sort((a,b)=>b[1]-a[1]).slice(0,12),blinks:blink,lookAtYouPct:+(100*user/(mins*3600)).toFixed(1),sleepPct:+(100*sl/(mins*3600)).toFixed(1),sfx:vs,naps:BRAIN.naps,e4:E4.count,leans:BMEM.leans,cats:DR.cats,short2s:bouts.filter(b=>b[1]<2).length})};
idle(.7,10,12);
return out})()
