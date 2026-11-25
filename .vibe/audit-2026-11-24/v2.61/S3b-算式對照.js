// S3b 對照（C1 wakeSoft、C2 nearFast、B4 eyeTrue）：SlimeRig.swift 的原文機械轉成 JS，跟 index.html 的原文吃同一串假手，每一格比狀態。
// 動工前的 SlimeRig.swift（df8a573，S3a 完成那版）也轉一份，三個參數都 0 時跟現在的比（狀態、亂數取用次數、出聲），要逐位元相同。
// 重跑：在工作樹根目錄 node .vibe/audit-2026-11-24/v2.61/S3b-算式對照.js（加 --live 改讀工作樹的網頁；DBG=1 印第一個不同的地方）。不加 --live 對的是 a2a3b57，那版網頁的 tapJudge 還沒改（v2.61 R），會有 2 項不同，是預期的
// 身體是照公式動的、走路是假的（gaitTo 之後等速走過去），不是物理。只證明算式一樣，不證明 Swift 編得過。
const fs=require('fs'),cp=require('child_process'),path=require('path');
const ROOT=path.resolve(__dirname,'../../..')+'/';
const rd=s=>s.replace(/\r/g,'');
const git=(c,f)=>rd(cp.execFileSync('git',['show',c+':'+f],{cwd:ROOT,maxBuffer:1<<26}).toString('utf8'));
const SW='ios/NieNie/Slime/SlimeRig.swift',HT='prototype/web/index.html';
const swNew=rd(fs.readFileSync(ROOT+SW,'utf8')),swOld=git('df8a573',SW);
const web=process.argv.includes('--live')?rd(fs.readFileSync(ROOT+HT,'utf8')):git('a2a3b57',HT);   // W3 提交的那版

// ---------- Swift → JS
const strip=x=>x.split('\n').map(l=>l.replace(/\s*\/\/.*$/,'')).join('\n');
const split=c=>{let d=0,o=[],s='';for(const ch of c){if('([{'.includes(ch))d++;if(')]}'.includes(ch))d--;if(ch===','&&d===0){o.push(s);s=''}else s+=ch}o.push(s);return o.map(q=>q.trim())};
const cond=c=>split(c).map(p=>{let m;if(m=/^let (\w+) = ([\s\S]+)$/.exec(p))return`((${m[1]}=${m[2]})!=null)`;if(m=/^let (\w+)$/.exec(p))return`(${m[1]}!=null)`;return'('+p+')'}).join('&&');
function ifs(x){let o='',i=0;for(;;){const m=/(^|[^\w$.])(if|guard) /.exec(x.slice(i));if(!m){o+=x.slice(i);break}
  const a=i+m.index+m[1].length,s=a+m[2].length+1;o+=x.slice(i,a);let d=0,j=s;
  for(;;j++){if(j>=x.length)throw Error('if 沒有尾：'+x.slice(a,a+80));const c=x[j];if(d===0&&m[2]==='if'&&c==='{')break;if(d===0&&m[2]==='guard'&&x.startsWith(' else {',j))break;if('(['.includes(c)||c==='{')d++;if(')]'.includes(c)||c==='}')d--}
  if(m[2]==='if'){o+='if('+cond(x.slice(s,j).trim())+')';i=j}else{o+='if(!('+cond(x.slice(s,j).trim())+'))';i=j+6}}
  return o}
