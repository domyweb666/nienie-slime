// a) 熟要多久滿；b) 連戳 12 下的習慣化（間隔 0.6、1.5、4 秒）；c) 隔多久恢復；d) 逃的實際距離
const out={};
{ // a 熟的速度：慢慢揉（每秒約 5 公分），芋圓
  fresh(31,{deco:0,decoReal:0},{tr:0,settle:200});const p=scr(globalC.xc,globalC.yc-R*.1);ev('pointerdown',1,p[0],p[1]);const hit={};let T=0;
  for(let i=0;i<60*30;i++){const a=i/60*2*Math.PI*1.1;ev('pointermove',1,p[0]+R*.28*Math.sin(a),p[1]+R*.2*Math.sin(2*a));update(DT);T=(i+1)/60;for(const th of [.25,.5,.7,.99])if(IMP.tr>=th&&hit[th]==null)hit[th]=r2(T);if(IMP.tr>=.99)break}
  ev('pointerup',1,p[0],p[1]);out.trust={hit,m:r2(BRAIN.m),purr:r2(PURR)};
  // 只按著不動
  fresh(32,{deco:0,decoReal:0},{tr:0,settle:200});const q=scr(globalC.xc,globalC.yc-R*.1);ev('pointerdown',1,q[0],q[1]);const hh={};for(let i=0;i<60*40;i++){update(DT);for(const th of [.25,.5,.7,.99])if(IMP.tr>=th&&hh[th]==null)hh[th]=r2((i+1)/60);if(IMP.tr>=.99)break}ev('pointerup',1,q[0],q[1]);out.trustHold=hh;
  // 摸（從外面劃過身體，一秒兩趟）
  fresh(33,{deco:0,decoReal:0},{tr:0,settle:200});const sc=scr(globalC.xc,globalC.yc);const hs={};let fr=0;
  for(let k=0;k<60&&IMP.tr<.99;k++){const dir=k%2?1:-1;ev('pointerdown',1,sc[0]-dir*R*1.5,sc[1]-R*.2);for(let i=1;i<=24;i++){ev('pointermove',1,sc[0]-dir*R*1.5+dir*R*3*i/24,sc[1]-R*.2);update(DT);fr++;for(const th of [.25,.5,.7,.99])if(IMP.tr>=th&&hs[th]==null)hs[th]=r2(fr/60)}ev('pointerup',1,sc[0]+dir*R*1.5,sc[1]-R*.2);steps(8);fr+=8}out.trustStroke={hs,tr:r2(IMP.tr)}}
// b 連戳
out.hab={};
for(const gap of [.6,1.5,4]){const seq=[];fresh(41,{deco:0,decoReal:0},{tr:.5,settle:240});
  for(let k=0;k<12;k++){const g0=geo(),p=scr(globalC.xc-R*.2,globalC.yc-R*.15);LOG.length=0;let A=1,esc=0;ev('pointerdown',1,p[0],p[1]);const run=n=>{for(let i=0;i<n;i++){update(DT);A=Math.min(A,geo().A/g0.A);if(ESC.on)esc=1}};run(6);ev('pointerup',1,p[0],p[1]);run(Math.round(gap*60)-6);
    seq.push({fl:r3(FLN.last),H:r2(FLN.H),A:r3(A),esc,m:r2(BRAIN.m),w:r2(IMP.w),sc:r2(MOOD.scare),v:LOG.filter(q=>q[1].startsWith('voice.')).map(q=>q[1].slice(6)+'@'+r2(q[3])).join(','),lean:E2.leanS})}
  out.hab[gap]=seq}
// c 習慣多久恢復：戳 6 下後等 x 秒再戳一下
out.rec={};for(const w of [5,15,30,60,180]){fresh(42,{deco:0,decoReal:0,brain:1},{tr:.5,settle:240});const poke=()=>{const p=scr(globalC.xc-R*.2,globalC.yc-R*.15);ev('pointerdown',1,p[0],p[1]);steps(6);ev('pointerup',1,p[0],p[1]);steps(30);return r3(FLN.last)};const a=poke();for(let k=0;k<5;k++){steps(40);poke()}const b=FLN.last;LIFE.until=t+1e6;steps(w*60);const c=poke();out.rec[w]={first:a,sixth:r3(b),after:c,m:r2(BRAIN.m)}}
// d 逃：連戳 3 下、扯 2.5R 放手，重心最後離原地多遠（毫米）、碰到邊了沒
out.flee=[];for(const x0 of [0]){for(const kind of ['tap3','pull']){for(const sd of [1,2,3]){fresh(50+sd,{deco:0,decoReal:0},{tr:.2,settle:240});const g0=geo();const p=scr(globalC.xc-R*.3,globalC.yc-R*.15);
  if(kind==='tap3'){for(let k=0;k<3;k++){ev('pointerdown',1,p[0],p[1]);steps(5);ev('pointerup',1,p[0],p[1]);steps(12)}}
  else{const q=[p[0],p[1]-R*.4];ev('pointerdown',1,q[0],q[1]);for(let i=1;i<=40;i++){ev('pointermove',1,q[0]-R*1.4*i/40,q[1]-R*2*i/40);steps(1)}steps(90);ev('pointerup',1,q[0]-R*1.4,q[1]-R*2)}
  let planned=ESC.on?Math.hypot(ESC.dx-ESC.sx,ESC.dy-ESC.sy):0,maxd=0,x1=geo().cx;for(let i=0;i<60*4;i++){update(DT);maxd=Math.max(maxd,Math.abs(geo().cx-x1))}
  out.flee.push({kind,sd,plannedMM:r2(planned*.16565),movedMM:r2(maxd*.16565),homeX:r2(HOMEX),lo:r2(sillClampX(-9999)),hi:r2(sillClampX(9999))})}}}
return out;
