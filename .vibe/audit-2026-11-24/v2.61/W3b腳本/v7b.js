const R1={};const set=(o)=>{for(const k in PRESETS)Object.assign(PRESETS[k],o);Object.assign(mat,o)};
const ON=Object.fromEntries(KEYS61.map(k=>[k,PRESETS.clay[k]])),OFF=K61.all0;const mean=a=>a.reduce((x,y)=>x+y,0)/(a.length||1),cv2=a=>a.length>1?Math.sqrt(mean(a.map(x=>(x-mean(a))**2)))/mean(a):0;
// 你推：手指抓東西上半往旁邊推；抓著牠甩過去
for(const [nm,o] of [['off',OFF],['on',ON]]){set(o);const r=[];for(const sd of [1,2,3]){for(const im of [0,1]){open(sd,{tr:.3});steps(300);const q=PROPS.filter(p=>p.deco)[im];const p=scr(q.x,q.y-q.h*.4);ev('pointerdown',1,p[0],p[1]);for(let k=1;k<=20;k++){ev('pointermove',1,p[0]+(im?-1:1)*k*6,p[1]);steps(1)}ev('pointerup',1,p[0],p[1]);let t0=0;steps(120,()=>{if(q.gone||Math.abs(Math.atan2(Math.sin(q.a),Math.cos(q.a)))>.6)t0=1});r.push(t0)}
  for(const dir of [-1,1]){open(sd,{tr:.3});steps(300);const p=scr(globalC.xc,globalC.yc);ev('pointerdown',1,p[0],p[1]);steps(6);for(let k=1;k<=14;k++){ev('pointermove',1,p[0]+dir*k*9,p[1]-k*3);steps(1)}ev('pointerup',1,p[0]+dir*126,p[1]-42);const q=PROPS.filter(p=>p.deco)[dir>0?1:0];let t0=0;steps(150,()=>{if(q.gone||Math.abs(Math.atan2(Math.sin(q.a),Math.cos(q.a)))>.6)t0=1});r.push('甩'+t0)}}R1['你推 '+nm]=r.join(' ')}
// 換隻記憶
set(ON);IMPSV.noSave=false;localStorage.removeItem('nienie.brain');open(3,{tr:0});for(const k in BMEMS)delete BMEMS[k];BMEM.cell=[0,.6,0,0,-.4];BMEM.side=-.5;BMEM.dirty=true;IMP.w=.7;const before=JSON.stringify(BMEM.cell);let bad=[];
for(const i of [3,4,5,6,7,8,9,0,1]){chooseSlime(i,true,true);steps(240);if(BMEM.cell.some(v=>v!==0)||BMEM.side!==0)bad.push(i);}
const m0=BRAIN.m;chooseSlime(2,true,true);const st=JSON.parse(localStorage.getItem('nienie.brain')||'null');steps(6);R1['換隻一圈']={別隻被串:bad,換回芋圓:JSON.stringify(BMEM.cell.map(v=>+v.toFixed(2))),side:+BMEM.side.toFixed(2),戒:+IMP.w.toFixed(2),心情:+BRAIN.m.toFixed(2),存檔有:st?Object.keys(st.all||{}).length:0};
BMEM.dirty=true;memSave(true);for(const k in BMEMS)delete BMEMS[k];BMEM.cell=[0,0,0,0,0];memLoad();R1['重開讀回']=JSON.stringify(BMEM.cell.map(v=>+v.toFixed(2)));
localStorage.setItem('nienie.brain',JSON.stringify({id:'taro',cell:[.5,0,0,0,-.5],side:.2,ts:Date.now()-864e5}));for(const k in BMEMS)delete BMEMS[k];memLoad();R1['舊格式讀回（討厭退一天）']=JSON.stringify(BMEM.cell.map(v=>+v.toFixed(2)));localStorage.removeItem('nienie.brain');
return R1;
