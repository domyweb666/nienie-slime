 // 放著不碰 20 分鐘（白天、窗台、熟 tr 由 SEED 決定：1,2 → 0；3,4 → 1），記：在做什麼的比例、每種第一次出現的時間、張望方向、朝你做的事
 const tr0=[0,0,1,1][(SEED-1)%4];
 setup();fxReset();impReset();brainReset();IMP.tr=tr0;IMPD.tr=tr0;BMEM.cell=[0,0,0,0,0];BMEM.side=tr0?.6:0;lastTouch=t-5;SLP.lastAny=t-5;steps(120);
 const T0=t,share={},first={},looks=[],ev2=[];let pn=LIFE.sns.length?LIFE.sns[LIFE.sns.length-1]:null,pu=EYE.user,pe4=E4.on,plean=E2.leanT,pf=FLN.t0,ps=BRX.sighCyc,pd=DR.n.look,pbm=BMEM.leans,ptw=MOOD.wagT,lastAct='',chg=0,dwell=[],dw=0;
 const evN={};const E=(k)=>{evN[k]=(evN[k]||0)+1;if(first[k]==null)first[k]=+(t-T0).toFixed(1)};
 const N20=60*60*20;
 for(let k=0;k<N20;k++){steps(1);const a=BRAIN.act;share[a]=(share[a]||0)+1;if(first['act:'+a]==null)first['act:'+a]=+(t-T0).toFixed(1);
  if(a!==lastAct){chg++;lastAct=a}
  const s=LIFE.sns.length?LIFE.sns[LIFE.sns.length-1]:null;if(s&&s!==pn){const c=globalC,h=E4.on?'e4':LIFE.st;looks.push([+(Math.cos(s.a)).toFixed(2),+(Math.sin(s.a)).toFixed(2),h]);E('sniff')}pn=s;
  if(EYE.user>pu+.2){E('eyeUser')}pu=EYE.user;if(E4.on&&!pe4)E('e4');pe4=E4.on;if(BMEM.leans>pbm)E('offer');pbm=BMEM.leans;if(E2.leanT!==plean){E('lean');plean=E2.leanT}
  if(FLN.t0!==pf){E('flinch');pf=FLN.t0}if(BRX.sighCyc>=0&&ps<0)E('sigh');ps=BRX.sighCyc;if(DR.n.look>pd)E('decoLook');pd=DR.n.look;if(MOOD.wagT!==ptw){E('wag');ptw=MOOD.wagT}
 }
 for(const k in share)share[k]=+(share[k]/N20*100).toFixed(1);
 const down=looks.filter(x=>x[1]>.3).length,up=looks.filter(x=>x[1]<-.3).length,side=looks.length-down-up;
 return{tr0,share,evN,first,acts:chg,looks:looks.length,down,up,side,naps:BRAIN.naps,selfWake:BRAIN.selfWake,q:+BRAIN.q.toFixed(2),cats:DR.n.cat,samples:looks.slice(0,12)};
