// 快扯、慢拉：strain、抗議、逃、戒、熟、往回拔
const out=[];const DIRS={up:[0,-1],across:[1,-.05],upc:[0,-1]},GR={across:[-1,0]};
function one(cf,sl,sd,dn,d,v,hold,tr,w){fresh(sd,CFG[cf],{slime:sl,tr,w});const ux0=DIRS[dn][0],uy0=DIRS[dn][1],l=Math.hypot(ux0,uy0),ux=ux0/l,uy=uy0/l,[wx,wy]=dn==='upc'?[globalC.xc,globalC.yc]:edgePt(...(GR[dn]||[ux,uy]),.2),[sx,sy]=scr(wx,wy);
 let te=1e9;if(ux>1e-6)te=Math.min(te,(W-4-sx)/ux);if(ux<-1e-6)te=Math.min(te,(4-sx)/ux);if(uy>1e-6)te=Math.min(te,(H-4-sy)/uy);if(uy<-1e-6)te=Math.min(te,(4-sy)/uy);
 const dd=Math.min(d*R,te),tr0=IMP.tr,w0=IMP.w,r={cf,sl,sd,dn,d,eff:r2(dd/R),v,hold,tr,w,strain:0,tug:0,tugPx:0,red:0,sq:0,st:0,vMax:0,yank:false,lost:null,esc:false};let k=0;
 const rec=()=>{const f=fingers.get(1);if(!f||f.mode!=='grab'){if(r.lost==null)r.lost=r2(k/60)}else{r.st=Math.max(r.st,SB(f));r.vMax=Math.max(r.vMax,f.vMax||0);r.yank=r.yank||!!f.yank}
  r.strain=Math.max(r.strain,MOOD.strain);r.tug=Math.max(r.tug,MOOD.tugS||0);r.tugPx=Math.max(r.tugPx,Math.hypot(MOOD.tugX||0,MOOD.tugY||0)/R);r.red=Math.max(r.red,MC.s);if(EYE.mode==='squeeze')r.sq++;k++};
 ev('pointerdown',1,sx,sy);steps(3,rec);const n=Math.max(1,Math.round(dd/R/v*60));let x=sx,y=sy;for(let j=1;j<=n;j++){x=sx+ux*dd*j/n;y=sy+uy*dd*j/n;ev('pointermove',1,x,y);steps(1,rec)}
 steps(Math.round(hold*60),rec);r.strainRel=r2(MOOD.strain);const hm=HOMEX;ev('pointerup',1,x,y);r.esc=ESC.on;steps(2);r.esc=r.esc||ESC.on;r.dTr=r3(IMP.tr-tr0);r.dW=r3(IMP.w-w0);r.prot=VO.filter(q=>q[1]==='protest').length;r.vo=VO.map(q=>q[1]).join(',');steps(90);r.fledR=r2((HOMEX-hm)/R);
 for(const q of ['strain','tug','tugPx','red','st','vMax'])r[q]=r3(r[q]);return r}
for(const sl of ARG.sl)for(const cf of ARG.cf)for(const dn in DIRS)for(const d of [2.4,3.5])for(const v of [15,1.5])for(const hold of v>=7?[.1,.4,1,2,3]:[.4,1,3])for(const [tr,w] of ARG.tw)for(let sd=1;sd<=ARG.seeds;sd++)out.push(one(cf,sl,sd,dn,d,v,hold,tr,w));
return out;
