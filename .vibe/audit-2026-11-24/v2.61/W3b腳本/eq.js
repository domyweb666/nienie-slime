// 全開關 0：每格的粒子座標、記形、情緒、眼睛、大腦、擺飾、聲音做一條雜湊；最後畫面雜湊
const set=(o)=>{for(const k in PRESETS)Object.assign(PRESETS[k],o);Object.assign(mat,o)};set(K61.all0);
const fnv=new Uint32Array(1);const buf=new Float64Array(1),u8=new Uint8Array(buf.buffer);const H1=()=>{fnv[0]=2166136261};const ad=v=>{buf[0]=v;for(let k=0;k<8;k++)fnv[0]=Math.imul(fnv[0]^u8[k],16777619)};
const out={};for(const sl of [2,1])for(const sd of [1,2]){open(sd,{slime:sl,tr:sd===1?.1:.9});H1();const hs=[];const rec=()=>{for(let i=0;i<N;i++){ad(X[i]);ad(Y[i]);ad(QX[i])}ad(MOOD.c);ad(MOOD.scare);ad(IMP.tr);ad(IMP.w);ad(BRAIN.z);ad(BRAIN.q);ad(BRAIN.e);ad(BRAIN.m);ad(EYE.gx);ad(EYE.gy);ad(EYE.openD);ad(EYE.blink);ad(EYE.wideD);ad(SLP.k);ad(FLN.s);for(const p of PROPS){ad(p.x);ad(p.y);ad(p.a)}for(const v of BMEM.cell)ad(v)};
 const S=(n)=>{steps(n,rec);hs.push(fnv[0].toString(16))};const P=(a,b)=>scr(globalC.xc+a*R,globalC.yc+b*R);let p;
 S(60*30);                                    // 打開放著
 p=P(1.8,-.6);ev('pointerdown',1,...p);S(120);ev('pointerup',1,...p);S(60);      // 手指放旁邊
 for(let k=0;k<4;k++){ev('pointerdown',1,...p);S(6);ev('pointerup',1,...p);S(18)}S(300);   // 節奏
 p=P(0,0);ev('pointerdown',1,...p);S(30);for(let k=1;k<60;k++){ev('pointermove',1,p[0]+Math.sin(k/4)*R*.5,p[1]);S(1)}ev('pointerup',1,...p);S(200);   // 揉
 p=P(0,-.7);ev('pointerdown',1,...p);for(let k=1;k<40;k++){ev('pointermove',1,p[0],p[1]-k*R*.06);S(1)}S(60);ev('pointerup',1,p[0],p[1]-40*R*.06);S(240);   // 拉
 SLP.on=true;LIFE.st='sleep';BRAIN.z=.9;S(400);p=P(.2,0);ev('pointerdown',1,...p);S(12);ev('pointerup',1,...p);S(240);   // 睡著碰
 S(60*200);                                   // 放著睡、撞東西
 window.dispatchEvent(new Event('blur'));window.dispatchEvent(new Event('focus'));S(120);
 impBack(7e5);S(300);draw();const d=document.createElement('canvas');d.width=cv.width;d.height=cv.height;const c=d.getContext('2d');c.drawImage(cv,0,0);const px=c.getImageData(0,0,d.width,d.height).data;H1();let z=2166136261;for(let i=0;i<px.length;i++)z=Math.imul(z^px[i],16777619);
 out[SLIMES[sl].id+sd]={state:hs.join(','),px:(z>>>0).toString(16),snd:JSON.stringify(LOG),n:LOG.length}}
return out;
