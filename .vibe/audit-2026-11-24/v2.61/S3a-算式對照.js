// S3a 對照（D1 rough、D2 tapSoft、C3 petSlow）：把 SlimeRig.swift 的原文機械轉成 JS，跟 index.html 的原文吃同一串假手，每一格比狀態。
// 另外把動工前的 SlimeRig.swift（git show ca6f880）也轉一份，三個參數都 0 時跟現在的比（狀態、亂數取用次數、出聲）。
// 重跑：在工作樹根目錄 node .vibe/audit-2026-11-24/v2.61/S3a-算式對照.js
// 這只證明算式一樣，不證明 Swift 編得過。
const fs=require('fs'),cp=require('child_process'),path=require('path');
const ROOT=path.resolve(__dirname,'../../..')+'/';
const rd=s=>s.replace(/\r/g,'');
const swNew=rd(fs.readFileSync(ROOT+'ios/NieNie/Slime/SlimeRig.swift','utf8'));
const swOld=rd(cp.execFileSync('git',['show','ca6f880:ios/NieNie/Slime/SlimeRig.swift'],{cwd:ROOT,maxBuffer:1<<26}).toString('utf8'));
// 網頁固定拿 W2 提交的那版（W3 同時在改 index.html）；加 --live 改讀工作樹
const gitShow=f=>rd(cp.execFileSync('git',['show','ca6f880:'+f],{cwd:ROOT,maxBuffer:1<<26}).toString('utf8'));
const web=process.argv.includes('--live')?rd(fs.readFileSync(ROOT+'prototype/web/index.html','utf8')):gitShow('prototype/web/index.html');

// ---------- Swift → JS
const strip=x=>x.split('\n').map(l=>l.replace(/\s*\/\/.*$/,'')).join('\n');
// 條件最外層的逗號換成 &&
function cond(c){let d=0,o='';for(const ch of c){if('(['.includes(ch))d++;if(')]'.includes(ch))d--;o+=ch===','&&d===0?' && ':ch}
  return o.replace(/\blet (\w+)\b/g,'$1')}
function ifs(x){let o='',i=0;for(;;){const m=/(^|[^\w$.])(if|guard) /.exec(x.slice(i));if(!m){o+=x.slice(i);break}
  const a=i+m.index+m[1].length,s=a+m[2].length+1;o+=x.slice(i,a);let d=0,j=s;for(;;j++){const c=x[j];if('(['.includes(c))d++;if(')]'.includes(c))d--;if(d===0&&m[2]==='if'&&c==='{')break;if(d===0&&m[2]==='guard'&&x.startsWith(' else {',j))break}
  if(m[2]==='if'){o+='if('+cond(x.slice(s,j).trim())+')';i=j}
  else{const c=x.slice(s,j).trim(),g=/^let (\w+) = (.+)$/.exec(c);o+=g?`const ${g[1]}=${g[2]};if(!${g[1]})`:'if(!('+cond(c)+'))';i=j+6}}
  return o}
