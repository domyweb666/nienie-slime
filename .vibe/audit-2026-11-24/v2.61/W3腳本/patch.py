import sys,io
sys.stdout.reconfigure(encoding='utf-8')
W='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/prototype/web/'
def load(f): return open(W+f,encoding='utf-8',newline='').read()
def save(f,s): open(W+f,'w',encoding='utf-8',newline='').write(s)
def rep(s,a,b,n=1):
    nl='\r\n' if '\r\n' in s else '\n'
    a=a.replace('\r\n','\n').replace('\n',nl);b=b.replace('\r\n','\n').replace('\n',nl)
    assert s.count(a)==n,(s.count(a),a[:120]);return s.replace(a,b)
s=load('index.html')
# ---- C1
s=rep(s,"  if(grab){SWIM.on=false;wake(true)}   // v2.23：游過來途中被抓就不打招呼；睡著被碰嚇醒",
"  GREET.st='';   // v2.61 C4：一碰就不看了，照平常\n  if(grab){SWIM.on=false;if(!(SLP.on&&softTouch(f)))wake(true)}   // v2.23：游過來途中被抓就不打招呼；睡著被碰嚇醒   // v2.61 C1（wakeSoft）：熟的先等 0.25 秒看是不是輕碰")
s=rep(s,"if(grab&&LV('lifeFlinch')&&!(FLN.at>t)){FLN.at=t+(.1+.15*Math.random())","if(grab&&LV('lifeFlinch')&&!(FLN.at>t)&&!SLP.on){FLN.at=t+(.1+.15*Math.random())")
s=rep(s,"  if(grab&&mat.life2>=.5){cutSniffs();GAIT.on=false;GAIT.k=1;WANDER.moving=false;LIFE.st='rest';LIFE.until=-1;LIFE.ask=null}",
"  if(grab&&mat.life2>=.5){cutSniffs();GAIT.on=false;GAIT.k=1;WANDER.moving=false;LIFE.st=SLP.on?'sleep':'rest';LIFE.until=-1;LIFE.ask=null}")
s=rep(s,"  if((f.gentleT||0)>1&&MOOD.c>.35&&!fingers.size){MOOD.happyT=t;","  if((f.gentleT||0)>1&&MOOD.c>.35&&!fingers.size&&!SLP.on){MOOD.happyT=t;")
s=rep(s,"  if(LV('lifeAttend')&&!ESC.on&&!INTRO.on&&Math.hypot(f.fx-globalC.xc,f.fy-globalC.yc)>R*.4)LIFE.att={at:t+.5,x:f.fx,y:f.fy,blank:false};\n  LIFE.st='rest';LIFE.until=t+1.5+2*Math.random()}",
"  if(SLP.on){LIFE.st='sleep';return}   // v2.61 C1：很熟、只翻一下沒醒\n  if(LV('lifeAttend')&&!ESC.on&&!INTRO.on&&Math.hypot(f.fx-globalC.xc,f.fy-globalC.yc)>R*.4)LIFE.att={at:t+.5,x:f.fx,y:f.fy,blank:false};\n  LIFE.st='rest';LIFE.until=t+1.5+2*Math.random()}")
s=rep(s,"function e2Release(f){if(!IV3('e2'))return;","function e2Release(f){if(!IV3('e2')||SLP.on)return;")
s=rep(s,"function impAsk(f){if(!IV2('impC4')||ESC.on||IMP.tr<.2)return;","function impAsk(f){if(!IV2('impC4')||ESC.on||SLP.on||IMP.tr<.2)return;")
s=rep(s,"const SLP={on:false,k:0,lastAny:-99,wakeT:-9,askAt:-9,nearT:0};",
"""const SLP={on:false,k:0,lastAny:-99,wakeT:-9,askAt:-9,nearT:0,openT:-99,slow:false,tap:null,n:0,rollT:-9,rollD:1,rollO:0};   // v2.61 C1：openT 哪一刻打開（換隻）的；slow 這次是慢慢醒；tap 睡著時碰牠的那根手指（還在看是輕碰還是猛按）；n 這一覺被輕碰幾次；roll 翻一下
// v2.61 C1（wakeSoft，多米：睡著輕碰就嚇醒）。熟（跟 lureStep 同一條：tr > 0.25 而且比 w 多 0.1）的牠睡著被碰，先不醒，看落下 T 秒：手快過每秒 v 個半徑、或拖開超過 st 個半徑是猛按，照舊嚇醒；
// 不然慢慢醒（閉著的眼睛用 slow 秒的時間常數睜開、不縮、不睜大）。很熟（deep）只翻一下（重心挪 roll 個半徑再回來，roT 秒）不醒，一覺第 n 次、按住 hold 秒、或之後拖開超過 st 才慢慢醒。不熟的照舊
const WAKEK={v:4,st:.8,T:.25,deep:.7,roll:.05,roT:1.4,n:3,hold:1.2,slow:.5};
function softTouch(f){if(!(mat.wakeSoft>=.5&&IMP.tr>.25&&IMP.tr-IMP.w>.1)||MOOD.taps.filter(x=>t-x<1).length>=2)return false;   // 一秒內第三下是連戳，照舊
  if(SLP.tap&&SLP.tap.f!==f)return false;SLP.tap={f,t0:t,done:false};return true}
function tapJudge(){const q=SLP.tap;if(!q)return;const f=q.f;if(!SLP.on){SLP.tap=null;return}
  const here=fingers.get(f.id)===f&&(f.mode==='grab'||t-f.hitT<.1),hv=Math.hypot(f.vxS,f.vyS)*CAM.z/R,off=Math.hypot(f.x-f.ax,f.y-f.ay)/R;
  if(!q.done){if(hv>=WAKEK.v||off>WAKEK.st){SLP.tap=null;wake(true);return}
    if(here&&t-q.t0<WAKEK.T)return;
    q.done=true;SLP.n++;
    if(IMP.tr>WAKEK.deep&&SLP.n<WAKEK.n){SLP.rollT=t;SLP.rollO=0;SLP.rollD=f.ax>=globalC.xc?1:-1}else{SLP.tap=null;wake(false,false,true);return}}
  if(!here){SLP.tap=null;return}
  if(f.yank)wake(true);else if(t-q.t0>WAKEK.hold||off>WAKEK.st)wake(false,false,true)}
function rollStep(dt){if(SLP.rollT<0)return;const u=(t-SLP.rollT)/WAKEK.roT,o=u>=0&&u<1?R*WAKEK.roll*(REDUCED?.5:1)*Math.sin(Math.PI*u)**2*SLP.rollD:0,d=o-SLP.rollO;SLP.rollO=o;if(d!==0)moveHome(d,0,dt);if(u>=1||u<0)SLP.rollT=-9}
const idleSec=()=>t-Math.max(lastTouch,SLP.lastAny,mat.wakeSoft>=.5&&SLP.openT<=t?SLP.openT:-99);   // 多久沒人理牠。v2.61 C1：剛打開從打開那一刻算起（以前開機時 lastTouch 是 -10，等於打開前 10 秒，所以 30 秒就睡）""")
s=rep(s,"  if(t-Math.max(lastTouch,SLP.lastAny)<(mat.sleepAfter||40)||","  if(idleSec()<(mat.sleepAfter||40)||")
s=rep(s,"  const cl=v=>Math.max(0,Math.min(1,v)),idleT=t-Math.max(lastTouch,SLP.lastAny),pz","  const cl=v=>Math.max(0,Math.min(1,v)),idleT=idleSec(),pz")
s=rep(s,"calm=1-B.f,idleT=t-Math.max(lastTouch,SLP.lastAny);","calm=1-B.f,idleT=idleSec(),opening=mat.wakeSoft>=.5&&t>=SLP.openT&&t-SLP.openT<(mat.sleepAfter||40);")
s=rep(s,"['sleep',sleepOK()&&idleT>8&&B.z>.5?B.z*calm+n():-1","['sleep',!opening&&sleepOK()&&idleT>8&&B.z>B.zAt?B.z*calm+n():-1")
s=rep(s,"function wake(sharp,self){if(!SLP.on)return;SLP.on=false;SLP.wakeT=t;SLP.nearT=0;LIFE.st","function wake(sharp,self,slow){if(!SLP.on)return;SLP.on=false;SLP.wakeT=t;SLP.nearT=0;SLP.slow=!!slow;SLP.n=0;SLP.tap=null;LIFE.st")
s=rep(s,"  if(SLP.on)for(const f of fingers.values())if(t-f.hitT<.05){wake(true);break}   // 從外面推進來碰到它\n  SLP.k+=((SLP.on?1:0)-SLP.k)*(1-Math.exp(-dt/(SLP.on?1.6:.25)));",
"  tapJudge();\n  if(SLP.on)for(const f of fingers.values())if(t-f.hitT<.05&&!(SLP.tap&&SLP.tap.f===f)&&!softTouch(f)){wake(true);break}   // 從外面推進來碰到它\n  rollStep(dt);\n  SLP.k+=((SLP.on?1:0)-SLP.k)*(1-Math.exp(-dt/(SLP.on?1.6:SLP.slow?WAKEK.slow:.25)));")
s=rep(s,"||t-SLP.wakeT<.8||BRM()","||t-SLP.wakeT<.8&&!SLP.slow||BRM()")
s=rep(s,"Object.assign(SLP,{on:false,k:0,askAt:-9,nearT:0});Object.assign(ECHO","Object.assign(SLP,{on:false,k:0,askAt:-9,nearT:0,slow:false,tap:null,n:0,rollT:-9,rollO:0});Object.assign(ECHO")
# ---- C2
s=rep(s,"  if(ECHO.st!=='idle')return;   // v2.23 C6：在聽你的節奏、在回你：停在原地\n  if(LIFE.st==='rest'&&!BRon()&&sleepTry())return;   // v2.41 大腦開著：睡不睡由 brainRest 決定\n  const lured=lureStep(dt);   // v2.20 C1 C2：手指放在旁邊時交給 lureStep",
"  const hear=ECHO.st==='listen'&&mat.nearFast>=.5;   // v2.61 C2（nearFast）：還在聽（手指可能就是要放著），照樣看旁邊的手指、靠過去；在回你的時候才停\n  if(ECHO.st!=='idle'&&!hear)return;   // v2.23 C6：在聽你的節奏、在回你：停在原地\n  if(LIFE.st==='rest'&&!BRon()&&sleepTry())return;   // v2.41 大腦開著：睡不睡由 brainRest 決定\n  const lured=lureStep(dt);   // v2.20 C1 C2：手指放在旁邊時交給 lureStep\n  if(hear&&!lured)return;")
# ---- B4
s=rep(s,"  if(g)o=tow(g.fx,g.fy);else if(pf)o=tow(pf.fx,pf.fy);","  if(g||pf){const q=g||pf;o=mat.eyeTrue>=.5?tow(q.x,q.y):tow(q.fx,q.fy)}   // v2.61 B4（eyeTrue）：看手指現在的位置，不看慢一拍（lag）的那根")
# ---- C4
s=rep(s,"  else if(t<DR.lookT&&!SLP.on&&DRon())o=tow(DR.lx,DR.ly);","  else if(GREET.st==='wait'&&GREET.open)o=[0,.9];else if(t<GREET.until)o=[0,0];   // v2.61 C4：往下掉的時候看著下面，落地轉過來看你\n  else if(t<DR.lookT&&!SLP.on&&DRon())o=tow(DR.lx,DR.ly);")
s=rep(s,"// B2 睡著：40 秒沒人碰（點空白處也算碰）",
"""// v2.61 C4（greetLook，多米：打開、切回來都先看你）：打開、換隻等落地（窗台），切回來等 0.35 秒，轉過來看你、眨一下，看完再做別的。跟離開多久無關。睡著就慢慢醒（不出聲）。碰牠就不看了。不出聲、不動身體，只有眼睛
const GREET={st:'',open:false,at:-9,t0:-9,until:-9,blurT:-9,air:false},GREETK={land:.2,back:.35,look:1.4,blink:.25,max:8};
function greetArm(open){if(!(mat.greetLook>=.5&&mat.life2>=.5&&mat.eyes>=.5)||fingers.size||GREET.st==='wait')return;Object.assign(GREET,{st:'wait',open,t0:t,until:-9,air:false,at:open?-9:t+GREETK.back});
  if(!open&&SLP.on)wake(false,true,true)}
function greetStep(){const G=GREET;if(G.st!=='wait')return;
  if(!(mat.greetLook>=.5)||fingers.size||t<G.t0||t-G.t0>GREETK.max){G.st='';return}
  if(G.open&&G.at<0){if(SILL.on&&(SILL.air||SILL.route)||INTRO.on||SWIM.on){G.air=true;return}if(SILL.on&&!G.air&&t-G.t0<.1)return;G.at=t+GREETK.land}   // 打開：落地那一刻起算
  if(G.open&&LIFE.st==='rest')LIFE.until=Math.max(LIFE.until,G.at+GREETK.look+.1);
  if(t<G.at)return;
  G.st='';G.until=t+GREETK.look;EYE.user=Math.max(EYE.user,G.until);EYE.blinkT=t+GREETK.blink;EYE.nextBlink=Math.max(EYE.nextBlink,t+GREETK.blink+1.2);
  if(LIFE.st==='rest'&&!SLP.on)LIFE.until=Math.max(LIFE.until,G.until+.1+.6*Math.random())}
function brainJit(){if(!(mat.greetLook>=.5)||!BRon())return;const B=BRAIN,r=Math.random;B.seed=(r()*4294967296)>>>0;B.z=.15+.3*r();B.q=.05+.65*r();B.e=.05+.65*r();B.s=.4*r()*IMP.tr}   // 打開（換隻、離開十分鐘回來）時四個需求的起點加亂數：開頭三件事不再每次一樣
// B2 睡著：40 秒沒人碰（點空白處也算碰）""")
s=rep(s,"  sleepStep(dt);echoStep(dt);   // v2.23 B2 睡著、C6 節奏","  sleepStep(dt);echoStep(dt);   // v2.23 B2 睡著、C6 節奏\n  greetStep();   // v2.61 C4")
s=rep(s,"function impBack(away){if(!(away>6e5))return;brainReset();","function impBack(away){if(!(away>6e5))return;brainReset();brainJit();")
s=rep(s,"else if(IMP.hiddenAt>0)impBack(performance.now()-IMP.hiddenAt)});","else{if(IMP.hiddenAt>0)impBack(performance.now()-IMP.hiddenAt);if(IMP.hiddenAt>0)greetArm(false)}});\naddEventListener('blur',()=>{GREET.blurT=performance.now()});addEventListener('focus',()=>{if(GREET.blurT>0&&!document.hidden){GREET.blurT=-9;greetArm(false)}});   // v2.61 C4：視窗切走再切回來（分頁沒藏起來）也看你")
# ---- C7 作息
s=rep(s,"homeAt:0,seed:20261114,hudAt:0,naps:0,selfWake:0};","homeAt:0,seed:20261114,hudAt:0,naps:0,selfWake:0,zAt:.5,jA:1,jS:1,slp:false};   // v2.61 C7（brJit）：zAt 睏到多少才想睡、jA 這一輪醒著睏得多快、jS 這一覺睡多快醒，每一輪重抽")
s=rep(s,"homeAt:t})}   // 每次打開、換一隻都從同一個起點：跟你離開多久無關","homeAt:t,zAt:.5,jA:1,jS:1,slp:false})}   // 每次打開、換一隻都從同一個起點：跟你離開多久無關")
s=rep(s,"  if(engaged)B.pre=null;\n  if(SLP.on){B.z-=dt/mat.brSleepT;B.e+=dt/90}   // 睡覺：睏退掉，力氣回來\n  else{B.z+=dt/mat.brAwakeT*pz*",
"""  if(engaged)B.pre=null;
  const jit=mat.brJit>=.5;
  if(!jit){B.zAt=.5;B.jA=B.jS=1;B.slp=SLP.on}
  else if(B.slp!==SLP.on){B.slp=SLP.on;if(SLP.on)B.jS=BRJ.s0+(BRJ.s1-BRJ.s0)*brnd()**2;else{B.jA=BRJ.a0*Math.pow(BRJ.a1/BRJ.a0,brnd());B.zAt=BRJ.z0+(BRJ.z1-BRJ.z0)*brnd();B.e*=BRJ.e0+(1-BRJ.e0)*brnd();B.q=Math.max(B.q,BRJ.q*brnd());LIFE.until=Math.max(LIFE.until,t+1.5+BRJ.lie*brnd()**2)}}   // v2.61 C7：每一輪的作息重抽；醒來想做什麼不一定（有時先張望、有時先賴一下）
  if(SLP.on){B.z-=dt/mat.brSleepT*B.jS;B.e+=dt/(jit?180:90)}   // 睡覺：睏退掉，力氣回來
  else{B.z+=dt/mat.brAwakeT*B.jA*pz*""")
