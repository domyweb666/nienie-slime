// 一下一下摸；公分用 60 點＝1 公分（稽核的算法）
function pet(name,v,sd,over,opt){fresh(sd,over,opt);const px=v*60,T=10;let purr=0,tP=null,n=0,nS=0,g=0,dx=0,st=0,tr0=IMP.tr,x0=globalC.xc,mm=0,w0=IMP.w;const t0=t;
 const rec=()=>{const f=fingers.get(1);if(f&&f.mode==='grab')st=Math.max(st,SB(f));purr=Math.max(purr,PURR);if(tP==null&&PURR>.3)tP=r2(t-t0);g=Math.max(g,PET.g);dx=Math.max(dx,Math.abs(globalC.xc-x0)/R)};
 while(t-t0<T){const c=globalC;let wx,wy,ux=1,uy=0,L=1.2;if(name==='lift'||name==='rub'){wx=c.xc-R*.6;wy=c.yc-R*.35}else if(name==='short'){wx=c.xc-R*.5;wy=c.yc-R*.35;L=.8}else if(name==='down'){wx=c.xc+R*.45;wy=c.yc-R*.55;ux=0;uy=1;L=.9}else if(name==='topdown'){wx=c.xc-R*.45;wy=c.yc-R*.6;ux=.6;uy=.8;L=1}else if(name==='leftward'){wx=c.xc+R*.6;wy=c.yc-R*.2;ux=-1}else if(name==='outside'){wx=c.xc-R*1.5;wy=c.yc-R*.3;L=3}
  const [sx,sy]=scr(wx,wy);const Lp=L*R*CAM.z;let x=sx,y=sy,m=0,dir=1,ok=false;ev('pointerdown',1,x,y);
  while((name==='rub'||m<Lp)&&t-t0<T){const d=px*DT;x+=dir*ux*d;y+=dir*uy*d;m+=d;if(name==='rub'){if(x>sx+Lp){x=sx+Lp;dir=-1}if(x<sx){x=sx;dir=1}}ev('pointermove',1,x,y);steps(1,rec);const f=fingers.get(1);if(f&&f.mode==='stroke')ok=true}
  ev('pointerup',1,x,y);n++;if(ok)nS++;steps(18,rec)}
 return{purr:r2(purr),tP,n,nS,g:r2(g),shift:r2(dx),st:r2(st),dTr:r3(IMP.tr-tr0),dW:r3(IMP.w-w0),mmm:VO.filter(q=>q[1]==='mmm').length}}
// 往外拉 10 秒：拉 dist R、停 .5、放、等 .3，重複
function pulls(kind,v,sd,over,opt,dist){fresh(sd,over,opt);const K={topUp:[0,-1,0,-1,0],rightOut:[1,-.15,1,-.15,0],upRight:[.6,-.8,.6,-.8,0],leftUp:[-.7,-.7,-.7,-.7,0],centerUp:[0,-1,0,-1,1],centerRight:[1,0,1,0,1],centerUpL:[-.5,-.85,-.5,-.85,1],through:[1,0,-1,0,0],throughUp:[0,-1,0,1,0],midUp:[0,-1,0,-1,2],sideUp:[0,-1,1,-.2,0],topRight:[1,-.1,0,-1,0]}[kind];
 let purr=0,tP=null,n=0,g=0,tr0=IMP.tr,esc=0,lost=0;const t0=t,rec=()=>{purr=Math.max(purr,PURR);g=Math.max(g,PET.g);if(tP==null&&PURR>.3)tP=r2(t-t0);if(ESC.on)esc=1};const px=v*60;
 while(t-t0<10){let wx,wy;if(K[4]===1){wx=globalC.xc;wy=globalC.yc}else if(K[4]===2){wx=globalC.xc+K[0]*R*.5;wy=globalC.yc+K[1]*R*.5}else [wx,wy]=edgePt(K[2],K[3]);const [sx,sy]=scr(wx,wy),l=Math.hypot(K[0],K[1]),ux=K[0]/l,uy=K[1]/l;let x=sx,y=sy,m=0;ev('pointerdown',1,x,y);steps(3,rec);
  while(m<dist*R&&t-t0<10){m+=px*DT;x+=ux*px*DT;y+=uy*px*DT;ev('pointermove',1,x,y);steps(1,rec)}
  steps(30,rec);const f=fingers.get(1);if(!f||f.mode!=='grab')lost++;ev('pointerup',1,x,y);n++;steps(18,rec)}
 return{purr:r2(purr),tP,n,g:r2(g),dTr:r3(IMP.tr-tr0),esc,lost}}
