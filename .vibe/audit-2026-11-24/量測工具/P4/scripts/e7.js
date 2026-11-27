 // 打開 app 後 60 秒不碰：第一個「朝你做」的動作在幾秒（看你 EYE.user、游到前面 E4、把常摸那邊靠過來、揮）。熟 0、.5、1 各 8 次
 const out={};
 for(const tr0 of [0,.5,1]){const firsts=[],any=[],look0=[];
  for(let r=0;r<8;r++){Math.random=seeded(SEED*100+r*17+tr0*1000);BRAIN.seed=(20261114+r*7919+SEED*13)>>>0;setup();fxReset();impReset();brainReset();IMP.tr=tr0;IMPD.tr=tr0;BMEM.side=tr0?.6:0;lastTouch=t-10;SLP.lastAny=t-10;E4.count=0;E4.lastT=-99;E4.wait=-1;EYE.user=-9;BMEM.offerAt=-99;LIFE.until=-1;
   const T0=t;let f=null,kind='',pu=EYE.user,pl=BMEM.leans,firstMove=null,ps=LIFE.sns.length;
   for(let k=0;k<3600&&f===null;k++){steps(1);if(firstMove===null&&(LIFE.sns.length>ps||GAIT.on))firstMove=t-T0;if(E4.on){f=t-T0;kind='e4'}else if(BMEM.leans>pl){f=t-T0;kind='offer'}else if(EYE.user>pu+.2){f=t-T0;kind='eye'}pu=Math.max(pu,EYE.user)}
   firsts.push(f===null?null:[+f.toFixed(1),kind]);any.push(firstMove===null?null:+firstMove.toFixed(1))}
  out['tr'+tr0]={firsts,firstMove:any}}
 return out;