s=rep(s,"const BR_Q=30,BR_E=90,","const BRJ={a0:.3,a1:2.6,s0:.45,s1:2.4,z0:.4,z1:.75,e0:.15,q:.9,lie:9};   // v2.61 C7：a 醒著睏得多快的倍數（越大越快睏）、s 睡著多快睡飽的倍數、z 睏到多少才睡、e 醒來想動至少留幾成、q 醒來好奇最多多少、lie 醒來最多賴幾秒\nconst BR_Q=30,BR_E=90,")
# ---- C7 自己撞到只晃不倒
s=rep(s,"const DB={x:null,y:null,n:0,ok:false,stat:{n:0,v:0}};",
"""// v2.61 C7（bumpSoft）：牠自己走路、探、睡著攤開碰到的（沒有手指在身上、最後一次碰牠 1.5 秒以前、不在空中、不是牠在推東西），只晃一下：角度最多 lean、位置最多挪 move 個半徑，碰完 hold 秒內都夾著。你抓著牠撞、甩過去、手指推的，照舊會倒
const SOFTB={lean:.16,move:.08,hold:1.6,k:.12,w:1.6};
function selfMove(){if(!(mat.bumpSoft>=.5)||SILL.air||SILL.hop||SILL.grab||t>=lastTouch&&t-lastTouch<1.5)return false;for(const f of fingers.values())if(f.mode==='grab'||f.mode==='stroke'||f.mode==='push'&&t-f.hitT<.5&&!f.lure)return false;return true}
function softHold(p){if(!drRecent(p.softT,SOFTB.hold)||p.held||p.tip||drRecent(p.fingT,1.2)||drRecent(p.catT,2))return;const w=Math.atan2(Math.sin(p.a),Math.cos(p.a)),m=R*SOFTB.move;
  if(Math.abs(w)>SOFTB.lean){p.a-=w-Math.sign(w)*SOFTB.lean;if(p.va*w>0)p.va=0}
  if(p.x>p.softX+m){p.x=p.softX+m;if(p.vx>0)p.vx=0}else if(p.x<p.softX-m){p.x=p.softX-m;if(p.vx<0)p.vx=0}}
const DB={x:null,y:null,n:0,ok:false,stat:{n:0,v:0}};""")
s=rep(s,"if(ok){const K=14*(mat.decoPush==null?1:mat.decoPush),vc=3000;","if(ok){const K=14*(mat.decoPush==null?1:mat.decoPush),vc=3000,self=selfMove();")
s=rep(s,"      if(!n)continue;const cov=","      if(!n)continue;const soft=self&&!p.tip;if(soft){if(!drRecent(p.softT,SOFTB.hold))p.softX=p.x;p.softT=t}else p.softT=null;const cov=")
s=rep(s,"      p.vx+=mx*k;if(my>0||sp>R*3)p.vy+=my*k*.5;p.va+=tq/n/(p.I/p.m)*k*.6;if(p.tc)p.va+=mx*k/p.base*.6;DB.stat.last",
"      if(soft){p.vx+=mx*k*SOFTB.k;if(p.tc)p.va=Math.max(-SOFTB.w,Math.min(SOFTB.w,p.va+mx*k/p.base*.6))}else{\n      p.vx+=mx*k;if(my>0||sp>R*3)p.vy+=my*k*.5;p.va+=tq/n/(p.I/p.m)*k*.6;if(p.tc)p.va+=mx*k/p.base*.6}DB.stat.last")
s=rep(s,"if(sp>R*2.2)propKnock(p,Math.min(1,sp/(R*9)));if(sp>DB.stat.v)","if(sp>R*2.2&&!(soft&&drRecent(p.softK,6))){if(soft)p.softK=t;propKnock(p,Math.min(1,sp/(R*9)))}if(sp>DB.stat.v)")
s=rep(s,"    p.tc=touch;if(p.deco&&!p.held&&touch>=2)","    softHold(p);p.tc=touch;if(p.deco&&!p.held&&touch>=2)")
# ---- C7 換隻記憶
s=rep(s,"function memSave(force){if(IMPSV.noSave||!BMEM.dirty)return;if(!force&&t-BMEM.at<3&&BMEM.at<=t)return;BMEM.at=t;BMEM.dirty=false;\n  try{localStorage.setItem('nienie.brain',JSON.stringify({id:SLIMES[SLIME].id,cell:BMEM.cell.map(v=>+v.toFixed(3)),side:+BMEM.side.toFixed(3),ts:Date.now()}))}catch(_){}}",
"""// v2.61 C7（未做 31）：每隻分開記。以前只有一份，換隻不重讀，A 的記性直接變成 B 的，3 秒後還寫到 B 名下、把 A 存的蓋掉；熟的牠換回來時，戒從 0 變回原本的值也被當成「剛剛在這格被嚇」。
// 現在換隻時先收起這隻的（memPut）、換成那隻的（memGet），存的時候十隻一起存（all）；外面那層 id、cell、side 留著，舊格式讀得懂
const BMEMS={};
function memPut(){BMEMS[SLIMES[SLIME].id]={cell:BMEM.cell.map(v=>+v.toFixed(3)),side:+BMEM.side.toFixed(3),ts:Date.now()}}
function memGet(){const m=BMEMS[SLIMES[SLIME].id],d=m?memDecay(m,Math.max(0,(Date.now()-m.ts)/864e5)):{cell:[0,0,0,0,0],side:0};BMEM.cell=d.cell.slice();BMEM.side=d.side;BMEM.offerAt=-99;BMEM.leans=0;BMEM.dirty=false}
function memSync(){Object.assign(BMEM.ev,{h:MOOD.happyT,w:IMP.w,sc:MOOD.scare});Object.assign(BRAIN.ev,{h:MOOD.happyT,j:ECHO.joyUntil,w:IMP.w,sc:MOOD.scare})}   // 換隻後戒、開心、被嚇換成那隻的，不算「剛剛發生」
function memSave(force){if(IMPSV.noSave||!BMEM.dirty)return;if(!force&&t-BMEM.at<3&&BMEM.at<=t)return;BMEM.at=t;BMEM.dirty=false;memPut();
  try{const m=BMEMS[SLIMES[SLIME].id];localStorage.setItem('nienie.brain',JSON.stringify({id:SLIMES[SLIME].id,cell:m.cell,side:m.side,ts:m.ts,all:BMEMS}))}catch(_){}}""")
