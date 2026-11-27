 // 輕點（0.1 秒、每 3 秒一下）點在牠中間 k 下之後：心情、怕、這格喜不喜歡、戒、家在哪；再放著 90 秒看牠待在哪一格
 const out={};
 for(const gap of [3,10])for(const [nm,sl] of [['taro',2],['peach',3]]){const rows=[];
  chooseSlime(sl);for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(31);BRAIN.seed=555;setup();fxReset();impReset();brainReset();BMEM.cell=[0,0,0,0,0];BMEM.side=0;Object.assign(BMEM.ev,{h:MOOD.happyT,w:0,sc:0});MOOD.scare=0;MOOD.c=0;MOOD.a=0;IMPD.tr=0;IMPD.w=0;steps(240);
  const g=SILL.g,mid=memCellAt(g.bx);let h0=memHomeX();rows.push([0,+BRAIN.m.toFixed(2),+BRAIN.f.toFixed(2),+BMEM.cell[mid].toFixed(2),+IMP.w.toFixed(2),0]);
  for(let k=1;k<=8;k++){const [sx,sy]=scr(globalC.xc,globalC.yc-R*.1);ev('pointerdown',1,sx,sy);steps(6);ev('pointerup',1,sx,sy);let mxF=0;for(let j=0;j<60*gap-6;j++){steps(1);mxF=Math.max(mxF,BRAIN.f)}
   rows.push([k,+BRAIN.m.toFixed(2),+mxF.toFixed(2),+Math.min(...BMEM.cell).toFixed(2),+IMP.w.toFixed(2),+((memHomeX()-h0)/R).toFixed(2)])}
  const xs=[];for(let j=0;j<60*90;j++){steps(1);if(j%30===0)xs.push(memCellAt(globalC.xc))}
  const cnt=[0,0,0,0,0];for(const x of xs)cnt[x]++;out[nm+'_gap'+gap]={cols:'taps, mood, peakFear, minCell, wary, homeShiftR',rows,cellTime90s:cnt.map(v=>Math.round(v/xs.length*100)),cells:BMEM.cell.map(v=>+v.toFixed(2))}}
 return out;
