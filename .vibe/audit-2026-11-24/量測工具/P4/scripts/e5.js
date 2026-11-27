 // 同一點重複點 40 下（每 2 秒、每 8 秒各一輪）：記縮的量、縮的時間差、外框最大位移，看變異係數
 const out={};
 for(const gap of [2,8]){setup();fxReset();impReset();brainReset();IMP.tr=.6;IMPD.tr=.6;MOOD.c=0;steps(180);const A=[],L=[],Dmax=[],lean=[],vo=[];let vl=voice.last;
  for(let k=0;k<40;k++){const [sx,sy]=scr(globalC.xc+R*.1,globalC.yc+R*.1);const t0=t;const f0=FLN.t0;ev('pointerdown',1,sx,sy);steps(6);ev('pointerup',1,sx,sy);const X0=Float64Array.from(X),Y0=Float64Array.from(Y);let md=0,lat=null,amp=0,ln=null;
   for(let j=0;j<60*gap-6;j++){steps(1);if(FLN.t0!==f0&&lat===null){lat=FLN.t0-t0;amp=FLN.amp}if(E2.leanT>t0&&ln===null)ln=E2.leanT-t0;if(j<60){for(const i of bnd)md=Math.max(md,Math.hypot(X[i]-X0[i],Y[i]-Y0[i]))}}
   A.push(+amp.toFixed(3));L.push(lat===null?null:+(lat*1000).toFixed(0));Dmax.push(+md.toFixed(1));lean.push(ln===null?null:+(ln*1000).toFixed(0))}
  const st=a=>{a=a.filter(x=>x!=null);const m=a.reduce((x,y)=>x+y,0)/a.length,s=Math.sqrt(a.reduce((x,y)=>x+(y-m)**2,0)/a.length);return{n:a.length,mean:+m.toFixed(3),sd:+s.toFixed(3),cv:+(s/m).toFixed(2)}};
  out['gap'+gap]={amp:A.slice(0,12),ampSt:st(A),latSt:st(L),lat:L.slice(0,10),disp:st(Dmax),leanLat:st(lean),tr:+IMP.tr.toFixed(2),w:+IMP.w.toFixed(2)}}
 return out;
