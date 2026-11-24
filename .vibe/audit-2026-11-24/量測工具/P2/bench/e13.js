// 每一種表演的外框最大位移（毫米）與重心位移；靠邊時逃與退的距離
const out={};const MM=.16565;
const meas=(nm,start,frames,opt)=>{fresh(81,{deco:0,decoReal:0},{tr:(opt||{}).tr==null?.5:opt.tr,w:(opt||{}).w||0,settle:260});const hold=()=>{LIFE.st='rest';LIFE.until=t+1e6;GAIT.on=false;BRX.sighNext=t+99};
 // 先記一段只有呼吸的外框範圍
 let lo=[],hi=[];for(const i of bnd){lo.push([1e9,1e9]);hi.push([-1e9,-1e9])}
 for(let k=0;k<400;k++){hold();update(DT);bnd.forEach((i,j)=>{lo[j][0]=Math.min(lo[j][0],X[i]);hi[j][0]=Math.max(hi[j][0],X[i]);lo[j][1]=Math.min(lo[j][1],Y[i]);hi[j][1]=Math.max(hi[j][1],Y[i])})}
 const c0=[globalC.xc,globalC.yc];start();let mx=0,mc=0,mcy=0,tpk=0,A=1;const A0b=geo().A;
 for(let k=0;k<frames;k++){if(!(opt&&opt.free))hold();update(DT);let m=0;bnd.forEach((i,j)=>{const dx=Math.max(lo[j][0]-X[i],X[i]-hi[j][0],0),dy=Math.max(lo[j][1]-Y[i],Y[i]-hi[j][1],0);m=Math.max(m,Math.hypot(dx,dy))});if(m>mx){mx=m;tpk=k/60}mc=Math.max(mc,Math.abs(globalC.xc-c0[0]));mcy=Math.max(mcy,c0[1]-globalC.yc);A=Math.min(A,geo().A/A0b)}
 out[nm]={edgeMM:r2(mx*MM),dxMM:r2(mc*MM),upMM:r2(mcy*MM),tPeak:r2(tpk),Amin:r3(A)}};
meas('搖(打招呼)',()=>{MOOD.wagT=t},110);
meas('伸偽足探(右上)',()=>{startSniff(-.6,.6,1.2,1,.8)},190);
meas('朝手指傾',()=>{E2.leanT=t;E2.leanA=-.6;E2.leanS=1},50);
meas('往反方向傾(戒)',()=>{E2.leanT=t;E2.leanA=-.6;E2.leanS=-1},50);
meas('小跳',()=>{hop()},70,{free:1});
meas('甩一甩',()=>{Object.assign(SHK,{at:-9,t0:t,amp:.8})},50);
meas('縮一下(普通)',()=>{FLN.at=t+.02;FLN.pre='rest';FLN.boost=1},40);
meas('縮一下(戒.9)',()=>{FLN.at=t+.02;FLN.pre='rest';FLN.boost=1},40,{w:.9,tr:0});
meas('節奏回一下',()=>{echoBeat(0)},40);
meas('開心挺高',()=>{MOOD.happyT=t},120);
meas('縮著 cower 1.5 秒',()=>{MOOD.cowerUntil=t+1.5},120);
meas('嚇 scare .45(點一下)',()=>{MOOD.scare=.45},60);
meas('大口嘆氣',()=>{BRX.sighNext=t},260,{free:1});
// 蹭
{fresh(82,{deco:0,decoReal:0},{tr:.5,settle:240});const p=scr(globalC.xc,globalC.yc-R*.3);ev('pointerdown',1,p[0],p[1]);steps(60);let a=1e9,b=-1e9;for(let i=0;i<240;i++){update(DT);a=Math.min(a,globalC.xc);b=Math.max(b,globalC.xc)}ev('pointerup',1,p[0],p[1]);out['按著不動蹭(左右峰對峰)']={dxMM:r2((b-a)*MM)}}
// 靠邊逃：家在最右，戳左半 3 下；家在最左，戳右半 3 下；家在中間
out.fleeEdge=[];for(const [nm,hx,side] of [['中間',196.5,-.3],['最右、戳左邊',293,-.3],['最左、戳右邊',100,.3]]){fresh(83,{deco:0,decoReal:0},{tr:.2,settle:60});const d=hx-HOMEX;HOMEX+=d;for(let i=0;i<N;i++){X[i]+=d;PX[i]+=d}steps(200);const hold=()=>{LIFE.st='rest';LIFE.until=t+1e6};const x0=globalC.xc;for(let k=0;k<3;k++){const p=scr(globalC.xc+side*R,globalC.yc-R*.15);ev('pointerdown',1,p[0],p[1]);for(let i=0;i<5;i++){hold();update(DT)}ev('pointerup',1,p[0],p[1]);for(let i=0;i<12;i++){hold();update(DT)}}let m=0;for(let i=0;i<150;i++){hold();update(DT);if(Math.abs(globalC.xc-x0)>Math.abs(m))m=globalC.xc-x0}out.fleeEdge.push({nm,mm:r2(m*MM),homeX:r2(HOMEX)})}
// 戒：手指放旁邊，牠退多遠；靠邊時
out.backEdge=[];for(const [nm,hx,sd] of [['中間',196.5,1],['最左、手指在右',100,1]]){fresh(84,{deco:0,decoReal:0},{w:.8,settle:60});const d=hx-HOMEX;HOMEX+=d;for(let i=0;i<N;i++){X[i]+=d;PX[i]+=d}steps(200);const x0=globalC.xc,g=geo(),q=scr(g.x1+R*.5,g.cy);ev('pointerdown',1,Math.min(388,q[0]),q[1]);let m=0;for(let i=0;i<300;i++){IMP.w=.8;update(DT);if(Math.abs(globalC.xc-x0)>Math.abs(m))m=globalC.xc-x0}ev('pointerup',1,388,q[1]);out.backEdge.push({nm,mm:r2(m*MM)})}
return out;
