window.requestAnimationFrame=()=>0; await new Promise(r=>setTimeout(r,100));
WALK.noSave=true;WALK.items.length=0;WALK.fall.length=0;WALK.leave.length=0;WALK.stuck=null;IMPSV.noSave=true;
const DT=1/60, LOG=[]; const oPlay=sfxPlay; sfxPlay=(k,g,r)=>{LOG.push([+t.toFixed(3),k,+(g==null?1:g).toFixed(3),+((r||1)).toFixed(3)])};
if(SFX)SFX.frame=()=>{};
const seeded=s=>{let x=s>>>0;return()=>{x=(x+0x6D2B79F5)>>>0;let q=Math.imul(x^(x>>>15),x|1);q^=q+Math.imul(q^(q>>>7),q|61);return((q^(q>>>14))>>>0)/4294967296}};
function ev(type,id,x,y){cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}))}
function steps(n,cb){for(let i=0;i<n;i++){update(DT);if(cb)cb(i)}}
const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
function geo(){let x0=1e9,x1=-1e9,y0=1e9,y1=-1e9,A=0;const n=bnd.length;for(let i=0;i<n;i++){const a=bnd[i],b=bnd[(i+1)%n];A+=X[a]*Y[b]-X[b]*Y[a];x0=Math.min(x0,X[a]);x1=Math.max(x1,X[a]);y0=Math.min(y0,Y[a]);y1=Math.max(y1,Y[a])}return{w:x1-x0,h:y1-y0,cx:globalC.xc,cy:globalC.yc,x0,x1,y0,y1,A:Math.abs(A)/2}}
// fresh page-like state with default parameters (same as chooseSlime on load)
function fresh(sd,over,opt){opt=opt||{};for(const id of [...fingers.keys()])ev('pointerup',id,0,0);fingers.clear();Math.random=seeded(sd||1);
  const s=SLIMES[opt.slime==null?2:opt.slime];SLIME=opt.slime==null?2:opt.slime;mat={...PRESETS[s.mat],seed:s.seed,...s.p,...viewOver(),...(over||{})};
  t=0;tLife=0;setup();t=0;lastTouch=-10;nextTwitch=3;tLife=0;relaxUntil=-1;SLP.lastAny=-99;impReset();IMP.tr=opt.tr||0;IMP.w=opt.w||0;IMPD.tr=IMP.tr;IMPD.w=IMP.w;ESC.on=false;E2.tk.length=0;DENTS.length=0;E4.count=0;E4.lastT=-99;E4.on=false;
  Object.assign(BRAIN,{seed:sd||1,naps:0,selfWake:0});brainReset();BMEM.cell=[0,0,0,0,0];BMEM.side=0;BMEM.offerAt=-99;BMEM.leans=0;E2.leanS=0;E2.nuzT0=-1;MOOD.taps=[];voice.last=-9;EYE.user=-9;SLP.wakeT=-9;
  steps(opt.settle==null?150:opt.settle);LOG.length=0}
const r2=v=>Math.round(v*100)/100,r3=v=>Math.round(v*1000)/1000;
