(async()=>{window.requestAnimationFrame=()=>0;await new Promise(r=>setTimeout(r,80));
IMPSV.noSave=true;WALK.noSave=true;const log=[];const op=sfxPlay;sfxPlay=(k,g,r)=>{log.push([+t.toFixed(2),k])};
const DT=1/60;const steps=n=>{for(let i=0;i<n;i++)update(DT)};
const ev=(type,id,x,y)=>cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}));
const seeded=seed=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296}};
const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
const fresh=sd=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(65+sd*1000);setup();t=0;lastTouch=-10;nextTwitch=3;tLife=0;relaxUntil=-1;SLP.lastAny=-99;SLP.on=false;SLP.k=0;impReset();ESC.on=false;DENTS.length=0;BRAIN.seed=65+sd*1000;brainReset();Object.assign(MOOD,{c:0,a:0,strain:0,strainMax:0,scare:0,cowerUntil:-9,happyT:-9,wagT:-9,taps:[]});Object.assign(FLN,{at:-9,t0:-9,amp:0,H:1,s:1});PURR=0;INTRO.on=false;SWIM.on=false;steps(150);log.length=0};
const out=[];

const dim=()=>{let x0=1e9,x1=-1e9,y0=1e9,y1=-1e9;for(const i of bnd){x0=Math.min(x0,X[i]);x1=Math.max(x1,X[i]);y0=Math.min(y0,Y[i]);y1=Math.max(y1,Y[i])}return[x1-x0,y1-y0]};
const cond=(nm,f)=>{fresh(21);const hs=[],ws=[];const t0=t;while(t-t0<9){f();LIFE.until=t+5;LIFE.st='rest';steps(1);if(t-t0>3){const d=dim();ws.push(d[0]);hs.push(d[1])}}const st=a=>{const m=a.reduce((x,y)=>x+y,0)/a.length;return[+m.toFixed(1),+(Math.max(...a)-Math.min(...a)).toFixed(1)]};out.push({nm,w:st(ws),h:st(hs)})};
cond('普通(心情.15,不熟)',()=>{BRAIN.m=BRAIN.mS=.15});
cond('心情+1',()=>{BRAIN.m=BRAIN.mS=1});
cond('心情-1',()=>{BRAIN.m=BRAIN.mS=-1});
cond('熟1',()=>{BRAIN.m=BRAIN.mS=.15;IMP.tr=IMPD.tr=1});
cond('戒.6',()=>{BRAIN.m=BRAIN.mS=.15;IMP.w=IMPD.w=.6});
cond('舒服1',()=>{BRAIN.m=BRAIN.mS=.15;MOOD.c=1});
cond('睡著',()=>{BRAIN.m=BRAIN.mS=.15;SLP.on=true});
return out})()
