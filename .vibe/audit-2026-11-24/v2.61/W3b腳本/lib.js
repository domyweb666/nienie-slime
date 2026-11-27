WALK.noSave=true;WALK.items.length=0;WALK.fall.length=0;WALK.leave.length=0;WALK.stuck=null;IMPSV.noSave=true;
const DT=1/60,LOG=[];sfxPlay=(k,g,r)=>{LOG.push([+t.toFixed(4),k,+(g==null?1:g).toFixed(3),+((r||1)).toFixed(3)])};
if(SFX){SFX.frame=()=>{};SFX.init=()=>{}}
const seeded=s=>{let x=s>>>0;return()=>{x=(x+0x6D2B79F5)>>>0;let q=Math.imul(x^(x>>>15),x|1);q^=q+Math.imul(q^(q>>>7),q|61);return((q^(q>>>14))>>>0)/4294967296}};
function ev(type,id,x,y){cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}))}
function steps(n,cb){for(let i=0;i<n;i++){update(DT);if(cb)cb(i)}}
const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
const K61={all0:Object.fromEntries(KEYS61.map(k=>[k,0]))};
function box(){let x0=1e9,x1=-1e9,y0=1e9,y1=-1e9;for(const i of bnd){x0=Math.min(x0,X[i]);x1=Math.max(x1,X[i]);y0=Math.min(y0,Y[i]);y1=Math.max(y1,Y[i])}return{x0,x1,y0,y1}}
// 打開：整條開機路徑（chooseSlime(i,true)），時鐘歸零，存的東西照 opt
function open(sd,opt){opt=opt||{};for(const id of [...fingers.keys()])ev('pointerup',id,0,0);fingers.clear();Math.random=seeded(sd);t=0;tLife=0;lastTouch=-10;nextTwitch=3;relaxUntil=-1;SLP.lastAny=-99;if('openT' in SLP)SLP.openT=0;ESC.on=false;DENTS.length=0;E2.tk.length=0;E4.count=0;E4.lastT=-99;E4.on=false;ECHO.prev=null;voice.last=-9;EYE.user=-9;SLP.wakeT=-9;EYE.nextBlink=2;LURE.on=false;
  for(const k in IMPS)delete IMPS[k];IMP.tr=opt.tr||0;IMP.w=0;BMEM.cell=[0,0,0,0,0];BMEM.side=0;BMEM.offerAt=-99;BRAIN.seed=20261114;BRAIN.naps=0;BRAIN.selfWake=0;
  if(opt.over)Object.assign(mat,opt.over);const i=opt.slime==null?2:opt.slime;SLIME=i;IMPS[SLIMES[i].id]={tr:opt.tr||0,w:0};
  if(opt.over)for(const k in PRESETS)for(const j in opt.over)PRESETS[k][j]=opt.over[j];
  chooseSlime(i,true,false);IMP.tr=opt.tr||0;IMPD.tr=IMP.tr;LOG.length=0}
