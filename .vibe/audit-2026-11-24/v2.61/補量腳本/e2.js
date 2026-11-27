// 停住：身高、記住、長幾 R。ARG.sl 角色、ARG.cf 設定、ARG.seeds
const out=[];
function one(cf,sl,sd,m){ // m: {g:'head'|'tip', d, v, hold}
 fresh(sd,CFG[cf],{slime:sl});const h0=ext(Y);let wx,wy;if(m.g==='head'){wx=globalC.xc;wy=globalC.yc-R*.6}else if(m.g==='cen'){wx=globalC.xc;wy=globalC.yc}else [wx,wy]=edgePt(0,-1,.25);
 const [x,y]=scr(wx,wy),lim=(y-4)/R,d=Math.min(m.d,lim);ev('pointerdown',1,x,y);steps(m.g!=='tip'?4:6);const n=Math.max(2,Math.round(d/m.v*60));let lmax=0;
 for(let j=1;j<=n;j++){ev('pointermove',1,x,y-d*R*j/n);steps(1);lmax=Math.max(lmax,ext(Y))}
 const s0=ext(Y),tr=[];for(let k=0;k<m.hold;k++){steps(60);tr.push(r3(ext(Y)))}
 const f=fingers.get(1),held=!!f&&f.mode==='grab',st=MOOD.strain,esc0=ESC.on;ev('pointerup',1,x,y-d*R);steps(6);const q1=ext(QY);steps(114);
 return{cf,sl,sd,g:m.g,d:m.d,eff:r2(d),lim:r2(lim),v:m.v,h0:r3(h0),stop:r3(s0),s:tr,held,strain:r2(st),esc:ESC.on||esc0,q01:r3(q1),q2:r3(ext(QY)),y2:r3(ext(Y)),len2:r3(blen()),z:r2(CAM.z)}}
const M=[{g:'head',d:3,v:18,hold:2},{g:'tip',d:3,v:1.5,hold:2},{g:'tip',d:3,v:4,hold:2},{g:'tip',d:4,v:1.5,hold:2},{g:'tip',d:4,v:4,hold:2},{g:'tip',d:4,v:15,hold:2},{g:'tip',d:5,v:15,hold:3},{g:'tip',d:5,v:25,hold:3},{g:'head',d:5,v:25,hold:3},{g:'cen',d:5,v:25,hold:3},{g:'tip',d:2,v:4,hold:2}];
for(const sl of ARG.sl)for(const cf of ARG.cf)for(const m of M)for(let sd=1;sd<=ARG.seeds;sd++)out.push(one(cf,sl,sd,m));
return out;
