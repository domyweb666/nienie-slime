 // 對照：把單點的 scare 當 0（只在測試頁裡改 moodRelease 的副作用：每次點完把 MOOD.scare、MOOD.c 還原，戒也還原），同樣 8 下，看心情、格子、戒
 const out={};
 for(const fix of [0,1]){chooseSlime(2);for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(31);BRAIN.seed=555;setup();fxReset();impReset();brainReset();BMEM.cell=[0,0,0,0,0];BMEM.side=0;Object.assign(BMEM.ev,{h:MOOD.happyT,w:0,sc:0});MOOD.scare=0;MOOD.c=0;MOOD.a=0;steps(240);
  const h0=memHomeX(),rows=[];for(let k=1;k<=8;k++){const [sx,sy]=scr(globalC.xc,globalC.yc-R*.1);const s0=MOOD.scare,c0=MOOD.c,w0=IMP.w;ev('pointerdown',1,sx,sy);steps(6);ev('pointerup',1,sx,sy);if(fix){MOOD.scare=s0;MOOD.c=c0;IMP.w=w0}steps(60*3-6);rows.push([k,+BRAIN.m.toFixed(2),+Math.min(...BMEM.cell).toFixed(2),+IMP.w.toFixed(2),+FLN.last.toFixed(3)])}
  // 之後揉 30 秒，看多久呼嚕、心情補回來幾秒
  let [sx,sy]=scr(globalC.xc,globalC.yc);ev('pointerdown',1,sx,sy);let tp=null,tm=null;for(let k=1;k<=60*45;k++){const u=2*Math.PI*.6*k/60,r=R*CAM.z*.25;ev('pointermove',1,sx+r*Math.cos(u)-r,sy+r*Math.sin(u));steps(1);if(tp===null&&PURR>.3)tp=+(k/60).toFixed(1);if(tm===null&&BRAIN.m>=.1)tm=+(k/60).toFixed(1)}ev('pointerup',1,sx,sy);
  out['fix'+fix]={rows,purrAt:tp,moodBackAt:tm,homeShift:+((memHomeX()-h0)/R).toFixed(2)}}
 return out;
