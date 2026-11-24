 // 手裡的「不聽話」：先點 n 下（每 1.2 秒一下、每下 0.1 秒），再往右上拉 2R 停住 4 秒，看手指有沒有被牠掙脫（mode 變 none）、幾秒
 const out={};
 const reset=()=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);setup();fxReset();impReset();brainReset();IMPD.tr=0;IMPD.w=0;MOOD.c=0;MOOD.a=0;steps(180)};
 for(const slime of [2,0,3]){const key=SLIMES[slime].id;out[key]={};
  for(const n of [0,4,8,12,20]){chooseSlime(slime);reset();for(let k=0;k<n;k++){const [sx,sy]=scr(globalC.xc,globalC.yc);ev('pointerdown',1,sx,sy);steps(6);ev('pointerup',1,sx,sy);steps(66)}
   const w0=+IMP.w.toFixed(2);steps(120);let [sx,sy]=scr(globalC.xc+R*.2,globalC.yc-R*.2);ev('pointerdown',1,sx,sy);steps(6);const L=R*CAM.z*2.4;for(let j=1;j<=40;j++){ev('pointermove',1,sx+L*.7*j/40,sy-L*.7*j/40);steps(1)}
   let lost=null,mx=0;for(let k=0;k<240;k++){steps(1);const f=fingers.get(1);if(f)mx=Math.max(mx,SB(f));if(lost===null&&(!f||f.mode!=='grab'))lost=+((k+1)/60).toFixed(2)}
   out[key]['tap'+n]={w0,w1:+IMP.w.toFixed(2),lostAt:lost,maxSB:+mx.toFixed(2)};ev('pointerup',1,sx+L*.7,sy-L*.7)}}
 // 搔癢 8 秒：有沒有掙脫
 {chooseSlime(2);reset();const [sx,sy]=scr(globalC.xc,globalC.yc);ev('pointerdown',1,sx,sy);steps(4);let lost=null;for(let k=0;k<600;k++){const u=k/60,x=sx+R*CAM.z*.16*Math.sign(Math.sin(2*Math.PI*4*u))*Math.abs(Math.sin(2*Math.PI*4*u));ev('pointermove',1,x,sy);steps(1);const f=fingers.get(1);if(lost===null&&(!f||f.mode==='none'))lost=+((k+1)/60).toFixed(2)}out.tickle={lostAt:lost,w:+IMP.w.toFixed(2)};ev('pointerup',1,sx,sy)}
 return out;
