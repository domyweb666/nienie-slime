// C7：無人 60 分鐘，睡的間隔、醒來第一件、自己撞倒、聲音；你推的照倒
const R1={};const set=(o)=>{for(const k in PRESETS)Object.assign(PRESETS[k],o);Object.assign(mat,o)};
const ON=Object.fromEntries(KEYS61.map(k=>[k,PRESETS.clay[k]])),OFF=K61.all0;const mean=a=>a.reduce((x,y)=>x+y,0)/(a.length||1),cv2=a=>a.length>1?Math.sqrt(mean(a.map(x=>(x-mean(a))**2)))/mean(a):0;
for(const [nm,o] of [['off',OFF],['on',ON]]){set(o);for(const sd of [11,22,33]){open(sd,{tr:.3});let was=false,at=-1,ivs=[],dur=[],wakes={},need=false,top=0,fall=0,kn=0,sl=0;const op=brainPick;let wk=[];brainPick=c=>{const w=op(c);if(need){if(w==='rest')wakes.rest0=(wakes.rest0||0);else{wk.push(w);need=false}}return w};
  let firstDec={},nd=false;const op2=brainPick;brainPick=c=>{const w=op2(c);if(nd){firstDec[w]=(firstDec[w]||0)+1;nd=false}return w};
  steps(60*60*60,()=>{if(SLP.on)sl++;if(SLP.on!==was){if(SLP.on){if(at>=0)ivs.push(t-at);at=t}else{dur.push(t-at);need=true;nd=true}was=SLP.on}});brainPick=op;
  const c={};for(const w of wk)c[w]=(c[w]||0)+1;const n=(k)=>LOG.filter(x=>x[1]===k).length;
  R1['C7 '+nm+' '+sd]={睡次:dur.length,間隔:Math.round(mean(ivs))+'cv'+cv2(ivs).toFixed(2),睡長:Math.round(mean(dur))+'cv'+cv2(dur).toFixed(2),睡pct:Math.round(sl/2160),醒後第一決定:firstDec,醒後第一動作:c,topple:n('fx.topple'),fallout:n('fx.fallout'),knock:LOG.filter(x=>/^knock/.test(x[1])).length,startle:n('voice.startle'),voice:LOG.filter(x=>/^voice/.test(x[1])).length,全部聲音:LOG.length}}}
// 你推：手指抓東西上半往旁邊推；抓著牠甩過去
for(const [nm,o] of [['off',OFF],['on',ON]]){set(o);const r=[];for(const sd of [1,2,3]){for(const im of [0,1]){open(sd,{tr:.3});steps(300);const q=PROPS.filter(p=>p.deco)[im];const p=scr(q.x,q.y-q.h*.4);ev('pointerdown',1,p[0],p[1]);for(let k=1;k<=20;k++){ev('pointermove',1,p[0]+(im?-1:1)*k*6,p[1]);steps(1)}ev('pointerup',1,p[0],p[1]);let t0=0;steps(120,()=>{if(q.tip||q.gone||q.fell)t0=1});r.push(t0)}
  for(const dir of [-1,1]){open(sd,{tr:.3});steps(300);const p=scr(globalC.xc,globalC.yc);ev('pointerdown',1,p[0],p[1]);steps(6);for(let k=1;k<=14;k++){ev('pointermove',1,p[0]+dir*k*9,p[1]-k*3);steps(1)}ev('pointerup',1,p[0]+dir*126,p[1]-42);const q=PROPS.filter(p=>p.deco)[dir>0?1:0];let t0=0;steps(150,()=>{if(q.tip||q.gone||q.fell)t0=1});r.push('甩'+t0)}}R1['你推 '+nm]=r.join(' ')}
// 換隻記憶
set(ON);IMPSV.noSave=false;localStorage.removeItem('nienie.brain');open(3,{tr:0});for(const k in BMEMS)delete BMEMS[k];BMEM.cell=[0,.6,0,0,-.4];BMEM.side=-.5;BMEM.dirty=true;IMP.w=.7;const before=JSON.stringify(BMEM.cell);let bad=[];
for(const i of [3,4,5,6,7,8,9,0,1]){chooseSlime(i,true,true);steps(240);if(BMEM.cell.some(v=>v!==0)||BMEM.side!==0)bad.push(i);}
const m0=BRAIN.m;chooseSlime(2,true,true);const st=JSON.parse(localStorage.getItem('nienie.brain')||'null');steps(6);R1['換隻一圈']={別隻被串:bad,換回芋圓:JSON.stringify(BMEM.cell.map(v=>+v.toFixed(2))),side:+BMEM.side.toFixed(2),戒:+IMP.w.toFixed(2),心情:+BRAIN.m.toFixed(2),存檔有:st?Object.keys(st.all||{}).length:0};
BMEM.dirty=true;memSave(true);for(const k in BMEMS)delete BMEMS[k];BMEM.cell=[0,0,0,0,0];memLoad();R1['重開讀回']=JSON.stringify(BMEM.cell.map(v=>+v.toFixed(2)));
localStorage.setItem('nienie.brain',JSON.stringify({id:'taro',cell:[.5,0,0,0,-.5],side:.2,ts:Date.now()-864e5}));for(const k in BMEMS)delete BMEMS[k];memLoad();R1['舊格式讀回（討厭退一天）']=JSON.stringify(BMEM.cell.map(v=>+v.toFixed(2)));localStorage.removeItem('nienie.brain');
return R1;