s=rep(s,"function memLoad(){try{const o=JSON.parse(localStorage.getItem('nienie.brain')||'null');if(!o||!Array.isArray(o.cell)||o.cell.length!==5||o.id!==SLIMES[SLIME].id)return;\n    const d=memDecay({cell:o.cell.map(v=>isFinite(+v)?Math.max(-1,Math.min(1,+v)):0),side:isFinite(+o.side)?Math.max(-1,Math.min(1,+o.side)):0},Math.max(0,(Date.now()-(+o.ts||0))/864e5));\n    BMEM.cell=d.cell;BMEM.side=d.side}catch(_){}}",
"""function memLoad(){try{const o=JSON.parse(localStorage.getItem('nienie.brain')||'null');if(!o)return;
    const put=(id,m)=>{if(m&&Array.isArray(m.cell)&&m.cell.length===5&&SLIMES.some(q=>q.id===id))BMEMS[id]={cell:m.cell.map(v=>isFinite(+v)?Math.max(-1,Math.min(1,+v)):0),side:isFinite(+m.side)?Math.max(-1,Math.min(1,+m.side)):0,ts:+m.ts||0}};
    if(o.all)for(const id in o.all)put(id,o.all[id]);put(o.id,o);memGet()}catch(_){}}""")
s=rep(s,"function chooseSlime(i,intro,say){if(mat.imp>=.5)IMPS[SLIMES[SLIME].id]={tr:IMP.tr,w:IMP.w};\n","function chooseSlime(i,intro,say){if(mat.imp>=.5)IMPS[SLIMES[SLIME].id]={tr:IMP.tr,w:IMP.w};memSave(true);memPut();\n")
s=rep(s,"setup();fxReset();impReset();const o=IMPS[s.id];if(o){IMP.tr=o.tr;IMP.w=o.w}IMPD.tr=IMP.tr;IMPD.w=IMP.w;\n  syncSliders();if(intro)startIntro();",
"setup();fxReset();impReset();const o=IMPS[s.id];if(o){IMP.tr=o.tr;IMP.w=o.w}IMPD.tr=IMP.tr;IMPD.w=IMP.w;memGet();memSync();\n  syncSliders();if(intro){startIntro();SLP.openT=t;GREET.st='';brainJit();greetArm(true)}")
# ---- B1
s=rep(s,"    if(SFX)SFX.frame(dt,{rub:sfxRubLevel,stretch:stMax,grabbing})}","    if(SFX){SFX.snd61=mat.snd61>=.5?1:0;SFX.frame(dt,{rub:sfxRubLevel,stretch:stMax,grabbing})}}")
s=rep(s,"     其他十個（rough tapSoft petSlow wakeSoft nearFast greetLook brJit bumpSoft eyeTrue snd61）登記在這裡，各自的行為另外接。",
"     其他十個（rough tapSoft petSlow wakeSoft nearFast greetLook brJit bumpSoft eyeTrue snd61）各自的行為寫在 ROUGH、TAPK、PETK、WAKEK、lifeStep 的 hear、GREET、BRJ、SOFTB、eyeStep、sfx/engine.js。換隻的地方記性每隻分開（BMEMS，沒有開關）。")
save('index.html',s)
e=load('sfx/engine.js')
e=rep(e,"amb: 'rain', ambMeta: null,","snd61: 1,   // v2.61 B1：揉的新循環（rub.loop61）和抓著時雨降到 0.3；0 回 rub.loop、0.6\n    amb: 'rain', ambMeta: null,")
e=rep(e,"grabbing ? S.bgmDuck : 1","grabbing ? (S.snd61 && S.amb === 'rain' ? 0.3 : S.bgmDuck) : 1")
e=rep(e,"S.rubV = loopVoice('rub.loop');","S.rubV = loopVoice(S.snd61 && S.buf['rub.loop61'] && S.buf['rub.loop61'].length ? 'rub.loop61' : 'rub.loop');")
save('sfx/engine.js',e)
d=load('desk.js');d=rep(d,"const FEELVER='v2.54';","const FEELVER='v2.61';");save('desk.js',d)
print('ok')