function events(x){for(;;){const i=x.indexOf('onEvent?(');if(i<0)return x;let d=0,j=i+8;for(;;j++){if(x[j]==='(')d++;if(x[j]===')'&&--d===0)break}const a=x.slice(i+9,j),k=/kind: "(\w+)"/.exec(a),n=k?k[1]:/^\.(\w+)/.exec(a)[1];x=x.slice(0,i)+(n==='beat'?'0':`log.push("${n}")`)+x.slice(j+1)}}
const names=x=>[...new Set([...strip(x).matchAll(/(?:if|guard|,) let (\w+) = /g)].map(m=>m[1]))];
function s2j(x){const nm=names(x).filter(n=>n!=='k');x=events(strip(x));
  x=x.replace(/fingers\.values\.contains\(where: \{ (.+?) \}\)/g,'([...fingers.values()].some($$0=>($1)))').replace(/\.filter\(\{ (.+?) \}\)\.count/g,'.filter($$0=>($1)).length').replace(/iv\.allSatisfy\(\{ (.+?) \}\)/g,'iv.every($$0=>($1))')
   .replace(/zip\(iv, p\)\.allSatisfy \{ abs\(\$0 - \$1\) <= 0\.25 \* \$1 \+ 0\.04 \}/g,'iv.every((a,i)=>Math.abs(a-p[i])<=0.25*p[i]+0.04)').replace(/\(iv\.max\(\) \?\? 0\)/g,'(iv.length?Math.max(...iv):0)')
   .replace(/\(echoBeats\.last \?\? 0\)/g,'(echoBeats.length?echoBeats[echoBeats.length-1]:0)').replace(/echoBeats\.last!/g,'echoBeats[echoBeats.length-1]').replace(/echoTaps\.last\b/g,'echoTaps.at(-1)').replace(/sniffs\.last\b/g,'sniffs.at(-1)')
   .replace(/\.removeFirst\(\)/g,'.shift()').replace(/\.append\(/g,'.push(').replace(/iv\.isEmpty/g,'(!iv.length)').replace(/(\w+)\.count\b/g,'$1.length')
   .replace(/!fingers\.isEmpty/g,'(fingers.size>0)').replace(/fingers\.isEmpty/g,'(!fingers.size)').replace(/!clusters\.isEmpty/g,'(clusters.length>0)').replace(/clusters\.indices\.contains\(gi\)/g,'(gi<clusters.length)')
   .replace(/let fid = fingers\.first\(where: .+\)\?\.key/g,'let fid = f.id').replace(/if let k = sniffs\.firstIndex\(where: \{ \$0\.id == lureSn \}\) \{/g,'let k=sniffs.findIndex(q=>q.id==lureSn);if (k>=0) {')
   .replace(/Double\.random\(in: 0\.\.<([\d.]+), using: &rng\)/g,'(rnd()*$1)')
   .replace(/Finger\(x: x, y: y, mode: (.+?), time: t\)/g,'mkF(x,y,$1,t)').replace(/let f = mkF/g,'var f = mkF')
   .replace(/switch mode \{/g,'switch(mode){').replace(/case \.come:/g,"case 'come':").replace(/case \.(back|look):/g,"break;case '$1':").replace(/case 'look':\s*\n\s*break/,"case 'look':")
   .replace(/best\?\.edge = bd/g,'if(best) { best.edge = bd }').replace(/\bslow: /g,'').replace(/\bdash: /g,'')
   .replace(/([\s(])\.(grab|stroke|push|none|rest|go|look|sleep|come|back|arrive|route)\b/g,"$1'$2'")
   .replace(/\b(?:let|var) (\w+): (?:Finger|\(Double, Double\))\?/g,'let $1=null').replace(/((?:let|var) |, )(\w+): (?:Double|Bool|Int|LureMode|\[Double\])(?= =)/g,'$1$2').replace(/\bvar (?!f = mkF)/g,'let ')
   .replace(/for i in 1\.\.<max\(1, (.+?)\) \{/g,'for(let i=1;i<Math.max(1,$1);i++) {').replace(/for i in bnd \{/g,'for(const i of bnd) {').replace(/for i in 0\.\.<N where !GRAB\[i\] \{/g,'for(let i=0;i<N;i++)if(!GRAB[i]) {').replace(/for x in iv \{/g,'for(const x of iv) {')
   .replace(/for f in fingers\.values where (.+?) \{/g,'for(const f of fingers.values())if($1) {').replace(/while (.+?) \{/g,'while($1) {')
   .replace(/o = \((0, 0)\)/g,'o = [0,0]').replace(/o = \(cos\((\S+)\), sin\((\S+)\)\)/g,'o = [cos($1),sin($2)]')
   .replace(/([\w$])!(?=[.)])/g,'$1').replace(/\bnil\b/g,'null').replace(/([\s(])\.pi\b/g,'$1Math.PI');
  x=ifs(x);
  x=x.replace(/(^|[^\w.$])(hypot|exp|pow|atan2|max|min|cos|sin|abs)\(/g,'$1Math.$2(').replace(/(^|[^\w.$])(hypot|exp|pow|atan2|max|min|cos|sin|abs)\(/g,'$1Math.$2(');
  return(nm.length?'var '+nm.join(',')+';':'')+x}
const cut=(s,a,b)=>{const i=s.indexOf(a);if(i<0||s.indexOf(a,i+1)>=0)throw Error('標記 '+(i<0?'沒有':'不唯一')+'：'+a);const j=s.indexOf(b,i+a.length);if(j<0)throw Error('尾：'+b);return s.slice(i,j)};
function swFn(src,name,args){const i=src.indexOf('    private func '+name+'(');if(i<0)return'';const nl=src.indexOf('\n',i),line=strip(src.slice(i,nl));
  let body;if(/\}\s*$/.test(line)&&line.includes('{'))body=line.slice(line.indexOf('{')+1,line.lastIndexOf('}'));else{const e=src.indexOf('\n    }\n',i);body=src.slice(src.indexOf('{',i)+1,e)}
  if(name==='moveHome')body=body.replace('let dx = sillOn && sillTanV ? 0 : dx, dy = sillOn && !sillTanV ? 0 : dy','dx = sillOn && sillTanV ? 0 : dx; dy = sillOn && !sillTanV ? 0 : dy');
  return'function '+name+'('+args+'){'+s2j(body)+'\n}\n'}
const lineOf=(src,p)=>{const r=src.split('\n').filter(l=>l.startsWith(p));if(r.length!==1)throw Error(r.length+' 行 '+p);return r[0]};
const WakeSet={};for(const m of strip(cut(swNew,'private enum WakeSet {','\n    }')).matchAll(/(\w+): (?:Double|Int) = ([\d.]+)/g))WakeSet[m[1]]=+m[2];
for(const m of strip(cut(swNew,'private enum WakeSet {','\n    }')).matchAll(/, (\w+) = ([\d.]+)/g))WakeSet[m[1]]=+m[2];
console.log('Swift 常數',JSON.stringify(WakeSet));
function build(src){let js='';
  for(const[n,a]of[['softTouch','f'],['tapJudge',''],['rollStep','dt'],['softDrop',''],['wake','sharp,slow=false'],['sleepStep','dt'],['sleepTry',''],['moveHome','dx,dy,dt'],['echoTap','x,y'],['echoBeat','i'],['echoStep','dt'],['lureFinger',''],['lureEnd',''],['lureStep','dt'],['lifeRelease','f'],['impAsk','f'],['e2Release','f']])js+=swFn(src,n,a);
  if(src.includes('private var idleSec'))js+='function idleSec(){'+s2j(cut(src,'    private var idleSec: Double {\n','\n    }').replace('    private var idleSec: Double {',''))+'}\n';
  js=js.replace(/idleSec >=/g,'idleSec() >=');
  js+='function downSeg(x,y,grab,allowed){'+s2j(cut(src,'        if grab { escOn = false }','        let lure = !grab'))+";return typeof f!=='undefined'?f:mkF(x,y,grab?'grab':'push',t)}\n";
  js+='function seg(dt,free){'+s2j(cut(src,'        if !free { return }\n','        let e4 = '))+'\nreturn lured?2:1}\n';
  js+='function eyeSeg(g,pf,tow){'+s2j(cut(src,'        var o: (Double, Double)?\n','        if o == nil {'))+'\nreturn o}\n';
  js+='function wideSeg(){let wide=1;'+s2j(lineOf(src,'        if impWary > 0.5 || moodScare > 0.3 ||'))+'\nreturn wide}\n';
  js+='function happySeg(f){'+s2j(lineOf(src,'        if f.gentleT > 1 && moodC > 0.35 && fingers.isEmpty'))+'}\n';
  const sl=src.split('\n').filter(l=>l.startsWith('        eyeSetup(); slpOn = false;')||l.startsWith('        slpOpenT = t; slpSlow = false;'));
  js+='function setupReset(){t=0;'+s2j(sl.join('\n').replace('eyeSetup();',''))+'}\n';return js}

// ---------- 網頁原文
const wl=web.split('\n'),one=p=>{const r=wl.filter(l=>l.startsWith(p));if(r.length!==1)throw Error(r.length+' 行 '+p);return r[0]};
const fnText=n=>{const i=wl.findIndex(l=>l.startsWith('function '+n+'('));if(i<0)throw Error(n);let j=i+1;while(!/^\S/.test(wl[j]))j++;return wl.slice(i,j).join('\n')};
const seg=(a,b)=>{const i=wl.findIndex(l=>l.startsWith(a)),j=wl.findIndex((l,k)=>k>i&&l.startsWith(b));if(i<0||j<0)throw Error(a);return wl.slice(i,j).join('\n')};
let wj=one('const WAKEK=')+'\n'+one('const idleSec=')+'\n';
for(const n of['softTouch','tapJudge','rollStep','wake','sleepStep','sleepTry','moveHome','echoTap','echoBeat','echoStep','lureFinger','lureEnd','lureStep','lifeRelease','impAsk','e2Release'])wj+=fnText(n)+'\n';
wj+='function downSeg(x,y,grab){const p={x,y},f=mkF(x,y,grab?"grab":"push",t);\n'+[one("  if(grab){SWIM.on=false;"),one("  if(!grab){if(SLP.on){let db"),one("  if(grab&&LV('lifeFlinch')&&!(FLN.at>t)"),one('  if(grab&&mat.life2>=.5){cutSniffs()')].join('\n')+'\nreturn f}\n';
wj+='function seg(dt,free){'+seg('  if(!free)return;','  const e4=!lured')+'\nreturn lured?2:1}\n';
wj+='function eyeSeg(g,pf,tow){'+(()=>{const a=wl.findIndex(l=>l.startsWith("  if(g||pf){const q=g||pf")),b=wl.findIndex((l,k)=>k>a&&l.startsWith('  if(!o){if(t>=EYE.sacT)'));if(a<0||wl[a-1]!=='  let o=null;')throw Error('eye');return wl.slice(a-1,b).join('\n')})()+'\nreturn o}\n';
wj+='function wideSeg(){let wide=1;'+one('  if(IMP.w>.5||MOOD.scare>.3||t-SLP.wakeT')+'\nreturn wide}\n';
wj+='function happySeg(f){'+one('  if((f.gentleT||0)>1&&MOOD.c>.35&&!fingers.size&&!SLP.on)').replace(/\}\s*$/,'')+'}\n';
{const m=/Object\.assign\(SLP,\{[^}]*\}\);Object\.assign\(ECHO/.exec(web);wj+='function setupReset(){'+m[0].replace(/;Object\.assign\(ECHO$/,'')+'}\n'}
wj=wj.replace(/Math\.random\(/g,'rnd(');
const mk=(code,S,n)=>new Function('S','with(S){'+code+';return{'+n.join(',')+'}}')(S);
const NAMES=['wake','sleepStep','sleepTry','moveHome','echoStep','downSeg','seg','eyeSeg','wideSeg','happySeg','lifeRelease','impAsk','e2Release','setupReset'];
const RNG=s0=>{let s=s0>>>0,n=0;const f=()=>{n++;s=(s*1664525+1013904223)>>>0;return s/4294967296};f.n=()=>n;return f};
const R=108,NB=32,CX=200,CY=400;
const PAR=o=>Object.assign({emo:1,imp:1,life2:1,e1:1,e2:1,e3:1,impC1:1,impC2:1,impC4:1,impC5:1,lifeFlinch:1,lifeBreath:1,lifeGait:1,lifeAttend:1,sleep:1,echo:1,sleepAfter:3,podLen:.8,trRate:1,voicePitch:1,wakeSoft:1,nearFast:1,eyeTrue:1},o);
const pts=()=>{const X=[],Y=[];for(let i=0;i<NB;i++){X.push(CX+R*Math.cos(i/NB*6.2832));Y.push(CY+R*Math.sin(i/NB*6.2832))}return[X,Y]};
function common(S,par,rnd,log){const[X,Y]=pts();return Object.assign(S,{R,N:NB,X,Y,PX:X.slice(),PY:Y.slice(),GRAB:new Array(NB).fill(false),bnd:X.map((_,i)=>i),fingers:new Map(),t:0,rnd,log,iv2:v=>par.imp>=.5&&par.life2>=.5&&v>=.5,
  mkF:(x,y,mode,t)=>({id:0,mode,x,y,rawX:x,rawY:y,ax:x,ay:y,fx:x,fy:y,vxS:0,vyS:0,peak:0,hitT:-9,tDown:t,gentleT:0,stretch:0,sb:S.isWeb?null:-1,lure:false,yank:false,edge:0}),
  voice:k=>log.push(k),hop:()=>log.push('hop'),restDur:()=>3+rnd(),lastTouch:-10})}
function swSide(code,par,seed){const rnd=RNG(seed),log=[],S={isWeb:false};let sid=0;
  common(S,par,rnd,log);Object.assign(S,{params:par,camZ:1,gi:0,clusters:[{xc:CX,yc:CY}],slpOn:false,slpK:0,slpLastAny:-99,slpWakeT:-9,slpAskAt:-9,slpNearT:0,slpSnoreAt:0,flBoost:1,slpOpenT:-99,slpSlow:false,slpTap:null,slpTapN:0,slpTapT0:-9,slpTapDone:false,slpRollT:-9,slpRollD:1,slpRollO:0,
   taps:[],moodC:.1,moodScare:0,cowerUntil:-9,happyT:-9,wagT:-9,impTrust:.5,impWary:0,impAskUntil:-9,flAt:-9,flT0:-9,flAmp:0,flPre:'rest',flTapAt:-9,lifeSt:'rest',lifeUntil:-1,lifeLooks:0,eyeBlinkT:-9,eyeUser:-9,eyePulse:-9,voiceLast:-9,swimOn:false,e4On:false,snwCloud:0,escOn:false,introOn:false,escDX:0,escDY:0,
   gaitOn:false,gaitK:1,gaitTX:0,gaitTY:0,gaitH:0,wanderMoving:false,wanderX:0,wanderY:0,wanderVX:0,wanderVY:0,homeX:CX,homeY:CY,sillOn:false,sillTanV:false,sniffs:[],askOn:false,askAt:0,askX:0,askY:0,attOn:false,attAt:0,attX:0,attY:0,leanT:-9,leanA:0,leanS:1,shkAt:-9,shkAmp:0,exert:0,
   echoTaps:[],echoSt:0,echoX:0,echoY:0,echoBeats:[],echoI:0,echoT0:0,echoPrev:null,echoPrevT:-99,echoSame:false,echoJoyUntil:-9,echoBeatT:-9,lureOn:false,lureID:-1,lureT0:0,lureStillT:0,lurePounced:false,lureTouched:false,lureTouchT:-9,lureStartle:-9,lureSn:-1,lureRub:0,lureBacked:false,reduceMotion:false,WakeSet,
   lv:v=>par.life2>=.5&&v>=.5,iv3:v=>par.life2>=.5&&v>=.5,bodyStretch:f=>f.sb>=0?f.sb:f.stretch,cutSniffs(){S.sniffs.length=0},startSniff(a,L){const s={id:++sid,a,L,cut:0};S.sniffs.push(s);return s},gaitTo(x,y){S.lifeSt='go';S.gaitOn=true;S.gaitTX=x;S.gaitTY=y;S.gaitH=Math.atan2(y-S.homeY,x-S.homeX);log.push('gait')}});
  const F=mk(code,S,NAMES.concat(['softDrop','idleSec'].filter(n=>code.includes('function '+n))));
  return{S,F,log,rnd,par,A:{get on(){return S.slpOn},get st(){return S.lifeSt},set st(v){S.lifeSt=v},get until(){return S.lifeUntil},set until(v){S.lifeUntil=v},get gait(){return S.gaitOn},set gait(v){S.gaitOn=v;S.wanderMoving=S.wanderMoving&&v},get tx(){return S.gaitTX},get ty(){return S.gaitTY},get hx(){return S.homeX},get hy(){return S.homeY},get flAt(){return S.flAt},set flAt(v){S.flAt=v},set flT0(v){S.flT0=v},get boost(){return S.flBoost},set boost(v){S.flBoost=v},get taps(){return S.taps},set any(v){S.slpLastAny=v},set user(v){S.eyeUser=v},set open(v){S.slpOpenT=v},set c(v){S.moodC=v},get echo(){return S.echoSt===1?'listen':S.echoSt===2?'play':'idle'},imp(a,b){S.impTrust=a;S.impWary=b},ctr(){S.clusters[0].xc=S.homeX;S.clusters[0].yc=S.homeY},cam(z){S.camZ=z},rm(v){S.reduceMotion=v},sn(){return S.sniffs}},
   put(f,p,vx,vy){f.rawX=p[0];f.rawY=p[1];f.x=p[0]+vx/60;f.y=p[1]+vy/60},   // x、y 在手機可能是預測點：故意放別的值，讀錯就會不同
   snap(){return{on:+S.slpOn,k:S.slpK,wakeT:S.slpWakeT,ask:S.slpAskAt,near:S.slpNearT,snore:S.slpSnoreAt,slow:+S.slpSlow,tap:S.slpTap?1+S.slpTap.id:0,t0:S.slpTap?S.slpTapT0:0,done:S.slpTap?+S.slpTapDone:0,n:S.slpTapN,rollT:S.slpRollT,rollD:S.slpRollD,rollO:S.slpRollO,flAt:S.flAt,boost:S.flBoost,flAmp:S.flAmp,pre:S.flPre,st:S.lifeSt,until:S.lifeUntil,blink:S.eyeBlinkT,user:S.eyeUser,hx:S.homeX,hy:S.homeY,x0:S.X[0],px0:S.PX[0],tr:S.impTrust,w:S.impWary,hap:S.happyT,wag:S.wagT,lean:S.leanT,leanA:S.leanA,askOn:+S.askOn,att:+S.attOn,attAt:S.attOn?S.attAt:0,est:S.echoSt,en:S.echoTaps.length,ei:S.echoI,joy:S.echoJoyUntil,lure:+S.lureOn,still:S.lureStillT,gait:+S.gaitOn,gk:S.gaitK,shk:S.shkAt,ex:S.exert,sn:S.sniffs.length,rn:rnd.n(),lg:log.length,ll:log[log.length-1]||''}}}}
function webSide(par,seed){const rnd=RNG(seed),log=[],S={isWeb:true};common(S,par,rnd,log);
  Object.assign(S,{mat:par,CAM:{z:1},globalC:{xc:CX,yc:CY},SLP:{on:false,k:0,lastAny:-99,wakeT:-9,askAt:-9,nearT:0,openT:-99,slow:false,tap:null,n:0,rollT:-9,rollD:1,rollO:0},MOOD:{taps:[],c:.1,scare:0,cowerUntil:-9,happyT:-9,wagT:-9},IMP:{tr:.5,w:0,askUntil:-9},FLN:{at:-9,t0:-9,amp:0,pre:'rest',boost:1,tpAt:-9},LIFE:{st:'rest',until:-1,sns:[],att:null,ask:null},EYE:{blinkT:-9,user:-9,pulse:-9},E2:{leanT:-9,leanA:0,leanS:1},SHK:{at:-9,amp:0},BRX:{exert:0},SWIM:{on:false},E4:{on:false},SNW:{cloud:0,loose:[]},ESC:{on:false,dx:0,dy:0},INTRO:{on:false},
   GAIT:{on:false,k:1,tx:0,ty:0,h:0},WANDER:{moving:false,dx:0,dy:0,vx:0,vy:0},HOMEX:CX,HOMEY:CY,SILL:{on:false,tanV:false},ECHO:{taps:[],st:'idle',x:0,y:0,beats:[],i:0,t0:0,prev:null,prevT:-99,same:false,joyUntil:-9},LURE:{on:false,id:-1,t0:0,stillT:0,pounced:false,touched:false,touchT:-9,startle:-9,sn:null,rub:0,backed:false},GREET:{st:'',until:-9,open:false},DR:{lookT:-9},BRAIN:{m:0},REDUCED:false,
   LV:k=>par.life2>=.5&&par[k]>=.5,IV2:k=>par.imp>=.5&&par.life2>=.5&&par[k]>=.5,IV3:k=>par.life2>=.5&&par[k]>=.5,SB:f=>f.sb==null?f.stretch:f.sb,MDon:()=>false,BRon:()=>false,DRon:()=>false,BRM:()=>0,drRecent:()=>false,sfxPlay:k=>log.push(k.replace(/^\w+\./,'')),cutSniffs(){S.LIFE.sns.length=0},startSniff(a,L){const s={a,L,cut:0};S.LIFE.sns.push(s);return s},gaitTo(x,y){S.LIFE.st='go';Object.assign(S.GAIT,{on:true,tx:x,ty:y,h:Math.atan2(y-S.HOMEY,x-S.HOMEX)});log.push('gait')}});
  S.voice.last=-9;const F=mk(wj,S,NAMES.concat(['idleSec'])),E={idle:0,listen:1,play:2};
  return{S,F,log,rnd,par,A:{get on(){return S.SLP.on},get st(){return S.LIFE.st},set st(v){S.LIFE.st=v},get until(){return S.LIFE.until},set until(v){S.LIFE.until=v},get gait(){return S.GAIT.on},set gait(v){S.GAIT.on=v;S.WANDER.moving=S.WANDER.moving&&v},get tx(){return S.GAIT.tx},get ty(){return S.GAIT.ty},get hx(){return S.HOMEX},get hy(){return S.HOMEY},get flAt(){return S.FLN.at},set flAt(v){S.FLN.at=v},set flT0(v){S.FLN.t0=v},get boost(){return S.FLN.boost},set boost(v){S.FLN.boost=v},get taps(){return S.MOOD.taps},set any(v){S.SLP.lastAny=v},set user(v){S.EYE.user=v},set open(v){S.SLP.openT=v},set c(v){S.MOOD.c=v},get echo(){return S.ECHO.st},imp(a,b){S.IMP.tr=a;S.IMP.w=b},ctr(){S.globalC.xc=S.HOMEX;S.globalC.yc=S.HOMEY},cam(z){S.CAM.z=z},rm(v){S.REDUCED=v},sn(){return S.LIFE.sns}},
   put(f,p){f.x=f.rawX=p[0];f.y=f.rawY=p[1]},
   snap(){const L=S.SLP,q=L.tap;return{on:+L.on,k:L.k,wakeT:L.wakeT,ask:L.askAt,near:L.nearT,snore:L.snoreAt||0,slow:+L.slow,tap:q?1+q.f.id:0,t0:q?q.t0:0,done:q?+q.done:0,n:L.n,rollT:L.rollT,rollD:L.rollD,rollO:L.rollO,flAt:S.FLN.at,boost:S.FLN.boost,flAmp:S.FLN.amp,pre:S.FLN.pre,st:S.LIFE.st,until:S.LIFE.until,blink:S.EYE.blinkT,user:S.EYE.user,hx:S.HOMEX,hy:S.HOMEY,x0:S.X[0],px0:S.PX[0],tr:S.IMP.tr,w:S.IMP.w,hap:S.MOOD.happyT,wag:S.MOOD.wagT,lean:S.E2.leanT,leanA:S.E2.leanA,askOn:+!!S.LIFE.ask,att:+!!S.LIFE.att,attAt:S.LIFE.att?S.LIFE.att.at:0,est:E[S.ECHO.st],en:S.ECHO.taps.length,ei:S.ECHO.i,joy:S.ECHO.joyUntil,lure:+S.LURE.on,still:S.LURE.stillT,gait:+S.GAIT.on,gk:S.GAIT.k,shk:S.SHK.at,ex:S.BRX.exert,sn:S.LIFE.sns.length,rn:rnd.n(),lg:log.length,ll:log[log.length-1]||''}}}}

// ---------- 假手
let sd=20261125;const r0=()=>{sd=(sd*1664525+1013904223)>>>0;return sd/4294967296},rr=(a,b)=>a+(b-a)*r0();
const KIND=['light','light','light','hold','slap','drag','yank','tap3','two','beside','far','rhythm','pushin','brush','bg'];
function script(only){const ev=[];let T=rr(.2,1);const n=only?1:4+(r0()*6|0);let id=1;
  for(let k=0;k<n;k++){const kind=only||KIND[r0()*KIND.length|0];T+=r0()<.75||only?rr(5,7.5):rr(.1,1.2);   // 多半等到睡著再碰
    const add=(d,dur,r,path)=>ev.push({id:id++,kind,T:T+d,dur,a:rr(0,6.283),r,path,v:rr(1,9),w:rr(0,6.283)});let len=1;
    if(kind==='light'){const c=1+(r0()*4|0);let d=0;for(let i=0;i<c;i++){add(d,rr(.04,.6),rr(.05,.95),'still');d+=rr(.7,2.2)}len=d}
    else if(kind==='hold'){len=rr(.5,3);add(0,len,rr(.1,.9),'still')}
    else if(kind==='slap'){len=rr(.1,.6);add(0,len,rr(.1,.9),'line');ev[ev.length-1].v=rr(2,9)}
    else if(kind==='drag'){len=rr(.8,3);add(0,len,rr(.1,.9),'line');ev[ev.length-1].v=rr(.3,3)}
    else if(kind==='yank'){len=rr(.5,2);add(0,len,rr(.1,.9),'late');ev[ev.length-1].v=rr(6,12)}
    else if(kind==='tap3'){for(const d of[0,.25,.5,.75])add(d,.1,rr(.1,.9),'still')}
    else if(kind==='two'){add(0,1.4,.5,'still');add(rr(.02,1),.8,.4,'still');len=2.2}
    else if(kind==='beside'){len=rr(1,5);add(0,len,rr(1.3,2.8),r0()<.5?'still':'jit')}
    else if(kind==='far'){add(0,.2,rr(3.2,4.5),'still')}
    else if(kind==='rhythm'){const c=2+(r0()*5|0),g=rr(.15,.9);for(let i=0;i<c;i++)add(i*g,.08,rr(1.4,3.4),'still');if(r0()<.5){add(c*g,rr(1,4),rr(1.4,2.6),'still')}len=c*g+3}
    else if(kind==='pushin'){len=rr(.8,3.5);add(0,len,rr(3.05,3.5),'in');ev[ev.length-1].v=rr(1.6,6)}
    else if(kind==='brush'){len=rr(.4,2);add(0,len,1.3,'stroke')}
    else if(kind==='bg'){len=rr(.1,1);add(0,len+1,rr(.1,.9),'still');ev.push({bg:true,T:T+len})}
    T+=len}
  return{ev,T:T+6,tr:[0,.2,.3,.5,.65,.75,.95][r0()*7|0],w:r0()<.7?0:rr(0,.8),z:r0()<.5?1:rr(.5,1),rm:r0()<.2,c:r0()<.3?.6:.1,gt:r0()<.3?1.4:0}}
function posAt(e,u){const ox=Math.cos(e.a),oy=Math.sin(e.a),sx=CX+ox*e.r*R,sy=CY+oy*e.r*R,d=e.path==='line'?u*e.v*R:e.path==='late'?Math.max(0,u-.4)*e.v*R:0;
  if(e.path==='in'){const l=Math.min(u*e.v*R,(e.r-.6)*R);return[sx-ox*l,sy-oy*l]}
  if(e.path==='jit')return[sx+Math.sin(u*5)*R*.4,sy+Math.cos(u*3)*R*.4];
  if(e.path==='stroke'){const q=Math.sin(u*6)*R*.6;return[sx-oy*q-ox*R*.4,sy+ox*q-oy*R*.4]}
  return[sx+Math.cos(e.w)*d,sy+Math.sin(e.w)*d]}
function run(sides,sc,o={}){const dt=1/60,dif={},cov={};let t=0,fr=0,live=[];const gone=new Set(),eye=sides.map(()=>[0,0]);let first=null;
  for(const s of sides){s.A.imp(sc.tr,sc.w);s.A.cam(sc.z);s.A.rm(sc.rm);s.A.c=sc.c;s.A.open=0}
  while(t<sc.T){t+=dt;fr++;const pre=t-dt;
   sc.ev.forEach((e,k)=>{if(gone.has(k)||t<e.T)return;gone.add(k);
     if(e.bg){if(o.noBg)return;for(const h of live)sides.forEach(s=>s.S.fingers.delete(h.e.id));live=[];sides.forEach(s=>{s.S.t=pre;if(s.F.softDrop)s.F.softDrop();s.S.lastTouch=pre});return}
     const p=posAt(e,0),sA=sides[0].A,h={e,t0:t,lx:p[0],ly:p[1],vx:0,vy:0,end:t+e.dur};h.grab=Math.hypot(p[0]-sA.hx,p[1]-sA.hy)<R*1.1;live.push(h);
     sides.forEach(s=>{s.S.t=pre;s.A.any=pre;const f=s.F.downSeg(p[0],p[1],h.grab,true);f.id=e.id;f.lure=!h.grab;f.gentleT=h.grab?sc.gt:0;s.S.fingers.set(e.id,f)})});
   sides.forEach(s=>{s.S.t=t;s.S.wanderVX=0});
   for(const h of live){const u=t-h.t0,p=posAt(h.e,u),vx=(p[0]-h.lx)/dt,vy=(p[1]-h.ly)/dt,k=1-Math.exp(-dt/.03);h.lx=p[0];h.ly=p[1];h.vx+=(vx-h.vx)*k;h.vy+=(vy-h.vy)*k;
     sides.forEach(s=>{const f=s.S.fingers.get(h.e.id);s.put(f,p,vx,vy);f.vxS=h.vx;f.vyS=h.vy;f.fx+=(p[0]-f.fx)*(1-Math.exp(-dt/.22));f.fy+=(p[1]-f.fy)*(1-Math.exp(-dt/.22));
      const d=Math.hypot(p[0]-s.A.hx,p[1]-s.A.hy);
      if(h.grab){f.stretch=Math.hypot(p[0]-f.ax,p[1]-f.ay)/R;if(Math.hypot(h.vx,h.vy)*sc.z/R>=6&&f.stretch>.8)f.yank=true}
      else if(h.e.path==='stroke'&&u>.1&&d<R*1.1){f.mode='stroke';f.lure=false;f.hitT=t;s.S.lastTouch=t}
      else if(d<R*1.02){f.hitT=t}})}
   sides.forEach((s,i)=>{const F=s.F,S=s.S,A=s.A;A.ctr();if(o.swap)o.swap(t,s);
     let eng=false;for(const f of S.fingers.values())if(f.mode==='grab'||(t-f.hitT<.3&&!(f.lure&&Math.hypot(f.vxS,f.vyS)<R)))eng=true;
     const idle=eng?0:Math.min(1,Math.max(0,(t-S.lastTouch-.8)/1.2));
     S.pass=0;F.sleepStep(dt);if(o.after)o.after(t,s);F.echoStep(dt);
     if(A.flAt>0&&t>=A.flAt){A.flAt=-9;A.flT0=t;s.log.push('fl'+A.boost.toFixed(2));A.boost=1;A.sn().length=0}
     if(A.until<0)A.until=t+1.5+s.rnd();
     if(eng){if(A.gait||A.st==='go'){A.gait=false;A.st='rest';A.until=-1}}
     else{S.pass=F.seg(dt,idle>.5)||0;
      if(A.st==='look'&&!S.fingers.size&&t>A.until){A.st='rest';A.until=t+1}
      if(A.gait&&!(A.echo!=='idle'&&!(A.echo==='listen'&&s.par.nearFast>=.5))){const dx=A.tx-A.hx,dy=A.ty-A.hy,l=Math.hypot(dx,dy),m=Math.min(l,R*1.2*dt);if(l<1){A.gait=false;A.st='rest';A.until=t+2}else F.moveHome(dx/l*m,dy/l*m,dt)}}
     if(i===0&&first===null&&Math.hypot(A.hx-CX,A.hy-CY)>1)first=t;
     let g=null,pf=null;for(const f of S.fingers.values()){if(f.mode==='grab'){if(!g)g=f}else if(!pf)pf=f}
     const cx=CX+3,cy=CY-7,tow=(x,y)=>{const dx=x-cx,dy=y-cy,d=Math.max(1e-6,Math.hypot(dx,dy)),k=Math.min(1,d/(R*1.2));return[dx/d*k,dy/d*k]},q=F.eyeSeg(g,pf,tow)||[0,0],ke=1-Math.exp(-dt/.06);eye[i][0]+=(q[0]-eye[i][0])*ke;eye[i][1]+=(q[1]-eye[i][1])*ke});
   for(const h of live.slice())if(t>=h.end){live.splice(live.indexOf(h),1);sides.forEach(s=>{const S=s.S,f=S.fingers.get(h.e.id);S.fingers.delete(h.e.id);if(f.mode==='grab'||f.hitT>-9&&!f.lure)S.lastTouch=t;
     if(f.mode==='grab'){if(t-f.tDown<.25&&f.stretch<.3){const k=s.A.taps.filter(x=>t-x<1);k.push(t);s.A.taps.length=0;s.A.taps.push(...k)}else s.F.happySeg(f);s.F.lifeRelease(f);s.F.impAsk(f);s.F.e2Release(f);s.A.user=t+1.2}})}
   const sn=sides.map((s,i)=>Object.assign(s.snap(),{ex0:eye[i][0],ey0:eye[i][1],wide:s.F.wideSeg(),pass:s.S.pass}));
   for(const q in sn[0])for(let i=1;i<sn.length;i++){const a=sn[0][q],b=sn[i][q],d=a===b?0:typeof a==='number'&&typeof b==='number'?Math.abs(a-b):1;if(!(d<=(dif[q]||0))){if(d>1e-9&&process.env.DBG&&!dif['_']){dif['_']=1;console.log('  ',q,t.toFixed(3),a,b)}dif[q]=d}}
   const z=sn[0];cov.sleep=(cov.sleep||0)+z.on;if(z.rollT>0)cov.roll=(cov.roll||0)+1;if(z.slow&&z.k>0&&!z.on)cov.slow=(cov.slow||0)+1;if(z.tap)cov.judge=(cov.judge||0)+1;if(z.est===1&&z.lure)cov.hear=(cov.hear||0)+1;if(z.est===2)cov.play=(cov.play||0)+1;cov.startle=sides[0].log.filter(x=>x==='startle').length}
  return{fr,dif,cov,first,sides}}
let fail=0;const N=build(swNew),O=build(swOld);
function batch(name,n,mkS,tol,o){const D={},C={};let fr=0;for(let i=0;i<n;i++){const r=run(mkS(i),script(),o);fr+=r.fr;for(const q in r.dif)if(q[0]!=='_')D[q]=Math.max(D[q]||0,r.dif[q]);for(const q in r.cov)C[q]=(C[q]||0)+r.cov[q]}
  const w=Object.entries(D).sort((a,b)=>b[1]-a[1])[0]||['-',0],ok=w[1]<=tol;if(!ok)fail++;
  console.log((w[1]===0?'一樣':ok?'一樣（捨入內）':'不同')+' | '+name+' | '+n+' 串 '+fr+' 格 | 最大差 '+w[1]+'（'+w[0]+'）| 睡著 '+(C.sleep||0)+'、判斷中 '+(C.judge||0)+'、翻身 '+(C.roll||0)+'、慢醒中 '+(C.slow||0)+'、嚇醒 '+(C.startle||0)+' 次、聽著就靠過來 '+(C.hear||0)+'、回節奏 '+(C.play||0)+' 格')}
for(const[a,b,c,n]of[[1,1,1,250],[1,0,0,100],[0,1,0,100],[0,0,1,100],[0,0,0,100]])
  batch(`Swift 對網頁 wakeSoft ${a} nearFast ${b} eyeTrue ${c}`,n,i=>{const p=()=>PAR({wakeSoft:a,nearFast:b,eyeTrue:c});return[swSide(N,p(),i+1),webSide(p(),i+1)]},1e-9,{noBg:true});
batch('三個都 0：現在的 Swift 對動工前的 Swift（df8a573）',300,i=>{const p=()=>PAR({wakeSoft:0,nearFast:0,eyeTrue:0});return[swSide(N,p(),i+1),swSide(O,p(),i+1)]},0,{});
// 半路切成 0：同一格不能留下狀態，翻身挪的那一點要還回去
{let bad=0,mid=0,hit=0;for(let i=0;i<400;i++){const par=PAR({}),s=swSide(N,par,i+1),sc=script('light');sc.tr=.9;sc.w=0;let on=false,done=false,h0=0,ro=0;const at=rr(.02,1.3);let st=-1;
 run([s],sc,{noBg:true,swap:(t,q)=>{const S=q.S;if(st<0&&S.slpTap)st=t;if(st>=0&&!done&&t>st+at){done=on=true;hit++;ro=S.slpRollO;h0=S.homeX-ro;if(ro)mid++;par.wakeSoft=par.nearFast=par.eyeTrue=0}},after:(t,q)=>{if(!on)return;on=false;const S=q.S;if(S.slpTap||S.slpTapN||S.slpTapDone||S.slpRollT!==-9||S.slpRollO!==0||S.slpSlow||Math.abs(S.homeX-h0)>1e-9)bad++}})}
 console.log((bad?'不同':'一樣')+' | 半路三個切成 0：狀態歸零、位移還回去 | '+hit+' 次（翻到一半切的 '+mid+'）| 沒歸零 '+bad);if(bad||!mid)fail++}
// 切背景（cancelAllTouches 裡的 softDrop）、setup
{let bad=0,mid=0;for(let i=0;i<400;i++){const s=swSide(N,PAR({}),i+1),sc=script('light');sc.tr=.9;sc.w=0;let done=false;run([s],sc,{noBg:true,swap:(t,q)=>{const S=q.S;if(!done&&S.slpRollO!==0){done=true;mid++;const h=S.homeX-S.slpRollO;q.F.softDrop();if(S.slpTap||S.slpTapN||S.slpTapDone||S.slpRollT!==-9||S.slpRollO!==0||Math.abs(S.homeX-h)>1e-9||!S.slpOn)bad++}}})}
 console.log((bad?'不同':'一樣')+' | 切背景 softDrop：歸零、位移還回去、還睡著 | 翻到一半 '+mid+' 次 | 不對 '+bad);if(bad||!mid)fail++}
{let bad=0;for(let i=0;i<200;i++){const s=swSide(N,PAR({}),i+1);run([s],script());s.F.setupReset();const S=s.S;if(S.slpOn||S.slpK||S.slpSlow||S.slpTap||S.slpTapN||S.slpTapDone||S.slpRollT!==-9||S.slpRollO||S.slpRollD!==1||S.slpOpenT!==0)bad++}console.log((bad?'不同':'一樣')+' | setup 歸零、openT 設成 0 | 200 串 | 不對 '+bad);if(bad)fail++}
// 規則走一遍
const just=(sd2,par,sc,o)=>run([swSide(N,PAR(par),sd2)],sc,o).sides[0];
const mkSc=(ev,x)=>({ev:ev.map((e,i)=>Object.assign({id:i+1,a:0,r:.5,path:'still',v:0,w:0},e)),T:30,tr:.5,w:0,z:1,rm:false,c:.1,gt:0,...x});
const cnt=(s,k)=>s.log.filter(x=>x===k).length;
function rule(n,ok){if(!ok)fail++;console.log((ok?'對':'不對')+' | '+n)}
{let a=0,b=0,c=0;for(let i=0;i<5;i++){const s=just(i+1,{},mkSc([{T:10,dur:.1}],{tr:.5,T:12}));a+=cnt(s,'startle')+s.log.filter(x=>x.startsWith('fl')).length;b+=+(s.S.slpWakeT>9.9&&s.S.slpSlow);const w=just(i+1,{wakeSoft:0},mkSc([{T:10,dur:.1}],{tr:.5,T:12}));c+=cnt(w,'startle')}rule('熟 0.5 輕碰 5 次：嚇醒加縮 '+a+'、慢醒 '+b+'；wakeSoft 0 嚇醒 '+c,a===0&&b===5&&c===5)}
{const s=just(3,{},mkSc([{T:10,dur:.1},{T:12.5,dur:.1},{T:15,dur:.1}],{tr:.9,T:17}));const w=s.S.slpWakeT;rule('熟 0.9 輕碰三次：第三次（15 秒）醒，量到 '+w.toFixed(2)+' 秒，嚇醒 '+cnt(s,'startle'),w>15&&w<15.3&&!cnt(s,'startle'))}
{const s=just(3,{},mkSc([{T:10,dur:.3,path:'line',v:6}],{tr:.9,T:12}));rule('熟 0.9 落下（10 秒）就快動每秒 6R：嚇醒 '+cnt(s,'startle')+' 次（'+s.S.slpWakeT.toFixed(2)+' 秒）',cnt(s,'startle')===1&&s.S.slpWakeT<10.1)}
{const s=just(3,{},mkSc([{T:10,dur:.1}],{tr:.2,T:12}));rule('熟 0.2 輕碰：照舊嚇醒 '+cnt(s,'startle'),cnt(s,'startle')===1)}
{const s=just(3,{},mkSc([{T:10,dur:.1},{T:10.25,dur:.1},{T:10.5,dur:.1}],{tr:.9,T:12}));rule('熟 0.9 一秒內三下：第三下嚇醒 '+cnt(s,'startle'),cnt(s,'startle')===1)}
{const s=just(3,{},mkSc([{T:10,dur:2}],{tr:.9,T:13}));rule('熟 0.9 從 10 秒按住：'+s.S.slpWakeT.toFixed(2)+' 秒慢醒，嚇醒 '+cnt(s,'startle'),Math.abs(s.S.slpWakeT-11.2)<.05&&!cnt(s,'startle'))}
for(const ws of[1,0]){const s=swSide(N,PAR({wakeSoft:ws,sleepAfter:0}),5);s.S.slpOpenT=0;let at=null;for(let k=0;k<3600&&at===null;k++){s.S.t+=1/60;s.A.st='rest';if(s.F.sleepTry())at=s.S.t}rule('剛打開、沒人碰：wakeSoft '+ws+' 在 '+at.toFixed(2)+' 秒睡',Math.abs(at-(ws?40:30))<.05)}
for(const tr of[0,.5,.8])for(const nf of[1,0]){const r=run([swSide(N,PAR({nearFast:nf,sleepAfter:40}),5)],mkSc([{T:5,dur:4,r:2.2}],{tr,T:9}));console.log('　　 | 手指放旁邊 2.2R 不動、熟 '+tr+'，身體第一次挪（走路是假的，只看開關前後差）：nearFast '+nf+' '+(r.first===null?'沒挪':'落指後 '+(r.first-5).toFixed(2)+' 秒'))}
for(const nf of[1,0]){let ok=true;for(let c=2;c<=8;c++){const ev=[];for(let i=0;i<c;i++)ev.push({T:5+i*.4,dur:.08,r:2.4});const r=run([swSide(N,PAR({nearFast:nf,sleepAfter:40}),5)],mkSc(ev,{T:5+c*.8+5}));if(r.sides[0].log.filter(x=>x==='poke').length!==c)ok=false}rule('敲 2 到 8 下照同樣次數回（nearFast '+nf+'）',ok)}
// 眼睛：手指左右移，眼珠慢多少（只有這段算式；身體、臉不動）
for(const et of[1,0])for(const mode of['grab','push']){const f={mode,fx:0,fy:0,rawX:0,rawY:0},s=swSide(N,PAR({eyeTrue:et}),1);let gx=0;const w=2*Math.PI*.6,A=[],B=[],FS=240;for(let k=0;k<FS*20;k++){const t=k/FS,x=CX+Math.sin(w*t)*60;f.rawX=x;f.rawY=CY+140;f.fx+=(x-f.fx)*(1-Math.exp(-1/FS/.2));f.fy=CY+140;const tow=(a,b)=>{const dx=a-CX,dy=b-CY,d=Math.hypot(dx,dy),q=Math.min(1,d/(R*1.2));return[dx/d*q,dy/d*q]},o=s.F.eyeSeg(mode==='grab'?f:null,mode==='push'?f:null,tow);gx+=(o[0]-gx)*(1-Math.exp(-1/FS/.06));if(k>FS*5){A.push(tow(x,CY+140)[0]);B.push(gx)}}
 let best=0,bc=-1e9;for(let l=0;l<120;l++){let c=0;for(let k=120;k<A.length;k++)c+=A[k-l]*B[k];if(c>bc){bc=c;best=l}}console.log('　　 | 眼珠慢多少（lag 設 0.2 秒的算式，不是真機）：eyeTrue '+et+' '+mode+' '+(best*1000/FS).toFixed(0)+' 毫秒')}
console.log(fail?'有 '+fail+' 項不同':'全部一樣');
