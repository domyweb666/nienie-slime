// 放著不碰 12 分鐘：牠自己做了什麼、主動對你的次數、時間點
const out=[];
for(const tr of [0,.5,.9])for(const sd of [1,2]){
  fresh(60+sd,{},{tr,settle:0});const c={};let last='';const ev2={greet:[],offer:[],cat:[],nap:[],wakeSelf:[],sniff:0,go:0,hello:0,eyeUser:0,eyeSelf:0};let e4c=0,of=0,ct=0,np=0,sw=0;let sn=null,n=0,moving=0,hx=[];let eyeYou=0,eyeN=0;
  for(let i=0;i<12*60*60;i++){update(DT);n++;const s=i/60;c[BRAIN.act]=(c[BRAIN.act]||0)+1;
    if(E4.on&&!sn){ev2.greet.push(r2(s));sn=true}if(!E4.on)sn=null;
    if(BMEM.leans>of){of=BMEM.leans;ev2.offer.push(r2(s))}if(DR.n.cat>ct){ct=DR.n.cat;ev2.cat.push(r2(s))}if(BRAIN.naps>np){np=BRAIN.naps;ev2.nap.push(r2(s))}if(BRAIN.selfWake>sw){sw=BRAIN.selfWake;ev2.wakeSelf.push(r2(s))}
    if(t<EYE.user)eyeYou++;if(i%30===0)hx.push(Math.round(globalC.xc))}
  const k={};for(const a in c)k[a]=r3(c[a]/n);
  const sd2=Math.sqrt(hx.reduce((a,b)=>a+(b-hx.reduce((x,y)=>x+y,0)/hx.length)**2,0)/hx.length);
  out.push({tr,sd,k,ev2,eyeYou:r3(eyeYou/n),xsdMM:r2(sd2*.16565),xmin:Math.min(...hx),xmax:Math.max(...hx),topple:LOG.filter(q=>q[1]==='fx.topple').length,startle:LOG.filter(q=>q[1]==='voice.startle').length,voices:LOG.filter(q=>q[1].startsWith('voice.')).length,fx:LOG.filter(q=>q[1].startsWith('fx.')).reduce((a,q)=>{a[q[1]]=(a[q[1]]||0)+1;return a},{}),m:r2(BRAIN.m),dr:{...DR.n}});
}
return out;
