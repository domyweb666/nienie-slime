window.requestAnimationFrame=()=>0; await new Promise(r=>setTimeout(r,100));
WALK.noSave=true;WALK.items.length=0;WALK.fall.length=0;WALK.leave.length=0;WALK.stuck=null;IMPSV.noSave=true;
const DT=1/60, LOG=[]; sfxPlay=(k,g,r)=>{LOG.push([+t.toFixed(3),k])};
const VO=[];const oV=voice;voice=function(k,g){VO.push([+t.toFixed(3),k]);};voice.last=-9;
if(SFX)SFX.frame=()=>{};
const seeded=s=>{let x=s>>>0;return()=>{x=(x+0x6D2B79F5)>>>0;let q=Math.imul(x^(x>>>15),x|1);q^=q+Math.imul(q^(q>>>7),q|61);return((q^(q>>>14))>>>0)/4294967296}};
function ev(type,id,x,y){cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}))}
function steps(n,cb){for(let i=0;i<n;i++){update(DT);if(cb)cb(i)}}
const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
function fresh(sd,over,opt){opt=opt||{};for(const id of [...fingers.keys()])ev('pointerup',id,0,0);fingers.clear();Math.random=seeded(sd||1);
  const si=opt.slime==null?2:opt.slime,s=SLIMES[si];SLIME=si;VIEW.bg='day';VIEW.win='';mat={...PRESETS[s.mat],seed:s.seed,...s.p,...viewOver(),...(over||{})};if(opt.noDeco)mat.deco=0;
  t=0;tLife=0;setup();t=0;lastTouch=-10;nextTwitch=3;tLife=0;relaxUntil=-1;SLP.lastAny=-99;SLP.on=false;SLP.k=0;impReset();IMP.tr=opt.tr||0;IMP.w=opt.w||0;IMPD.tr=IMP.tr;IMPD.w=IMP.w;ESC.on=false;E2.tk.length=0;DENTS.length=0;E4.count=0;E4.lastT=-99;E4.on=false;
  Object.assign(BRAIN,{seed:sd||1,naps:0,selfWake:0});brainReset();BMEM.cell=[0,0,0,0,0];BMEM.side=0;BMEM.offerAt=-99;BMEM.leans=0;E2.leanS=0;E2.nuzT0=-1;voice.last=-9;EYE.user=-9;EYE.sqU=-9;SLP.wakeT=-9;
  Object.assign(MOOD,{c:0,a:0,strain:0,strainMax:0,scare:0,cowerUntil:-9,happyT:-9,wagT:-9,taps:[]});Object.assign(FLN,{at:-9,t0:-9,amp:0,H:1,s:1,tc:1,tcq:false,tpAt:-9});Object.assign(MC,{c:0,s:0,w:0,z:0});PURR=0;INTRO.on=false;SWIM.on=false;if(typeof GREET!=='undefined')Object.assign(GREET,{st:'',until:-9,at:-9});EYE.gx=0;EYE.gy=0;if('openT' in SLP)SLP.openT=-99;if(typeof petReset==='function')petReset();if(typeof MOOD.tugS==='number')MOOD.tugS=0;MOOD.tugX=MOOD.tugY=0;REM.n=0;
  steps(opt.settle==null?150:opt.settle);LOG.length=0;VO.length=0}
const r2=v=>Math.round(v*100)/100,r3=v=>Math.round(v*1000)/1000;
// 抓外框上某個方向的點（往裡 0.2R），往 (ux,uy) 拉 dist R，速度 v R/秒（螢幕），停 hold 秒，放
function edgePt(ux,uy,inn){let b=-1,bv=-1e9;for(const i of bnd){const q=X[i]*ux+Y[i]*uy;if(q>bv){bv=q;b=i}}return[X[b]-ux*R*(inn==null?.2:inn),Y[b]-uy*R*(inn==null?.2:inn)]}
function pull(o){const l=Math.hypot(o.ux,o.uy),ux=o.ux/l,uy=o.uy/l,[wx,wy]=o.center?[globalC.xc,globalC.yc]:edgePt(o.gx==null?ux:o.gx,o.gy==null?uy:o.gy,o.inn);const [sx,sy]=scr(wx,wy);const R0={red:0,strain:0,sq:0,esc:false,lost:null,zmin:9,vMax:0,st:0,purr:0,yank:false};
  const tr0=IMP.tr,w0=IMP.w,c0=BRAIN.m;let k=0;const T=o.dist/o.v,n=Math.max(1,Math.round(T*60));
  const rec=()=>{const f=fingers.get(1);if(!f||f.mode!=='grab'){if(R0.lost==null)R0.lost=r2(k/60)}else{R0.vMax=Math.max(R0.vMax,f.vMax||0);R0.st=Math.max(R0.st,SB(f));R0.yank=R0.yank||!!f.yank}R0.red=Math.max(R0.red,MC.s);R0.strain=Math.max(R0.strain,MOOD.strain);if(EYE.mode==='squeeze')R0.sq++;R0.zmin=Math.min(R0.zmin,CAM.z);R0.purr=Math.max(R0.purr,PURR);k++};
  const vo0=VO.length;ev('pointerdown',1,sx,sy);steps(o.pre==null?3:o.pre,rec);
  const dd=o.dist*R*1;let x=sx,y=sy;for(let j=1;j<=n;j++){x=sx+ux*dd*j/n;y=sy+uy*dd*j/n;ev('pointermove',1,x,y);update(DT);rec()}
  steps(Math.round((o.hold||0)*60),rec);const lost0=R0.lost;ev('pointerup',1,x,y);R0.esc=ESC.on;steps(2);R0.esc=R0.esc||ESC.on;
  R0.lost=lost0;R0.dTr=r3(IMP.tr-tr0);R0.dW=r3(IMP.w-w0);R0.dM=r3(BRAIN.m-c0);R0.vo=VO.slice(vo0).map(v=>v[1]).join(',');
  for(const q of ['red','strain','zmin','vMax','st','purr'])R0[q]=r2(R0[q]);steps(Math.round((o.after==null?1:o.after)*60),()=>{});return R0}

const CFG={def:{},A3:{pullHold:1},A4:{pullWhole:1},A5:{pullSoft:1},all:{pullHold:1,pullWhole:1,pullSoft:1},def_r0:{rough:0},A5_r0:{pullSoft:1,rough:0},all_r0:{pullHold:1,pullWhole:1,pullSoft:1,rough:0}};
const ext=A=>{let a=1e9,b=-1e9;for(const i of bnd){a=Math.min(a,A[i]);b=Math.max(b,A[i])}return (b-a)/R};
const blen=()=>Math.hypot(ext(X),ext(Y));
const av=a=>a.length?a.reduce((s,x)=>s+x,0)/a.length:null;
