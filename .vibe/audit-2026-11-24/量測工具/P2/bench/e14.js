const MM=.16565,out=[];
for(const [nm,hx,side] of [['中間戳左邊',196.5,-.3],['最右、戳左邊',293,-.3],['最右、戳右邊',293,.3],['最左、戳右邊',100,.3]]){fresh(83,{deco:0,decoReal:0},{tr:.2,settle:60});const hold=()=>{LIFE.st='rest';LIFE.until=t+1e6;BRAIN.homeAt=t};const d=hx-HOMEX;HOMEX+=d;for(let i=0;i<N;i++){X[i]+=d;PX[i]+=d}for(let i=0;i<200;i++){hold();update(DT)}
 const x0=globalC.xc,g0=geo();for(let k=0;k<3;k++){const p=scr(globalC.xc+side*R,globalC.yc-R*.15);ev('pointerdown',1,p[0],p[1]);for(let i=0;i<5;i++){hold();update(DT)}ev('pointerup',1,p[0],p[1]);for(let i=0;i<12;i++){hold();update(DT)}}
 let m=0,mxR=0,mnL=999;for(let i=0;i<150;i++){hold();update(DT);const g=geo();if(Math.abs(globalC.xc-x0)>Math.abs(m))m=globalC.xc-x0;mxR=Math.max(mxR,g.x1);mnL=Math.min(mnL,g.x0)}
 out.push({nm,x0:r2(x0),moved_mm:r2(m*MM),homeX:r2(HOMEX),bodyL:r2(mnL),bodyR:r2(mxR),esc:ESC.on})}
return out;
