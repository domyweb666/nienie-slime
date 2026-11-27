// 開場 30 秒：陌生 vs 很熟。逐 0.5 秒記狀態、注視、搖、說話
const out={};
for(const [name,tr,sd] of [['stranger',0,1],['stranger',0,2],['close',.9,1],['close',.9,2],['close',.9,3]]){
  fresh(sd,{},{tr,settle:0});const tl=[];let lastSt='';let firstEye=null,firstWag=null,firstVoice=null,firstSniff=null,firstMove=null;const x0=globalC.xc;
  let wag0=MOOD.wagT;
  steps(30*60,i=>{const s=i/60;if(EYE.user>t&&firstEye==null)firstEye=r2(s);if(MOOD.wagT!==wag0&&firstWag==null)firstWag=r2(s);
    const v=LOG.find(q=>q[1].startsWith('voice.'));if(v&&firstVoice==null)firstVoice=v;
    if(LIFE.sns.length&&firstSniff==null)firstSniff=r2(s);if(GAIT.on&&firstMove==null)firstMove=r2(s);
    if(BRAIN.act!==lastSt){tl.push([r2(s),BRAIN.act]);lastSt=BRAIN.act}});
  (out[name]=out[name]||[]).push({sd,firstEye,firstWag,firstVoice,firstSniff,firstMove,tl,sfx:LOG.slice(0,12)});
}
return out;
