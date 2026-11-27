// 開場 40 秒 × 20 個種子：第一次看你、第一次打招呼、打翻東西、自己嚇到
const out=[];
for(const tr of [0,.3,.6,.9])for(let sd=1;sd<=20;sd++){
  fresh(sd*17+3,{},{tr,settle:0});let eye=null,greet=null,top10=0,top60=0,st10=0,move=null;
  steps(40*60,i=>{const s=i/60;if(EYE.user>t&&eye==null)eye=s;if(E4.on&&greet==null)greet=s;if(GAIT.on&&move==null)move=s});
  for(const q of LOG){if(q[1]==='fx.topple'||q[1]==='fx.fallout'){if(q[0]<10)top10=1;top60=1}if(q[1]==='voice.startle'&&q[0]<10)st10=1}
  out.push({tr,sd,eye,greet,top10,top60,st10,move});
}
return out;
