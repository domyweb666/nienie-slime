 // 情緒摸不摸得出來：同一隻（芋圓），狀態不同（普通、很熟很舒服、很戒、心情 -1、心情 +1、剛睡醒），按中間 1 秒、往右上拉 1.5R 停 1 秒再放手
 // 量：按 0.2／1.0 秒外框最大位移（點）、拉住時被拉開的量 SB（R）與整團跟了多少（R）、放手後第一次回到一半的時間與最大回彈
 const out={};
 const S={base:[.3,0,0,.1],trust:[1,0,.8,.6],wary:[.1,1,-.6,-.6],moodLow:[.3,0,0,-1],moodHigh:[.3,0,0,1]};
 const prep=(k)=>{const [tr,w,c,m]=S[k];for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(21);BRAIN.seed=999;chooseSlime(2);setup();fxReset();impReset();brainReset();t=60;lastTouch=t-6;SLP.lastAny=t-6;
   const hold=()=>{IMP.tr=tr;IMP.w=w;IMPD.tr=tr;IMPD.w=w;BRAIN.m=m;BRAIN.mS=m;MOOD.c=c;BRAIN.q=.1;BRAIN.e=.1;BRAIN.z=.1;BRAIN.s=0;LIFE.st='rest';LIFE.until=t+9};for(let i=0;i<240;i++){hold();steps(1)}return hold};
 const base=()=>bnd.map(i=>[X[i],Y[i]]);
 for(const k in S){const r={};
   {const hold=prep(k);const b0=base(),idx=[...bnd];const [sx,sy]=scr(globalC.xc,globalC.yc);ev('pointerdown',1,sx,sy);const md=()=>{let m=0,s=0;idx.forEach((i,j)=>{const d=Math.hypot(X[i]-b0[j][0],Y[i]-b0[j][1]);m=Math.max(m,d);s+=d});return[+m.toFixed(1),+(s/idx.length).toFixed(2)]};
    for(let j=1;j<=60;j++){hold();steps(1);if(j===3)r.p50=md();if(j===12)r.p200=md();if(j===60)r.p1000=md()}ev('pointerup',1,sx,sy)}
   {const hold=prep(k);const c0=[globalC.xc,globalC.yc];const [sx,sy]=scr(globalC.xc+R*.5,globalC.yc-R*.4);ev('pointerdown',1,sx,sy);steps(4);const L=R*CAM.z*1.5;for(let j=1;j<=24;j++){ev('pointermove',1,sx+L*.8*j/24,sy-L*.6*j/24);hold();steps(1)}for(let j=0;j<60;j++){hold();steps(1)}
    const f=fingers.get(1);r.SB=f?+SB(f).toFixed(2):null;r.follow=+(Math.hypot(globalC.xc-c0[0],globalC.yc-c0[1])/R).toFixed(2);r.mode=f?f.mode:'-';
    const w0=(()=>{let a=1e9,b=-1e9;for(const i of bnd){const p=X[i]*.8-Y[i]*.6;a=Math.min(a,p);b=Math.max(b,p)}return b-a})();ev('pointerup',1,sx+L*.8,sy-L*.6);let half=null;const len=()=>{let a=1e9,b=-1e9;for(const i of bnd){const p=X[i]*.8-Y[i]*.6;a=Math.min(a,p);b=Math.max(b,p)}return b-a};const l1=[];for(let j=1;j<=60;j++){steps(1);l1.push(len())}r.len0=+(w0/R).toFixed(2);r.len200=+(l1[11]/R).toFixed(2);r.len1000=+(l1[59]/R).toFixed(2)}
   out[k]=r}
 return out;
