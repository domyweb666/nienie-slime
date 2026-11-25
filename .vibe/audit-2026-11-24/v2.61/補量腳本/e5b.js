// C3 慢摸。trips＝分開一趟一趟摸；rub＝不放手來回
const out=[];
const G={lift:[-.6,-.35,1,0,1.2],short:[-.5,-.35,1,0,.8],down:[.45,-.55,0,1,.9],topdown:[-.45,-.6,.6,.8,1],leftward:[.6,-.2,-1,0,1.2],rub:[-.6,-.35,1,0,1.2]};
function pet(cf,sl,sd,nm,v,T,gap){fresh(sd,CFG[cf],{slime:sl});const px=v*60,g=G[nm],t0=t;let purr=0,tP=null,tPh=null,n=0,nS=0,gm=0,st=0,dx=0,x0=globalC.xc,tr0=IMP.tr,w0=IMP.w,nP=null,dur=[],zero=0,modes={};
 const rec=()=>{const f=fingers.get(1);if(f){modes[f.mode]=(modes[f.mode]||0)+1;if(f.mode==='grab')st=Math.max(st,SB(f))}purr=Math.max(purr,PURR);if(tP==null&&PURR>.3){tP=r2(t-t0);nP=n+1}if(tPh==null&&PURR>.6)tPh=r2(t-t0);gm=Math.max(gm,typeof PET==='undefined'?0:PET.g);dx=Math.max(dx,Math.abs(globalC.xc-x0)/R)};
 while(t-t0<T){const c=globalC,[sx,sy]=scr(c.xc+R*g[0],c.yc+R*g[1]),Lp=g[4]*R*CAM.z;let x=sx,y=sy,m=0,dir=1,ok=false;const a0=t;ev('pointerdown',1,x,y);
  while((nm==='rub'||m<Lp)&&t-t0<T){const d=px*DT;x+=dir*g[2]*d;y+=dir*g[3]*d;m+=d;if(nm==='rub'){if(x>sx+Lp){x=sx+Lp;dir=-1}if(x<sx){x=sx;dir=1}}ev('pointermove',1,x,y);steps(1,rec);const f=fingers.get(1);if(f&&f.mode==='stroke')ok=true}
  dur.push(r2(t-a0));ev('pointerup',1,x,y);n++;if(ok)nS++;steps(Math.round(gap*60),rec)}
 return{cf,sl,sd,nm:nm+'_隔'+gap,v,T,purr:r2(purr),tP,tPh,nP,n,nS,dur1:dur[0],g:r2(gm),shift:r2(dx),st:r2(st),dTr:r3(IMP.tr-tr0),dW:r3(IMP.w-w0),mmm:VO.filter(q=>q[1]==='mmm').length,modes}}
for(const sl of ARG.sl)for(const cf of ARG.cf)for(const nm of ['lift','short','down'])for(const gap of [.6,1,2])for(const v of [.5,1,1.5,3])for(let sd=1;sd<=ARG.seeds;sd++)out.push(pet(cf,sl,sd,nm,v,20,gap));
return out;
