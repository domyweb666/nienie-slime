// 張力層加「一拉就淡掉」之後還會不會變差；同一組亂捏種子。另外找 tense 那一次 185 點的跳是什麼
const V=[['base',null],['tense淡',{a:1.5,p:.6,h:1.2}],['loose淡',{a:.65,p:1.5,h:.8}],['loose只按壓',{a:1,p:1.6,h:1}],['loose只按壓淡',{a:1,p:1.6,h:1,fade:1}],['tense2淡',{a:2,p:.4,h:1.4}]];
const B={alpha:.18,pressBase:.12,pressHold:.18,pressSpread:.1,inertiaHz:3};
const out=[];
for(const [nm,m] of V){let fr=0,flipF=0,flipMax=0,js=0,jn=0,jump=0,after=0,big=[];
 const tune=()=>{if(!m)return;let st=0;for(const f of fingers.values())if(f.mode==='grab')st=Math.max(st,f.stretch||0,Math.hypot(f.x-f.ax,f.y-f.ay)/R);const useFade=nm!=='loose只按壓';const x=Math.max(0,Math.min(1,(st-.25)/.45)),k=useFade?1-x*x*(3-2*x):1,g=v=>1+(v-1)*k;mat.alpha=B.alpha*g(m.a);mat.pressBase=B.pressBase*g(m.p);mat.pressHold=B.pressHold*g(m.p);mat.pressSpread=B.pressSpread*g(m.p);mat.inertiaHz=B.inertiaHz*g(m.h)};
 for(let sd=1;sd<=12;sd++){fresh(100+sd,{deco:0,decoReal:0},{tr:.3,settle:150});const rnd=seeded(sd*77+5);let fx=0,fy=0;const p=scr(globalC.xc+(rnd()-.5)*R,globalC.yc+(rnd()-.5)*R*.8);fx=p[0];fy=p[1];ev('pointerdown',1,fx,fy);let tx=fx,ty=fy,px=X.slice(),py=Y.slice();
  for(let i=0;i<480;i++){if(i%40===0){const k=rnd();if(k<.45){tx=p[0]+(rnd()-.5)*R*1.2;ty=p[1]+(rnd()-.5)*R*1.2}else{tx=30+rnd()*333;ty=250+rnd()*380}if(k>.85){ev('pointerup',1,fx,fy);const q=scr(globalC.xc+(rnd()-.5)*R,globalC.yc+(rnd()-.5)*R*.6);fx=q[0];fy=q[1];tx=fx+(rnd()-.5)*R*2;ty=fy+(rnd()-.5)*R*2;ev('pointerdown',1,fx,fy)}}
   fx+=(tx-fx)*.12;fy+=(ty-fy)*.12;ev('pointermove',1,fx,fy);const n0=N;tune();update(DT);fr++;const f=flipCount(X,Y);if(f>0)flipF++;flipMax=Math.max(flipMax,f);if(N===n0&&px.length===N){let mm=0;for(let j=0;j<N;j++)mm=Math.max(mm,Math.hypot(X[j]-px[j],Y[j]-py[j]));jump=Math.max(jump,mm);if(mm>40)big.push([sd,i,r2(mm),REM.n,CLING.on]);js+=mm;jn++}px=X.slice();py=Y.slice()}
  ev('pointerup',1,fx,fy);for(let i=0;i<120;i++){tune();update(DT)}let m2=0;for(let i=0;i<30;i++){const a=X.slice(),b=Y.slice();tune();update(DT);if(a.length===N){let mm=0;for(let j=0;j<N;j++)mm=Math.max(mm,Math.hypot(X[j]-a[j],Y[j]-b[j]));m2+=mm/30}}after+=m2}
 // 按 0.6 秒的大小（跟 e7 同一個動作）
 fresh(22,{deco:0,decoReal:0,lifeFlinch:0,e2:0,flee:0,echo:0,life:0},{tr:.3,settle:300});LIFE.until=t+1e6;for(let i=0;i<120;i++){tune();update(DT)}const g0=geo(),q=scr(globalC.xc-R*.25,globalC.yc-R*.15);ev('pointerdown',1,q[0],q[1]);for(let i=0;i<36;i++){tune();update(DT)}const g1=geo();ev('pointerup',1,q[0],q[1]);let tr=null;for(let i=0;i<180;i++){tune();update(DT);if(tr==null&&Math.abs(geo().A/g0.A-1)<.02)tr=i/60}
 out.push({nm,flipPct:r2(flipF/fr*100),flipMax,jumpMax:r2(jump),jumpAvg:r2(js/jn),afterJit:r2(after/12),big:big.slice(0,4),press:{A:r3(g1.A/g0.A),w:r2((g1.w-g0.w)*.16565),h:r2((g1.h-g0.h)*.16565),back:tr&&r2(tr)}})}
return out;
