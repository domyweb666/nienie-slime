const R1={};const set=(o)=>{for(const k in PRESETS)Object.assign(PRESETS[k],o);Object.assign(mat,o)};
const ON=Object.fromEntries(KEYS61.map(k=>[k,PRESETS.clay[k]]));const med=a=>{a=a.slice().sort((x,y)=>x-y);return a.length?+a[a.length>>1].toFixed(3):null};
const q0=new URLSearchParams(location.search),C=(q0.get('c')||'').split(',').map(Number),TRS=(q0.get('tr')||'0,0.3').split(',').map(Number),NS=+(q0.get('n')||20);
if(C.length>=4)brainJit=function(){if(!(mat.greetLook>=.5)||!BRon())return;const B=BRAIN,r=Math.random;B.seed=(r()*4294967296)>>>0;B.z=.15+.3*r();B.q=C[0]+C[1]*r();B.e=C[2]+C[3]*r();B.s=.4*r()*IMP.tr;window.OJA=C[4]||.16;B.ojT=t+(C[5]||40)};
set(ON);for(const tr of TRS){const us=[],eye=[],third={},act={},one={};let seen=0,nsl=0,slm=[];
  for(let s=1;s<=NS;s++){open(s*17+3,{tr});let u=null,e=null,zz=null;const pk=[],ac=[];const op=brainPick,og=brainGo;let inPick=0;brainPick=c=>{const w=op(c);if(w!=='rest'){pk.push(w);ac.push(w);inPick=1}return w};brainGo=d=>{if(d!=null)ac.push('go');return og(d)};
    steps(60*60,i=>{const q=(i+1)/60;if(u==null&&EYE.user>t)u=q;if(u!=null&&e==null&&Math.hypot(EYE.gx,EYE.gy)<.15)e=q;if(zz==null&&SLP.on)zz=q});brainPick=op;brainGo=og;
    if(u!=null)us.push(u);if(u!=null&&u<.8)seen++;if(e!=null)eye.push(e);const a=pk.slice(0,3).join(','),b=ac.slice(0,3).join(',');third[a]=(third[a]||0)+1;act[b]=(act[b]||0)+1;one[pk[0]]=(one[pk[0]]||0)+1;if(zz!=null)slm.push(zz)}
  const so=o=>Object.entries(o).sort((x,y)=>y[1]-x[1]);R1['tr'+tr]={look:us.length,in08:seen,medUser:med(us),medEye:med(eye),maxEye:Math.max(...eye),pick3:so(third),act3:so(act),first:so(one),sleepMin:slm.length?+Math.min(...slm).toFixed(1):null,nSleep:slm.length}}
return R1;
