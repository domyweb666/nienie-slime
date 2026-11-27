 // 熟度從 0 到滿要多久（預設芋圓，trRate .7）：A 按住不動；B 慢慢揉圈（半徑 .25R，每秒 .6 圈）；C 摸（快速來回 stroke）；D 點 30 下（每 1.2 秒）
 const out={};
 const reset=()=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);setup();fxReset();impReset();brainReset();IMPD.tr=0;BMEM.cell=[0,0,0,0,0];BMEM.side=0;MOOD.c=0;MOOD.a=0;PURR=0;steps(180)};
 const hit=(arr,v)=>{const x=arr.find(q=>q[1]>=v);return x?+x[0].toFixed(1):null};
 const sum=(a,c)=>({t25:hit(a,.25),t5:hit(a,.5),t7:hit(a,.7),t99:hit(a,.99),end:+a[a.length-1][1].toFixed(2),cellMax30:hit(c,.3),cellEnd:+c[c.length-1][1].toFixed(2)});
 for(const mode of ['hold','rub']){reset();const a=[],c=[];let [sx,sy]=scr(globalC.xc,globalC.yc);ev('pointerdown',1,sx,sy);
  for(let k=1;k<=60*40;k++){if(mode==='rub'){const u=2*Math.PI*.6*k/60,r=R*CAM.z*.25;ev('pointermove',1,sx+r*Math.cos(u)-r,sy+r*Math.sin(u))}steps(1);if(k%6===0){a.push([k/60,IMP.tr]);c.push([k/60,Math.max(...BMEM.cell)])}}
  ev('pointerup',1,sx,sy);out[mode]=sum(a,c);out[mode].mood=+BRAIN.m.toFixed(2)}
 // D 點
 {reset();const a=[],c=[];for(let k=0;k<30;k++){const [sx,sy]=scr(globalC.xc,globalC.yc);ev('pointerdown',1,sx,sy);steps(6);ev('pointerup',1,sx,sy);steps(66);a.push([(k+1)*1.2,IMP.tr]);c.push([k,Math.max(...BMEM.cell)])}out.tap=sum(a,c);out.tap.w=+IMP.w.toFixed(2)}
 // E 溫柔拖 10 次
 {reset();const a=[],c=[];for(let k=0;k<12;k++){let [sx,sy]=scr(globalC.xc,globalC.yc);const T0=t;ev('pointerdown',1,sx,sy);steps(6);const d=(k%2?1:-1)*R*CAM.z*1.2;for(let j=1;j<=40;j++){ev('pointermove',1,sx+d*j/40,sy);steps(1)}steps(10);ev('pointerup',1,sx+d,sy);steps(90);a.push([(k+1),IMP.tr]);c.push([k,Math.max(...BMEM.cell)])}out.drag=sum(a,c);out.drag.seq=a.map(x=>+x[1].toFixed(2))}
 return out;
