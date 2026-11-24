// 摸起來的物理會不會跟情緒變：固定同一組手指動作，量「材料」的數字
// 1) 按住不動 0.6 秒：按下去的凹陷與面積變化、牠自己的推力不算（E2 nudge 關）
// 2) 慢拉 1.5R 停 0.5 秒：被抓那塊跟手指差多少、重心被帶走多少、身體拉長多少
// 3) 放手：33、100、200、400、1000 ms 的長度；彈幾下
// 4) 快扯 1.5R（6 幀）
const ST={neutral:{},trust:{tr:.9},wary:{w:.9},comfort:{f:()=>{MOOD.c=1;MOOD.a=.15}},scare:{f:()=>{MOOD.scare=1}},asleepPose:{f:()=>{SLP.k=1}},moodGood:{f:()=>{BRAIN.m=.8;BRAIN.mS=.8}},moodBad:{f:()=>{BRAIN.m=-.8;BRAIN.mS=-.8}},happy:{f:()=>{MOOD.happyT=t-.1}},strain:{f:()=>{MOOD.strain=1}}};
const len=(ux,uy)=>{let a=-1e9,b=1e9;for(const i of bnd){const p=X[i]*ux+Y[i]*uy;a=Math.max(a,p);b=Math.min(b,p)}return(a-b)/R};
const out={};
for(const k in ST){const s=ST[k];const rec={};
 for(const [nm,frames] of [['slow',45],['fast',6]]){
  // 關掉會自己出手的反應（縮、傾、推、蹭、逃、想逃），只留「情緒 → 身體」的路：看材料
  fresh(21,{deco:0,decoReal:0,lifeFlinch:0,e2:0,flee:0,echo:0},{tr:s.tr||0,w:s.w||0,settle:240});
  const keep=()=>{LIFE.st='rest';LIFE.until=t+1e6;GAIT.on=false;BRX.sighNext=t+99;IMP.tr=s.tr||0;IMP.w=s.w||0;IMPD.tr=IMP.tr;IMPD.w=IMP.w;if(s.f)s.f()};
  for(let i=0;i<240;i++){keep();update(DT)}
  const g0=geo(),ux=.45,uy=-.893;let bi=0,bd=-1e9;for(const i of bnd){const p=(X[i]-globalC.xc)*ux+(Y[i]-globalC.yc)*uy;if(p>bd){bd=p;bi=i}}
  const[sx,sy]=scr(X[bi]-ux*R*.3,Y[bi]-uy*R*.3);const L0=len(ux,uy);
  ev('pointerdown',1,sx,sy);for(let i=0;i<4;i++){keep();update(DT)}
  const D=1.5*R;for(let i=1;i<=frames;i++){ev('pointermove',1,sx+ux*D*i/frames,sy+uy*D*i/frames);keep();update(DT)}
  const L1=len(ux,uy);for(let i=0;i<30;i++){keep();update(DT)}
  const L2=len(ux,uy),g2=geo(),f=[...fingers.values()][0];let px=0,py=0,ww=0;for(const m of f.mem){px+=(X[m[0]]-m[1])*m[3];py+=(Y[m[0]]-m[2])*m[3];ww+=m[3]}px/=ww;py/=ww;
  const gap=Math.hypot(px-f.x,py-f.y)/R;
  ev('pointerup',1,sx+ux*D,sy+uy*D);const post={};const marks=[2,6,12,24,60,120];let c=0;for(const mk of marks){while(c<mk){keep();update(DT);c++}post[Math.round(mk*1000/60)]=r3(len(ux,uy))}
  rec[nm]={L0:r3(L0),Lend:r3(L1),Lheld:r3(L2),gap:r3(gap),follow:r3(Math.hypot(g2.cx-g0.cx,g2.cy-g0.cy)/R),post};
 }
 // 按
 fresh(22,{deco:0,decoReal:0,lifeFlinch:0,e2:0,flee:0,echo:0},{tr:s.tr||0,w:s.w||0,settle:240});
 const keep=()=>{LIFE.st='rest';LIFE.until=t+1e6;GAIT.on=false;BRX.sighNext=t+99;IMP.tr=s.tr||0;IMP.w=s.w||0;IMPD.tr=IMP.tr;IMPD.w=IMP.w;if(s.f)s.f()};
 for(let i=0;i<240;i++){keep();update(DT)}
 const g0=geo(),p=scr(globalC.xc,globalC.yc-R*.2);ev('pointerdown',1,p[0],p[1]);const pr=[];for(const mk of [3,6,18,36]){while(pr.length<mk){keep();update(DT);const f=[...fingers.values()][0];pr.push([geo().A/g0.A,f?f.press/R:0,DENTS.length?DENTS[DENTS.length-1].d:0,PRESS_SUM])}}
 rec.press={ms50:pr[2].map(r3),ms100:pr[5].map(r3),ms300:pr[17].map(r3),ms600:pr[35].map(r3)};
 ev('pointerup',1,p[0],p[1]);
 out[k]=rec;}
return out;
