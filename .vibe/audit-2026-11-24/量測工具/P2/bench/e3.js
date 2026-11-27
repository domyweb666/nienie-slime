// 同一個刺激 × 不同狀態：牠自己的反應差多少
const ST={neutral:{},trust:{tr:.9},wary:{w:.9},moodGood:{m:.8},moodBad:{m:-.8},asleep:{sl:1},comfort:{c:.8}};
const stims={
 tap:{n:90,run(p){ev('pointerdown',1,p[0],p[1]);this.cb(6);ev('pointerup',1,p[0],p[1]);this.cb(150)}},
 hold3:{run(p){ev('pointerdown',1,p[0],p[1]);this.cb(180);ev('pointerup',1,p[0],p[1]);this.cb(120)}},
 rub3:{run(p){ev('pointerdown',1,p[0],p[1]);for(let i=0;i<180;i++){const a=i/60*2*Math.PI*1.2;ev('pointermove',1,p[0]+R*.28*Math.sin(a),p[1]+R*.2*Math.sin(2*a));this.cb(1)}ev('pointerup',1,p[0],p[1]);this.cb(150)}},
 pull25:{run(p){const q=[p[0],p[1]-R*.5];ev('pointerdown',1,q[0],q[1]);for(let i=1;i<=40;i++){ev('pointermove',1,q[0]+R*1.2*i/40,q[1]-R*2.2*i/40);this.cb(1)}this.cb(60);ev('pointerup',1,q[0]+R*1.2,q[1]-R*2.2);this.cb(240)}},
 tap3:{run(p){for(let k=0;k<3;k++){ev('pointerdown',1,p[0],p[1]);this.cb(5);ev('pointerup',1,p[0],p[1]);this.cb(12)}this.cb(240)}},
 beside3:{run(p){const g=geo(),q=scr(g.x1+R*.55,g.cy);ev('pointerdown',1,Math.min(388,q[0]),q[1]);this.cb(240);ev('pointerup',1,Math.min(388,q[0]),q[1]);this.cb(90)}}
};
const out={};
for(const sn in stims){out[sn]={};for(const k in ST){const s=ST[k];
  fresh(11,{deco:0,decoReal:0},{tr:s.tr||0,w:s.w||0,settle:240});
  // 固定在休息、把狀態設好
  LIFE.st='rest';LIFE.until=t+1e6;
  if(s.m!=null){BRAIN.m=s.m;BRAIN.mS=s.m;BRAIN.ev.w=IMP.w;BRAIN.ev.sc=MOOD.scare}
  if(s.sl){SLP.on=true;LIFE.st='sleep';steps(60*6)}
  if(s.c){MOOD.c=s.c;MOOD.a=.15}
  steps(2);if(s.c)MOOD.c=s.c;
  const b=geo(),A0b=b.A;const rec={A:1,dA:0,dxMax:0,dx:0,dy:0,fl:0,lean:0,esc:false,escD:0,eye:[],mode:[],wide:1,open:1,purr:0,mc:[0,0,0,0]};
  LOG.length=0;const T0=t;let cx0=b.cx;const tr0=IMP.tr,w0=IMP.w,m0=BRAIN.m;
  const st=stims[sn];st.cb=n=>{for(let i=0;i<n;i++){update(DT);const g=geo();rec.A=Math.min(rec.A,g.A/A0b);if(Math.abs(g.cx-b.cx)>Math.abs(rec.dx))rec.dx=g.cx-b.cx;if(Math.abs(g.cy-b.cy)>Math.abs(rec.dy))rec.dy=g.cy-b.cy;rec.fl=Math.max(rec.fl,(t-FLN.t0)<.2?FLN.amp:0);if(E2.leanS&&t-E2.leanT>0&&t-E2.leanT<.7)rec.lean=E2.leanS;if(ESC.on)rec.esc=true;rec.mc=rec.mc.map((v,j)=>Math.max(v,[MC.c,MC.s,MC.w,MC.z][j]));rec.purr=Math.max(rec.purr,PURR);rec.wide=Math.max(rec.wide,EYE.wideD);rec.open=Math.min(rec.open,EYE.openD);if(rec.mode[rec.mode.length-1]!==EYE.mode)rec.mode.push(EYE.mode)}};
  const p=scr(globalC.xc-R*.2,globalC.yc-R*.15);st.run(p);
  for(const id of [...fingers.keys()])ev('pointerup',id,0,0);
  out[sn][k]={Amin:r3(rec.A),dx:r2(rec.dx*.16565),dy:r2(rec.dy*.16565),flinch:r3(rec.fl),lean:rec.lean,esc:rec.esc,mode:rec.mode,wide:r2(rec.wide),open:r2(rec.open),purr:r2(rec.purr),mc:rec.mc.map(r2),voice:LOG.filter(q=>q[1].startsWith('voice.')).map(q=>[r2(q[0]-T0),q[1].slice(6),q[2],q[3]]),d:{tr:r3(IMP.tr-tr0),w:r3(IMP.w-w0),m:r3(BRAIN.m-m0),c:r2(MOOD.c),a:r2(MOOD.a)},lure:LURE.on,act:BRAIN.act};
}}
return out;
