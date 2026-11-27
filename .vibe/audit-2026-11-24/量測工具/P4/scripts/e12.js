 // 心情、熟、戒在畫面上差幾點（1 點約 0.166 毫米）：固定住數值，量 24 秒平均的外框寬高、面積、呼吸一輪幾秒
 const out={};const reset=()=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);setup();fxReset();impReset();brainReset();IMPD.tr=0;IMPD.w=0;MOOD.c=0;MOOD.a=0;PURR=0};
 const meas=(hold)=>{let w=0,h=0,top=0,n=0;const tops=[];for(let k=0;k<60*30;k++){hold();steps(1);if(k<360)continue;let a=1e9,b=-1e9,c=1e9,d=-1e9;for(const i of bnd){a=Math.min(a,X[i]);b=Math.max(b,X[i]);c=Math.min(c,Y[i]);d=Math.max(d,Y[i])}w+=b-a;h+=d-c;top+=c;n++;tops.push(c)}
   w/=n;h/=n;top/=n;let ups=0;const m=tops.reduce((x,y)=>x+y,0)/tops.length;for(let i=1;i<tops.length;i++)if(tops[i-1]<m&&tops[i]>=m)ups++;return{w:+w.toFixed(1),h:+h.toFixed(1),top:+top.toFixed(1),period:ups?+(tops.length/60/ups).toFixed(2):null}};
 const freeze=()=>{LIFE.st='rest';LIFE.until=t+9;lastTouch=t-5;SLP.lastAny=t;BRAIN.q=.1;BRAIN.e=.1;BRAIN.z=.1;BRAIN.s=0};
 for(const [k,m,tr,wr] of [['m0',.1,0,0],['m+.5',.5,0,0],['m-.5',-.5,0,0],['m+1',1,0,0],['m-1',-1,0,0],['tr1',.1,1,0],['w1',.1,0,1]]){reset();Math.random=seeded(5);out[k]=meas(()=>{freeze();BRAIN.m=m;BRAIN.mS=m;IMP.tr=tr;IMP.w=wr;IMPD.tr=tr;IMPD.w=wr})}
 out.R=R;return out;
