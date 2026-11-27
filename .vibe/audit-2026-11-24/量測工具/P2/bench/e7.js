// 假想的「張力」：把 alpha、按壓攤開、慣性頻率照比例改，看手指底下的樣子差多少、會不會比較容易翻面
const len=(ux,uy)=>{let a=-1e9,b=1e9;for(const i of bnd){const p=X[i]*ux+Y[i]*uy;a=Math.max(a,p);b=Math.min(b,p)}return(a-b)/R};
const out=[];
const V=[['base',{}],['tense',{alpha:.18*1.5,pressBase:.12*.6,pressHold:.18*.6,pressSpread:.1*.6,inertiaHz:3*1.2}],['loose',{alpha:.18*.65,pressBase:.12*1.5,pressHold:.18*1.5,pressSpread:.1*1.5,inertiaHz:3*.8}],['alpha1.5',{alpha:.27}],['alpha.65',{alpha:.117}],['press.6',{pressBase:.072,pressHold:.108,pressSpread:.06}],['press1.5',{pressBase:.18,pressHold:.27,pressSpread:.15}]];
for(const [nm,ov] of V){const rec={nm};
 // 按 0.6 秒：量身體中間按下去，外框各方向往外跑多少（毫米）、面積、整團高度變化
 fresh(22,{deco:0,decoReal:0,lifeFlinch:0,e2:0,flee:0,echo:0,life:.0,...ov},{tr:.3,settle:300});LIFE.until=t+1e6;steps(120);
 const g0=geo(),x0=Float64Array.from(X),y0=Float64Array.from(Y),p=scr(globalC.xc-R*.25,globalC.yc-R*.15);ev('pointerdown',1,p[0],p[1]);steps(36);const g1=geo();let mx=0;for(const i of bnd)mx=Math.max(mx,Math.hypot(X[i]-x0[i],Y[i]-y0[i]));rec.press={A:r3(g1.A/g0.A),w:r2((g1.w-g0.w)*.16565),h:r2((g1.h-g0.h)*.16565),edge:r2(mx*.16565)};
 ev('pointerup',1,p[0],p[1]);let tr=null;for(let i=0;i<180;i++){update(DT);const g=geo();if(tr==null&&Math.abs(g.A/g0.A-1)<.02)tr=i/60}rec.press.back=tr==null?null:r2(tr);
 // 揉：0.35R 圓，每秒 1.2 圈，3 秒。量對面外框動多少、身體形變（高度標準差）
 fresh(23,{deco:0,decoReal:0,lifeFlinch:0,e2:0,flee:0,echo:0,...ov},{tr:.3,settle:300});LIFE.until=t+1e6;const q=scr(globalC.xc,globalC.yc-R*.2);ev('pointerdown',1,q[0],q[1]);const hs=[],ar=[];let flipM=0;for(let i=0;i<180;i++){const a=i/60*2*Math.PI*1.2;ev('pointermove',1,q[0]+R*.35*Math.cos(a)-R*.35,q[1]+R*.35*Math.sin(a));update(DT);const g=geo();hs.push(g.h);ar.push(g.A);flipM=Math.max(flipM,flipCount(X,Y))}ev('pointerup',1,q[0],q[1]);const m=hs.reduce((a,b)=>a+b)/hs.length;rec.knead={hsd:r2(Math.sqrt(hs.reduce((a,b)=>a+(b-m)**2,0)/hs.length)*.16565),A:r3(ar.reduce((a,b)=>a+b)/ar.length/geo().A),flip:flipM};
 // 拉 1.5R（0.75 秒）停 0.5 秒放手
 for(const [dx,dy,dist,fr] of [[.45,-.893,1.5,45],[1,0,2.5,30],[.45,-.893,1.5,6]]){fresh(24,{deco:0,decoReal:0,lifeFlinch:0,e2:0,flee:0,echo:0,...ov},{tr:.3,settle:240});LIFE.until=t+1e6;let bi=0,bd=-1e9;for(const i of bnd){const pp=(X[i]-globalC.xc)*dx+(Y[i]-globalC.yc)*dy;if(pp>bd){bd=pp;bi=i}}const[sx,sy]=scr(X[bi]-dx*R*.3,Y[bi]-dy*R*.3);const L0=len(dx,dy);ev('pointerdown',1,sx,sy);steps(4);let fm=0;const tx=Math.max(6,Math.min(387,sx+dx*R*dist)),ty=sy+dy*R*dist;for(let i=1;i<=fr;i++){ev('pointermove',1,sx+(tx-sx)*i/fr,sy+(ty-sy)*i/fr);update(DT);fm=Math.max(fm,flipCount(X,Y))}for(let i=0;i<30;i++){update(DT);fm=Math.max(fm,flipCount(X,Y))}const L1=len(dx,dy);ev('pointerup',1,tx,ty);const post=[];for(let i=1;i<=60;i++){update(DT);fm=Math.max(fm,flipCount(X,Y));if([2,4,8,16,30,60].includes(i))post.push(r2(len(dx,dy)))}
  (rec.pull=rec.pull||[]).push({dir:[dx,dy,dist,fr],L0:r2(L0),L1:r2(L1),post,flip:fm})}
 out.push(rec)}
return out;
