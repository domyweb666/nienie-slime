 // 「收到了」多快看得到：五種狀態下，手指放在牠旁邊（離外框 0.8R，不碰到）1.5 秒；跟同一顆種子、沒放手指的對照比。
 // 看三樣：眼睛移動（瞳孔偏移，點）、外框最大位移（點）、第一次超過 3 點的時間
 const out={};
 const prep=(st,tr)=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(77);BRAIN.seed=12345;setup();fxReset();impReset();brainReset();IMP.tr=tr;IMPD.tr=tr;MOOD.c=0;MOOD.a=0;PURR=0;t=100;lastTouch=t-30;SLP.lastAny=t-30;steps(120);
   LIFE.st='rest';LIFE.until=t+60;BRAIN.q=.1;BRAIN.e=.1;BRAIN.s=0;BRAIN.z=.1;
   if(st==='sleep'){SLP.on=true;LIFE.st='sleep';steps(300)}
   if(st==='walk'){gaitTo(globalC.xc+(globalC.xc>W/2?-1:1)*R*1.6,HOMEY,false);steps(40)}
   if(st==='look'){Object.assign(LIFE,{st:'look',looks:1,noGo:true,until:t});steps(50)}
   if(st==='e4'){E4.on=true;E4.ph='wave';E4.t0=t;MOOD.wagT=t;steps(30)}};
 const run=(st,tr,touch)=>{prep(st,tr);const xs=[],es=[];let bx=-1e9,by=0;for(const i of bnd)if(X[i]>bx){bx=X[i];by=Y[i]}
   const sideR=globalC.xc<W/2;let ex=-1e9;for(const i of bnd)ex=sideR?Math.max(ex,X[i]):Math.max(ex,-X[i]);const wx=sideR?ex+R*.8:-ex-R*.8;const [sx,sy]=scr(wx,globalC.yc-R*.3);
   if(touch)ev('pointerdown',1,sx,sy);
   for(let k=0;k<90;k++){steps(1);xs.push(Float64Array.from(bnd,i=>X[i]));es.push([EYE.gx,EYE.gy,EYE.openD])}
   const info={slp:SLP.on,st:LIFE.st};if(touch)ev('pointerup',1,sx,sy);return{xs,es,info,ys:null}};
 for(const tr of [0,.6])for(const st of ['rest','look','walk','sleep','e4']){const a=run(st,tr,false),b=run(st,tr,true);let tB=null,tE=null,mx=0,me=0;const D=[];
   for(let k=0;k<90;k++){let m=0;const n=Math.min(a.xs[k].length,b.xs[k].length);for(let j=0;j<n;j++)m=Math.max(m,Math.abs(a.xs[k][j]-b.xs[k][j]));const e=Math.hypot(a.es[k][0]-b.es[k][0],a.es[k][1]-b.es[k][1])*(mat.gazeAmp||.06)*R;if(m>3&&tB===null)tB=Math.round((k+1)/60*1000);if(e>3&&tE===null)tE=Math.round((k+1)/60*1000);mx=Math.max(mx,m);me=Math.max(me,e);D.push(m)}
   out[st+'_tr'+tr]={body3ptMs:tB,eye3ptMs:tE,bodyMax:+mx.toFixed(1),eyeMax:+me.toFixed(1),at300:+D[17].toFixed(1),at600:+D[35].toFixed(1),end:b.info}}
 return out;
