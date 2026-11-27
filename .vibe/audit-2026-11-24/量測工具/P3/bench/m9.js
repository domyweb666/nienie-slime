(async()=>{window.requestAnimationFrame=()=>0;await new Promise(r=>setTimeout(r,80));
IMPSV.noSave=true;WALK.noSave=true;const log=[];const op=sfxPlay;sfxPlay=(k,g,r)=>{log.push([+t.toFixed(2),k])};
const DT=1/60;const steps=n=>{for(let i=0;i<n;i++)update(DT)};
const ev=(type,id,x,y)=>cv.dispatchEvent(new PointerEvent(type,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===1}));
const seeded=seed=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296}};
const scr=(wx,wy)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(wx-CAM.x)*CAM.z+v.x+q.left,(wy-CAM.y)*CAM.z+v.y+q.top]};
const fresh=sd=>{for(const id of [...fingers.keys()])ev('pointerup',id,0,0);Math.random=seeded(65+sd*1000);setup();t=0;lastTouch=-10;nextTwitch=3;tLife=0;relaxUntil=-1;SLP.lastAny=-99;SLP.on=false;SLP.k=0;impReset();ESC.on=false;DENTS.length=0;BRAIN.seed=65+sd*1000;brainReset();Object.assign(MOOD,{c:0,a:0,strain:0,strainMax:0,scare:0,cowerUntil:-9,happyT:-9,wagT:-9,taps:[]});Object.assign(FLN,{at:-9,t0:-9,amp:0,H:1,s:1});PURR=0;INTRO.on=false;SWIM.on=false;steps(150);log.length=0};
const out=[];

const dim=()=>{let x0=1e9,x1=-1e9,y0=1e9,y1=-1e9;for(const i of bnd){x0=Math.min(x0,X[i]);x1=Math.max(x1,X[i]);y0=Math.min(y0,Y[i]);y1=Math.max(y1,Y[i])}return[x1-x0,y1-y0]};

const cond=(nm,f,setup0)=>{fresh(21);if(setup0)setup0();const hs=[],ws=[],cy=[];const t0=t;while(t-t0<26){f();steps(1);if(t-t0>8){const d=dim();ws.push(d[0]);hs.push(d[1]);cy.push(globalC.yc)}}const st=a=>{const m=a.reduce((x,y)=>x+y,0)/a.length;return[+m.toFixed(1),+(Math.max(...a)-Math.min(...a)).toFixed(1)]};
 // 呼吸週期：高度訊號的過零
 const m=hs.reduce((x,y)=>x+y,0)/hs.length;let z=0;for(let k=1;k<hs.length;k++)if(hs[k-1]<m&&hs[k]>=m)z++;out.push({nm,w:st(ws),h:st(hs),yc:st(cy),cyc:z,perMin:+(z/(hs.length/60)*60).toFixed(1),k:+SLP.k.toFixed(2),st:LIFE.st,brAmp:+BR.amp.toFixed(2)})};
cond('醒著休息',()=>{LIFE.until=t+5;LIFE.st='rest';BRAIN.z=.1});
cond('自然睡著(LIFE.st=sleep)',()=>{SLP.on=true;LIFE.st='sleep';BRAIN.z=.8},()=>{SLP.on=true;LIFE.st='sleep'});
return out})()