function s2j(x){x=strip(x);
  x=x.replace(/func cl\(_ v: Double\) -> Double \{ (.+?) \}\n/g,'const cl=v=>$1\n');
  x=x.replace(/\.filter \{ t - \$0 < 1 \}/g,'.filter(x=>t-x<1)').replace(/taps\.append\(/g,'taps.push(').replace(/(taps|HRX|\))\.count\b/g,'$1.length')
   .replace(/fingers\.count\b/g,'fingers.size').replace(/!fingers\.isEmpty/g,'(fingers.size>0)').replace(/fingers\.isEmpty/g,'(!fingers.size)').replace(/clusters\.isEmpty/g,'(!clusters.length)').replace(/clusters\.indices\.contains\(gi\)/g,'(gi<clusters.length)')
   .replace(/Double\.random\(in: 0\.\.<(\([^)]*\)|[\w.]+), using: &rng\)/g,'(rnd()*($1))')
   .replace(/Finger\.PetPath\(cx: (.+), cy: (.+), sx: (\w+), sy: (\w+), px: (\w+), py: (\w+)\)/g,'{cx:$1,cy:$2,sx:$3,sy:$4,px:$5,py:$6,ml:0,run:0,sum:0,out:false}')
   .replace(/([\s(])\.(grab|stroke|push|none|rest|go|look)\b/g,"$1'$2'").replace(/LifeState\.(\w+)/g,"'$1'")
   .replace(/\b(let|var) (\w+): Finger\?/g,'let $2').replace(/((?:let|var) |, )(\w+): (?:Double|Bool|Int|Finger\.PetPath)(?= =)/g,'$1$2').replace(/\bvar\b/g,'let')
   .replace(/for (\w+) in fingers\.values where (.+?) \{/g,'for(const $1 of fingers.values())if($2) {').replace(/for (\w+) in fingers\.values \{/g,'for(const $1 of fingers.values()) {')
   .replace(/([\w$])!(?=[.)])/g,'$1').replace(/\bnil\b/g,'null').replace(/2 \* \.pi/g,'2 * Math.PI');
  // if 的改寫要在 for…where 之後，for 那個 if 已經有括號、後面是 if( 不是「if 空格」
  x=ifs(x);
  return x.replace(/(^|[^\w.$])(hypot|exp|pow|atan2|max|min|cos|sin|tanh|sqrt)\(/g,'$1Math.$2(').replace(/(^|[^\w.$])(hypot|exp|pow|atan2|max|min|cos|sin|tanh|sqrt)\(/g,'$1Math.$2(').replace(/Math\.pow\(1 - p, 3\)/g,'(1 - p) ** 3').replace(/Math\.pow\(1 - p, 2\)/g,'(1 - p) ** 2')}
const cut=(s,a,b,inc)=>{const i=s.indexOf(a);if(i<0||s.indexOf(a,i+1)>=0)throw Error('標記 '+(i<0?'沒有':'不唯一')+'：'+a);const j=s.indexOf(b,i+a.length);if(j<0)throw Error('尾：'+b);return s.slice(i,j+(inc?b.length:0))};
function swFn(src,name,args){const head='    private func '+name+'(';const i=src.indexOf(head);if(i<0)return null;const nl=src.indexOf('\n',i),line=strip(src.slice(i,nl));
  let body;if(/\}\s*$/.test(line)&&line.includes('{'))body=line.slice(line.indexOf('{')+1,line.lastIndexOf('}'));else{const e=src.indexOf('\n    }\n',i);body=src.slice(src.indexOf('{',i)+1,e)}
  return 'function '+name+'('+args+'){'+s2j(body)+'\n}\n'}
// 常數
const enums={};for(const n of ['RoughSet','TapSet','PetSet'])if(swNew.includes('private enum '+n)){const b=/private enum \w+ \{/.test(swNew)?cut(swNew,'private enum '+n+' {',n==='PetSet'?'\n    }':'}\n'):'';enums[n]={};for(const m of strip(b).matchAll(/(\w+): Double = ([\d.]+)/g))enums[n][m[1]]=+m[2]}
console.log('Swift 常數',JSON.stringify(enums));

function build(src){const has=n=>src.includes('private func '+n+'(');
  let js='';for(const [n,a] of [['tapCap','a'],['petReset',''],['petStep','dt'],['moodStep','dt'],['moodRelease','f'],['flee','dx,dy,dist'],['moodColorStep','dt'],['impRelease','f'],['impStep','dt'],['e1Step','']])if(has(n)){let b=swFn(src,n,a);js+=b}
  // update() 裡抓著那一段、落指那一行、縮、> <、摸轉抓
  js+='function upd(f,ex,ey,st){'+s2j(cut(src,'                f.stretch = st; f.ex = ex; f.ey = ey','                if step > f.step'))+'}\n';
  const fl=strip(src.split('\n').filter(l=>l.startsWith('        if grab && lv(params.lifeFlinch)')).join('')),flb=fl.slice(fl.indexOf('{ ')+1,fl.lastIndexOf('}'));
  js+='function down(){if(lv(params.lifeFlinch)&&!(flAt>t)){'+s2j(flb)+'}}\n';
  const lf=cut(src,'        flH += (1 - flH) * (1 - exp(-dt / 7))','        do {   // 60 ms in');
  js+='function flinch(dt){'+s2j(lf)+'\n}\n';
  const ey=src.split('\n').filter(l=>l.includes('{ eyeSqU = t + 0.45 }'));if(ey.length!==1)throw Error('eye');js+='function eyeY(g){'+s2j(ey[0])+'}\n';
  const sg=cut(src,'        f.stretch = 0; f.ex = 0; f.ey = 0; f.sb = 0; f.step = 0;','        f.tGrab = t');js+='function strokeGrabReset(f){'+s2j(sg)+'}\n';
  js+='function setupReset(){'+s2j(cut(src,'        moodC = 0; moodA = 0; moodStrain = 0;','        dentList.removeAll()').replace(/taps = \[\]/,'taps.length = 0'))+'}\n';
  return js}

// ---------- 網頁原文
const wl=web.split('\n'),one=p=>{const r=wl.filter(l=>l.startsWith(p));if(r.length!==1)throw Error(r.length+' 行 '+p);return r[0]};
const fnText=(name)=>{const i=wl.findIndex(l=>l.startsWith('function '+name+'('));if(i<0)throw Error(name);let j=i+1;while(!/^(function|const|let|\/\/|\/\*|\S)/.test(wl[j]))j++;return wl.slice(i,j).join('\n')};
let wj=[one('const ROUGH='),one('const TAPK='),one('const SB=f=>')].map(l=>l.replace(/^const SB/,'const SB')).join('\n')+'\n';
wj+=one('const PETK=').replace(/,PET=\{.*$/,';')+'\n'+'const petReset=()=>Object.assign(PET,{g:0,last:-9,on:false,said:false});\n';
wj=wj.replace(/const LV=.*/,'');
for(const n of ['tapCap','petStep','moodStep','moodRelease','flee','moodColorStep','impRelease','impStep','e1Step'])wj+=fnText(n)+'\n';
{const a=wl.filter(l=>l.startsWith('      if(roughOn()){const hv='));if(a.length!==1)throw Error('hv');wj+='function upd(f,ex,ey,st){f.ex=ex;f.ey=ey;f.stretch=st;'+a[0].replace(/\/\/.*$/,'')+'}\n';
 const d=wl.filter(l=>/^  if\(grab&&LV\('lifeFlinch'\)&&!\(FLN\.at>t\)(&&!SLP\.on)?\)\{FLN\.at=/.test(l));if(d.length!==1)throw Error('down');wj+='function down(){const grab=true;'+d[0].replace(/\/\/.*$/,'')+'}\n';
 const i=wl.findIndex(l=>l.startsWith('  FLN.H+=(1-FLN.H)')),j=wl.findIndex((l,k)=>k>i&&l.startsWith('  {const u=t-FLN.t0'));wj+='function flinch(dt){'+wl.slice(i,j).join('\n')+'\n}\n';
 const e=wl.filter(l=>l.startsWith('  if(g&&g.peak/R>5&&SB(g)>.8'));if(e.length!==1)throw Error('eye');wj+='function eyeY(g){'+e[0].replace(/\/\/.*$/,'')+'}\n';
 const sg=one('function strokeGrab(f)');wj+='function strokeGrabReset(f){'+sg.slice(sg.indexOf('f.stretch=0;'),sg.indexOf('f.r0x='))+'}\n';
 wj+='function setupReset(){Object.assign(MOOD,{c:0,a:0,strain:0,strainMax:0,scare:0,cowerUntil:-9,happyT:-9,wagT:-9,tugX:0,tugY:0,tugS:0});MOOD.taps.length=0;ESC.on=false;PURR=0;petReset();Object.assign(FLN,{at:-9,t0:-9,amp:0,H:1,s:1,last:0,tc:1,tcq:false,tpAt:-9})}\n'}
// 網頁 setup 裡真的有這幾項（上面那行是手抄的，這裡查原文）
{const s=wl.slice(955,970).join('\n');for(const k of ['petReset()','tc:1,tcq:false,tpAt:-9'])if(!s.includes(k))throw Error('setup 沒有 '+k)}
wj=wj.replace(/Math\.random\(/g,'rnd(');

const RNG=seed=>{let s=seed>>>0,n=0;const f=()=>{n++;s=(s*1664525+1013904223)>>>0;return s/4294967296};f.n=()=>n;return f};
const mk=(code,S,names)=>new Function('S','with(S){'+code+';return{'+names.join(',')+'}}')(S);
const NAMES=['petStep','moodStep','moodRelease','moodColorStep','impRelease','impStep','e1Step','upd','down','flinch','eyeY','strokeGrabReset','setupReset','petReset'];

const R=108,W=390;   // 108 點：一個 R 剛好是網頁的 1.8 公分，也是手機的 60 點一公分
const PAR=(o)=>Object.assign({emo:1,imp:1,life2:1,e1:1,e3:1,impC3:1,impC4:1,impC5:1,lifeFlinch:1,lifeBreath:1,lifeGait:1,rubSpeed:12,flee:1,flinchAmp:.09,moodColor:1,wRate:1,trRate:1,wFade:1,pullSoft:0,pullHold:0,pullWhole:0,rough:1,tapSoft:1,petSlow:1,tickRev:6},o);
function swSide(code,par,seed){const rnd=RNG(seed),log=[];const S={params:par,R,W,H:844,camZ:1,gi:0,clusters:[{xc:200,yc:400}],fingers:new Map(),t:0,rnd,
  moodC:0,moodA:0,moodStrain:0,moodStrainMax:0,moodScare:0,cowerUntil:-9,happyT:-9,wagT:-9,taps:[],pullDX:1,pullDY:0,tugX:0,tugY:0,purr:0,moodTugS:0,petG:0,petLast:-9,petOn:false,petSaid:false,
  flAt:-9,flT0:-9,flAmp:0,flH:1,flS:1,flPre:'rest',flTc:1,flTapQ:false,flTapAt:-9,flBoost:1,escOn:false,escT0:0,escT:1,escSX:0,escSY:0,escDX:0,escDY:0,homeX:200,homeY:400,wanderVX:0,wanderVY:0,wanderMoving:false,wanderNext:0,strK:1,strH:0,exert:0,lifeSt:'rest',lifeUntil:-1,
  impTrust:.3,impWary:.2,impLX:0,impLY:0,impHas:false,impShownTrust:0,impShownWary:0,mcC:0,mcS:0,mcW:0,mcZ:0,slpK:0,slpOn:false,stkG:0,stkLast:-9,stkSaid:false,dragOX:0,dragOY:0,eyeSqU:-9,nuzSaid:false,reduceMotion:false,HRC:[1],HRX:[],memL:1,tickFake:false,
  ...enums,PullSet:{noFlee:1.35},get roughOn(){return par.rough>=.5},get tickOn(){return S.tickFake},
  lv:v=>par.life2>=.5&&v>=.5,iv2:v=>par.imp>=.5&&par.life2>=.5&&v>=.5,iv3:v=>par.life2>=.5&&v>=.5,exLevel:()=>.3,memLen:()=>S.memL,bodyStretch:f=>f.sb>=0?f.sb:f.stretch,hop:()=>log.push('hop'),voice:(k)=>log.push(k),cutSniffs(){},firstGrab(){for(const f of S.fingers.values())if(f.mode==='grab')return f;return null},onEvent(){}};
  S.HRC.length=1;const F=mk(code,S,NAMES.filter(n=>n!=='petReset'&&n!=='petStep'||code.includes('function '+n)));
  return{S,F,log,rnd,newF:(x,y,mode,t)=>({mode,x,y,rawX:x,rawY:y,ax:x,ay:y,fx:x,fy:y,ex:0,ey:0,sb:-1,stretch:0,vxS:0,vyS:0,peak:0,tDown:t,gentleT:0,strainT:0,tugT:0,vMax:0,yank:false,pt:null,on:false,dragMax:0,saidProt:false,saidPurr:false}),
   snap(){const a={c:S.moodC,a:S.moodA,strain:S.moodStrain,sMax:S.moodStrainMax,scare:S.moodScare,cow:S.cowerUntil,hap:S.happyT,tugX:S.tugX,tugY:S.tugY,purr:S.purr,tugS:S.moodTugS,g:S.petG,on:+S.petOn,said:+S.petSaid,fAt:S.flAt,fAmp:S.flAmp,fH:S.flH,tc:S.flTc,tcq:+S.flTapQ,esc:+S.escOn,hx:S.homeX,hy:S.homeY,tr:S.impTrust,w:S.impWary,mcS:S.mcS,mcC:S.mcC,mcW:S.mcW,sq:S.eyeSqU,nt:S.taps.length,rn:rnd.n(),lg:log.length};return a},
   set(o){S.t=o.t;S.clusters[0].xc=o.gx;S.clusters[0].yc=o.gy;S.camZ=o.z;S.stkG=o.stkG;S.stkLast=o.stkLast;if(o.stkG<.5)S.stkSaid=false;S.dragOX=o.dox;S.dragOY=o.doy;S.tickFake=o.tick;S.memL=o.memL;S.lifeSt=o.ls},wake(){}}}
function webSide(par,seed){const rnd=RNG(seed),log=[];const S={mat:par,R,W,H:844,CAM:{z:1},globalC:{xc:200,yc:400},fingers:new Map(),t:0,rnd,MOOD:{c:0,a:0,strain:0,strainMax:0,scare:0,cowerUntil:-9,happyT:-9,wagT:-9,taps:[],px:1,py:0,tugX:0,tugY:0},ESC:{on:false,t0:0,T:1,sx:0,sy:0,dx:0,dy:0},PURR:0,PET:{g:0,last:-9,on:false,said:false},
  FLN:{at:-9,t0:-9,amp:0,H:1,s:1,last:0,tc:1,tcq:false,tpAt:-9,boost:1},HOMEX:200,HOMEY:400,WANDER:{vx:0,vy:0,moving:false,next:0},STR:{k:1,h:0},BRX:{exert:0},LIFE:{st:'rest',until:-1},IMP:{tr:.3,w:.2,lx:0,ly:0,has:false,askUntil:-9},IMPD:{tr:0,w:0},MC:{c:0,s:0,w:0,z:0},SLP:{k:0,on:false},STK:{g:0,last:-9,said:false},DRAG:{ox:0,oy:0},EYE:{sqU:-9},E2:{nuzSaid:false},REDUCED:false,HRC:[1],HRX:[],memL:1,tickFake:false,PULLSOFT:{noFlee:1.35},
  roughOn:()=>par.rough>=.5,tickOn:()=>S.tickFake,LV:k=>par.life2>=.5&&par[k]>=.5,IV2:k=>par.imp>=.5&&par.life2>=.5&&par[k]>=.5,IV3:k=>par.life2>=.5&&par[k]>=.5,exLevel:()=>.3,memLen:()=>S.memL,hop:()=>log.push('hop'),voice:k=>log.push(k),cutSniffs(){},brainFlinch:()=>1,BRM:()=>0,memTouch(){}};
  const F=mk(wj,S,NAMES);
  return{S,F,log,rnd,newF:(x,y,mode,t)=>({mode,x,y,ax:x,ay:y,fx:x,fy:y,ex:0,ey:0,sb:null,stretch:0,vxS:0,vyS:0,peak:0,tDown:t,gentleT:0,strainT:0,on:false}),
   snap(){const M=S.MOOD,F=S.FLN;return{c:M.c,a:M.a,strain:M.strain,sMax:M.strainMax,scare:M.scare,cow:M.cowerUntil,hap:M.happyT,tugX:M.tugX,tugY:M.tugY,purr:S.PURR,tugS:par.rough>=.5?M.tugS||0:0,g:S.PET.g,on:+S.PET.on,said:+S.PET.said,fAt:F.at,fAmp:F.amp,fH:F.H,tc:F.tc,tcq:+F.tcq,esc:+S.ESC.on,hx:S.HOMEX,hy:S.HOMEY,tr:S.IMP.tr,w:S.IMP.w,mcS:S.MC.s,mcC:S.MC.c,mcW:S.MC.w,sq:S.EYE.sqU,nt:M.taps.length,rn:rnd.n(),lg:log.length}},
   set(o){S.t=o.t;S.globalC.xc=o.gx;S.globalC.yc=o.gy;S.CAM.z=o.z;S.STK.g=o.stkG;S.STK.last=o.stkLast;if(o.stkG<.5)S.STK.said=false;S.DRAG.ox=o.dox;S.DRAG.oy=o.doy;S.tickFake=o.tick;S.memL=o.memL;S.LIFE.st=o.ls}}}

// ---------- 假手：同一串手勢餵每一邊
let sd=20261125;const rnd0=()=>{sd=(sd*1664525+1013904223)>>>0;return sd/4294967296},rr=(a,b)=>a+(b-a)*rnd0();
function script(){const ev=[];let T=.3;const n=3+(rnd0()*6|0);for(let k=0;k<n;k++){const kind=['slow','slow','pull','yank','tap','tap3','rub','two','hold','center','jit'][rnd0()*11|0],a=rr(0,6.283),r=kind==='center'?rr(0,.3):rr(.2,1.05);ev.push({kind,T,a,r,v:kind==='slow'?rr(.6,14):kind==='pull'||kind==='center'?rr(1,9):0,amp:rr(.25,.75),len:rr(.5,4.5),dur:kind==='tap'?rr(.04,.22):kind==='yank'?rr(.12,.6):rr(.8,5),fast:rr(4,14),stroke:rnd0()<.35,hold:rr(0,1.8)});
  T+=ev[k].dur+ev[k].hold+(kind.startsWith('tap')?rr(.05,1.6):rr(.1,1.5))+(kind==='tap3'?.9:0)}
  return{ev,T:T+1.5}}
function posAt(e,u){const cx=200,cy=400,ox=Math.cos(e.a),oy=Math.sin(e.a),sx=cx+ox*e.r*R,sy=cy+oy*e.r*R,cm=R/1.8;
  if(e.kind==='slow'||e.kind==='rub'){const v=(e.kind==='rub'?9:e.v)*cm,A=e.amp*R,per=2*A/Math.max(v,1e-6),q=(u/per)%2,s=q<1?q:2-q,tx=-oy,ty=ox;return[sx+tx*A*(2*s-1)-(-tx*0),sy+ty*A*(2*s-1)]}
  if(e.kind==='pull'||e.kind==='center'){const l=Math.min(e.len*R,u*e.v*cm);return[sx+ox*l,sy+oy*l]}
  if(e.kind==='yank'){const l=Math.min(e.len*R,u*e.fast*R);return[sx+ox*l,sy+oy*l]}
  if(e.kind==='jit')return[sx+Math.sin(u*9)*R*.5,sy+Math.cos(u*13)*R*.4];
  return[sx,sy]}
function run(sides,sc,swap){const dt=1/60,maxd={},cov={},dif={};let frames=0,t=0,stkG=0,stkLast=-9,live=[];const ps=sides.map(()=>null);
  const evs=sc.ev.flatMap(e=>e.kind==='tap3'?[0,.28,.55].map(d=>({...e,kind:'tap',T:e.T+d,dur:.1})):e.kind==='two'?[{...e,kind:'slow',v:3,dur:e.dur},{...e,kind:'hold',T:e.T+.3,r:.5,a:e.a+2,dur:e.dur*.5}]:[e]);
  const gone=new Set();
  while(t<sc.T){t+=dt;frames++;const z=1,gx=200+Math.sin(t*.7)*6,gy=400+Math.cos(t*.5)*5;
   const st={t,gx,gy,z,stkG,stkLast,dox:Math.sin(t*2)*R*.6,doy:0,tick:Math.sin(t*1.3)>.985,memL:1+.6*Math.abs(Math.sin(t*.9)),ls:['rest','go','look'][(t*.8|0)%3]};
   // 落指
   evs.forEach((e,k)=>{if(!gone.has(k)&&t>=e.T){gone.add(k);const[x,y]=posAt(e,0),o={e,k,t0:t,x,y,lx:x,ly:y,vxS:0,vyS:0,peak:0,mode:e.stroke&&e.kind==='slow'?'stroke':'grab',end:t+e.dur+(e.kind.startsWith('tap')?0:e.hold)};
     sides.forEach(s=>{s.set({...st,t:t-dt});if(o.mode==='grab'){s.F.down();s.S.ESC?s.S.ESC.on=false:s.S.escOn=false}const f=s.newF(x,y,o.mode,t-dt);f.on=o.mode==='stroke';s.S.fingers.set(k,f)});live.push(o)}});
   let anyStroke=false;
   sides.forEach(s=>s.set(st));
   for(const o of live){const u=t-o.t0,lim=o.e.kind==='tap'?u:Math.min(u,o.e.dur),[x,y]=posAt(o.e,lim),vx=(x-o.lx)/dt,vy=(y-o.ly)/dt,kv=1-Math.exp(-dt/.03);o.lx=x;o.ly=y;o.vxS+=(vx-o.vxS)*kv;o.vyS+=(vy-o.vyS)*kv;o.peak=Math.max(Math.hypot(vx,vy),o.peak*Math.exp(-dt/.08));
     let ex=x-o.x,ey=y-o.y;const el=Math.hypot(ex,ey),lm=7*R;if(el>0){const s=lm*Math.tanh(el/lm)/el;ex*=s;ey*=s}const sl=Math.hypot(ex,ey)/R;
     if(o.mode==='stroke'){anyStroke=true;stkLast=t;stkG=Math.min(3,stkG+2*dt);if(u>o.e.dur*.7&&!o.sw){o.sw=true;o.mode='grab';o.x=x;o.y=y;sides.forEach(s=>{const f=s.S.fingers.get(o.k);f.mode='grab';f.ax=x;f.ay=y;s.F.strokeGrabReset(f)})}}
     else if(o.e.kind==='slow'&&!o.sw2&&o.e.amp>.6&&u>o.e.dur*.5){o.sw2=true;o.mode='stroke';sides.forEach(s=>{const f=s.S.fingers.get(o.k);f.mode='stroke';f.on=true;f.stretch=0;f.ex=0;f.ey=0;f.sb=0})}
     sides.forEach(s=>{const f=s.S.fingers.get(o.k);f.x=x;f.y=y;f.rawX=x;f.rawY=y;f.fx=x;f.fy=y;f.vxS=o.vxS;f.vyS=o.vyS;f.peak=o.peak;if(o.mode==='grab'){s.F.upd(f,ex,ey,sl);f.sb=f.stretch;f.dragMax=Math.max(f.dragMax||0,el*.3)}})}
   if(!anyStroke)stkG=Math.max(0,stkG-.6*dt);
   if(swap&&swap(t,sides));
   sides.forEach(s=>{const F=s.F;F.moodStep(dt);F.moodColorStep(dt);F.impStep(dt);F.e1Step();F.flinch(dt);let g=null;for(const f of s.S.fingers.values())if(f.mode==='grab'){g=f;break}F.eyeY(g)});
   // 放手：release 的順序 impRelease → moodRelease
   for(const o of live.slice())if(t>=o.end){live.splice(live.indexOf(o),1);sides.forEach(s=>{const f=s.S.fingers.get(o.k);s.S.fingers.delete(o.k);if(f.mode==='grab'){s.F.impRelease(f);s.F.moodRelease(f)}})}
   const sn=sides.map(s=>s.snap());
   for(const q in sn[0]){for(let i=1;i<sn.length;i++){const d=Math.abs(sn[0][q]-sn[i][q]);if(!(d<=(dif[q]||0)))dif[q]=d}
     if(sn[0][q]!==0)cov[q]=(cov[q]||0)+1}
   if(sn[0].on)cov.petOn=(cov.petOn||0)+1;if(sn[0].sMax>.15)cov.strainMax=(cov.strainMax||0)+1;if(sn[0].tc<1)cov.capped=(cov.capped||0)+1;if(sn[0].esc)cov.flee=(cov.flee||0)+1;
   let yk=0;for(const f of sides[0].S.fingers.values())if(f.yank)yk=1;cov.yank=(cov.yank||0)+yk}
  if(sides[1].log.join()!==sides[0].log.join())dif.log=1;
  return{frames,dif,cov}}
let fail=0;
function batch(name,n,mkS,tol,swap){const D={},C={};let fr=0;for(let i=0;i<n;i++){const sc=script(),r=run(mkS(i),sc,swap);fr+=r.frames;for(const q in r.dif)D[q]=Math.max(D[q]||0,r.dif[q]);for(const q in r.cov)C[q]=(C[q]||0)+r.cov[q]}
  const worst=Object.entries(D).sort((a,b)=>b[1]-a[1])[0]||['-',0],ok=worst[1]<=tol;if(!ok)fail++;
  console.log((worst[1]===0?'一樣':ok?'一樣（捨入內）':'不同')+' | '+name+' | '+n+' 串 '+fr+' 格 | 最大差 '+worst[1]+'（'+worst[0]+'）| 走到：快扯 '+(C.yank||0)+'、逃 '+(C.flee||0)+'、拉扯過 0.15 '+(C.strainMax||0)+'、慢摸算數 '+(C.petOn||0)+'、縮的上限 '+(C.capped||0)+' 格')}
const N=build(swNew),O=build(swOld);
const ks=[[1,1,1],[1,0,0],[0,1,0],[0,0,1],[0,0,0]];
for(const[a,b,c]of ks)for(const ps of [0,1]){if(ps&&(a+b+c)!==3)continue;batch(`Swift 對網頁 rough ${a} tapSoft ${b} petSlow ${c} pullSoft ${ps}`,a+b+c===3?600:200,i=>{const p=()=>PAR({rough:a,tapSoft:b,petSlow:c,pullSoft:ps,wRate:1+(i%3)*.3,trRate:1-(i%2)*.4});return[swSide(N,p(),i+1),webSide(p(),i+1)]},1e-9)}
batch('三個都 0：現在的 Swift 對動工前的 Swift',600,i=>{const p=()=>PAR({rough:0,tapSoft:0,petSlow:0,pullSoft:i%2,wRate:1+(i%3)*.3});return[swSide(N,p(),i+1),swSide(O,p(),i+1)]},0);
// 半路切開關、半路重建：切成 0 之後不能留下狀態
{let bad=0;for(let i=0;i<300;i++){const par=PAR({}),s=swSide(N,par,i+1),s2=swSide(N,par,i+1),sc=script();let done=false;run([s,s2],sc,(t,ss)=>{if(!done&&t>sc.T*.55){done=true;par.rough=par.tapSoft=par.petSlow=0}return true});
   const S=s.S;if(S.moodTugS!==0||S.petG!==0||S.petOn||S.petSaid||S.petLast!==-9||S.flTc!==1||S.flTapQ)bad++;for(const f of S.fingers.values())if(f.mode==='grab'&&(f.vMax||f.yank||f.pt))bad++}
 console.log((bad?'不同':'一樣')+' | 半路三個切成 0：狀態都歸零 | 300 串 | 沒歸零 '+bad);if(bad)fail++}
{let bad=0;for(let i=0;i<100;i++){const s=swSide(N,PAR({}),i+1),s2=swSide(N,PAR({}),i+1);run([s,s2],script());s.F.setupReset();const S=s.S;if(S.moodTugS||S.petG||S.petOn||S.petSaid||S.petLast!==-9||S.flTc!==1||S.flTapQ||S.flTapAt!==-9)bad++}console.log((bad?'不同':'一樣')+' | setup 歸零 | 100 串 | 沒歸零 '+bad);if(bad)fail++}
console.log(fail?'有 '+fail+' 項不同':'全部一樣');
