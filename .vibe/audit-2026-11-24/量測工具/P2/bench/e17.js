// 慢慢拉長（每秒 1.5R）停 1 秒放手：算不算被扯。現在（slide 4、無限拉）對 v2.53（slide 1.5、沒有無限拉）
const out=[];
for(const [nm,ov] of [['現在',{}],['v2.53',{slide:1.5,endless:0}]])for(const tr of [0,.9])for(const [dx,dy,dn] of [[0,-1,'上'],[.7,-.714,'斜上']])for(const dist of [1,1.5,2,2.5,3.5]){
 fresh(91,{deco:0,decoReal:0,...ov},{tr,settle:240});LIFE.until=t+1e6;let bi=0,bd=-1e9;for(const i of bnd){const pp=(X[i]-globalC.xc)*dx+(Y[i]-globalC.yc)*dy;if(pp>bd){bd=pp;bi=i}}const[sx,sy]=scr(X[bi]-dx*R*.3,Y[bi]-dy*R*.3);const m0=BRAIN.m,w0=IMP.w;ev('pointerdown',1,sx,sy);steps(4);const fr=Math.round(dist/1.5*60);let st=0,red=0;for(let i=1;i<=fr;i++){ev('pointermove',1,Math.max(6,Math.min(387,sx+dx*R*dist*i/fr)),sy+dy*R*dist*i/fr);update(DT);for(const f of fingers.values())st=Math.max(st,SB(f));red=Math.max(red,MC.s)}
 for(let i=0;i<60;i++){update(DT);for(const f of fingers.values())st=Math.max(st,SB(f));red=Math.max(red,MC.s)}const sm=MOOD.strainMax;ev('pointerup',1,sx+dx*R*dist,sy+dy*R*dist);let esc=false;for(let i=0;i<60;i++){update(DT);if(ESC.on)esc=true}
 out.push({nm,tr,dn,dist,sb:r2(st),strain:r2(sm),red:r2(red),esc,dw:r3(IMP.w-w0),dm:r2(BRAIN.m-m0),dtr:r2(IMP.tr-tr)})}
return out;
