// 你甩、你推：只切 bumpSoft；牠自己碰（沒有手指）對照
const R1={};const set=(o)=>{for(const k in PRESETS)Object.assign(PRESETS[k],o);Object.assign(mat,o)};const up=q=>Math.abs(Math.atan2(Math.sin(q.a),Math.cos(q.a)));
const qs=new URLSearchParams(location.search),S0=+qs.get('s'),N0=+qs.get('n');
for(const bs of [0,1]){set({bumpSoft:bs});const thr=[],psh=[];let softN=0;
 for(let s=S0;s<S0+N0;s++){for(const dir of [-1,1]){open(s*13+1,{tr:.3});steps(300);const q=PROPS.filter(p=>p.deco)[dir>0?1:0],x0=q.x;const p=scr(globalC.xc,globalC.yc);ev('pointerdown',1,p[0],p[1]);steps(6);for(let k=1;k<=14;k++){ev('pointermove',1,p[0]+dir*k*9,p[1]-k*3);steps(1)}ev('pointerup',1,p[0]+dir*126,p[1]-42);let t0=0,mv=0,so=0;const st0=t;steps(150,()=>{if(q.gone||up(q)>.6)t0=1;mv=Math.max(mv,Math.abs(q.x-x0));if(q.softT>st0)so=1});thr.push([t0,Math.round(mv),so])}
  for(const im of [0,1]){open(s*13+1,{tr:.3});steps(300);const q=PROPS.filter(p=>p.deco)[im];const p=scr(q.x,q.y-q.h*.4);ev('pointerdown',1,p[0],p[1]);let t0=0;for(let k=1;k<=20;k++){ev('pointermove',1,p[0]+(im?-1:1)*k*6,p[1]);steps(1);if(q.gone||up(q)>.6)t0=1}ev('pointerup',1,p[0],p[1]);steps(120,()=>{if(q.gone||up(q)>.6)t0=1});psh.push(t0)}}
 R1['b'+bs]={甩倒:thr.filter(x=>x[0]).length,甩n:thr.length,甩:thr.map(x=>x.join('/')).join(' '),手指推倒:psh.filter(x=>x).length,推n:psh.length}}
return R1;
