// 張力層會不會讓身體更容易壞：亂捏亂拉 8 秒 × 12 個種子 × 三種；另量極端的按壓
const V=[['base',{}],['tense',{alpha:.18*1.5,pressBase:.12*.6,pressHold:.18*.6,pressSpread:.1*.6,inertiaHz:3*1.2}],['loose',{alpha:.18*.65,pressBase:.12*1.5,pressHold:.18*1.5,pressSpread:.1*1.5,inertiaHz:3*.8}],['tense2',{alpha:.18*2,pressBase:.12*.4,pressHold:.18*.4,pressSpread:.1*.4,inertiaHz:3*1.4}],['loose2',{alpha:.18*.5,pressBase:.12*1.8,pressHold:.18*1.8,pressSpread:.1*1.8,inertiaHz:3*.7}]];
const out=[];
for(const [nm,ov] of V){let fr=0,flipF=0,flipMax=0,jump=0,js=0,jn=0,after=0;
 for(let sd=1;sd<=12;sd++){fresh(100+sd,{deco:0,decoReal:0,...ov},{tr:.3,settle:150});const rnd=seeded(sd*77+5);let fx=0,fy=0;const p=scr(globalC.xc+(rnd()-.5)*R,globalC.yc+(rnd()-.5)*R*.8);fx=p[0];fy=p[1];ev('pointerdown',1,fx,fy);let tx=fx,ty=fy,px=X.slice(),py=Y.slice();
  for(let i=0;i<480;i++){if(i%40===0){const k=rnd();if(k<.45){tx=p[0]+(rnd()-.5)*R*1.2;ty=p[1]+(rnd()-.5)*R*1.2}else{tx=30+rnd()*333;ty=250+rnd()*380}if(k>.85){ev('pointerup',1,fx,fy);const q=scr(globalC.xc+(rnd()-.5)*R,globalC.yc+(rnd()-.5)*R*.6);fx=q[0];fy=q[1];tx=fx+(rnd()-.5)*R*2;ty=fy+(rnd()-.5)*R*2;ev('pointerdown',1,fx,fy)}}
   fx+=(tx-fx)*.12;fy+=(ty-fy)*.12;ev('pointermove',1,fx,fy);const n0=N;update(DT);fr++;const f=flipCount(X,Y);if(f>0)flipF++;flipMax=Math.max(flipMax,f);if(N===n0&&px.length===N){let m=0;for(let j=0;j<N;j++)m=Math.max(m,Math.hypot(X[j]-px[j],Y[j]-py[j]));jump=Math.max(jump,m);js+=m;jn++}px=X.slice();py=Y.slice()}
  ev('pointerup',1,fx,fy);steps(120);let m2=0;for(let i=0;i<30;i++){const a=X.slice(),b=Y.slice();update(DT);if(a.length===N){let m=0;for(let j=0;j<N;j++)m=Math.max(m,Math.hypot(X[j]-a[j],Y[j]-b[j]));m2+=m/30}}after+=m2}
 // 極端：按 0.6 秒
 fresh(22,{deco:0,decoReal:0,lifeFlinch:0,e2:0,flee:0,echo:0,life:0,...ov},{tr:.3,settle:300});LIFE.until=t+1e6;steps(120);const g0=geo(),q=scr(globalC.xc-R*.25,globalC.yc-R*.15);ev('pointerdown',1,q[0],q[1]);steps(36);const g1=geo();ev('pointerup',1,q[0],q[1]);let tr=null;for(let i=0;i<180;i++){update(DT);if(tr==null&&Math.abs(geo().A/g0.A-1)<.02)tr=i/60}
 out.push({nm,flipPct:r2(flipF/fr*100),flipMax,jumpMax:r2(jump),jumpAvg:r2(js/jn),afterJit:r2(after/12),press:{A:r3(g1.A/g0.A),w:r2((g1.w-g0.w)*.16565),h:r2((g1.h-g0.h)*.16565),back:tr&&r2(tr)}})}
return out;
